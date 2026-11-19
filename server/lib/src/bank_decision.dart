import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'bank_card.dart';
import 'bank_bridge.dart';
import 'bank_common.dart';
import 'db.dart';
import 'http_util.dart';

const _choices = {'confirmed', 'requested', 'withhold'};
const _waiveReasons = {'outside_system', 'fixed_elsewhere', 'approved_exception', 'other'};
const _decisionKinds = {'partial', 'return_all', 'control_measure', 'suspend'};
final _keyPattern = RegExp(r'^[A-Za-z0-9_-]{8,80}$');

void mountBankDecision(Router router, AppDatabase db) {
  router
    ..post(
      '/api/bank/tranches/<id>/lines/<lineId>/choice',
      (Request request, String id, String lineId) => _choice(request, db, id, lineId),
    )
    ..post(
      '/api/bank/tranches/<id>/checks/<checkId>/waive',
      (Request request, String id, String checkId) => _waive(request, db, id, checkId),
    )
    ..post(
      '/api/bank/tranches/<id>/checks/<checkId>/request',
      (Request request, String id, String checkId) => _requestCheck(request, db, id, checkId),
    )
    ..post(
      '/api/bank/tranches/<id>/resume',
      (Request request, String id) => _resume(request, db, id),
    )
    ..post(
      '/api/bank/tranches/<id>/decision',
      (Request request, String id) => _decide(request, db, id),
    );
}

/// The state of a tranche that every action checks under a lock.
class _State {
  const _State({
    required this.stage,
    required this.waiting,
    required this.outcome,
    required this.paused,
    required this.round,
    required this.facilityId,
  });

  final String stage;
  final bool waiting;
  final String? outcome;
  final bool paused;
  final int round;
  final String facilityId;
}

Future<_State> _lock(Session tx, String id, BankActor actor) async {
  final rows = await tx.execute(
    Sql.named('''
      SELECT t.stage, t.waiting_developer, t.outcome, t.approval_round,
             f.funding_paused, f.id::text AS facility_id
      FROM bank_tranches t
      JOIN project_facilities f ON f.project_id = t.project_id AND f.bank_id = t.bank_id
      WHERE t.id = @id::uuid AND t.bank_id = @bankId::uuid
      FOR UPDATE OF t
    '''),
    parameters: {'id': id, 'bankId': actor.bankId},
  );
  if (rows.isEmpty) throw const BankFailure(404, 'not_found', 'Не найдено');
  final map = rows.first.toColumnMap();
  return _State(
    stage: map['stage'] as String,
    waiting: bankBool(map['waiting_developer']),
    outcome: map['outcome'] as String?,
    paused: bankBool(map['funding_paused']),
    round: bankInt(map['approval_round']),
    facilityId: map['facility_id'] as String,
  );
}

void _mustDecide(_State state) {
  if (state.outcome != null) {
    throw const BankFailure(409, 'closed', 'Транш уже закрыт');
  }
  if (state.waiting) {
    throw const BankFailure(409, 'waiting_developer', 'Транш ждёт застройщика');
  }
  if (state.paused) {
    throw const BankFailure(409, 'paused', 'Финансирование объекта приостановлено');
  }
  if (state.stage != 'specialist') {
    throw const BankFailure(409, 'wrong_stage', 'Транш уже не на этапе решения специалиста');
  }
}

typedef _Work = Future<Map<String, Object?>?> Function(
  Session tx,
  BankActor actor,
  _State state,
  Map<String, Object?> body,
);

/// One place for the rules every change shares: the person is logged in, the
/// token fits, the person is the specialist of the bank, the tranche is locked,
/// the counted values are refreshed and the answer is the card after commit.
Future<Response> _run(
  Request request,
  AppDatabase db,
  String id,
  _Work work, {
  bool needsBody = true,
}) async {
  final opened = await bankMutating(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!bankIsUuid(id)) return jsonError(404, 'not_found', 'Не найдено');
  final actor = await bankActor(db, session.user!);
  if (actor == null) return jsonError(404, 'not_found', 'Не найдено');
  if (actor.role != 'specialist') {
    return jsonError(403, 'forbidden', 'Это действие доступно кредитному специалисту');
  }
  var body = <String, Object?>{};
  if (needsBody) {
    final parsed = await readJsonObject(request);
    if (parsed is String) return jsonError(400, 'validation', 'Не удалось прочитать запрос');
    body = (parsed as Map).map((key, value) => MapEntry(key.toString(), value));
  }
  try {
    await db.pool.runTx((tx) async {
      final state = await _lock(tx, id, actor);
      final summary = await work(tx, actor, state, body);
      if (summary != null) await bankRecompute(tx, id);
    });
  } on BankFailure catch (failure) {
    return failure.toResponse();
  } on BankKeyReused {
    return jsonError(409, 'key_reused', 'Этот ключ уже использован с другим запросом');
  }
  await bankWriteBack(db, id);
  final card = await bankTrancheCard(db, id, actor);
  return jsonResponse(200, {'card': card});
}

Future<Response> _choice(Request request, AppDatabase db, String id, String lineId) {
  return _run(request, db, id, (tx, actor, state, body) async {
    if (!bankIsUuid(lineId)) throw const BankFailure(404, 'not_found', 'Статья не найдена');
    final choice = body['choice'];
    if (choice is! String || !_choices.contains(choice)) {
      throw const BankFailure(400, 'validation', 'Выберите, какую сумму выдать');
    }
    _mustDecide(state);
    final rows = await tx.execute(
      Sql.named('''
        SELECT (l.requested <= l.confirmed) AS can_request,
               l.title AS title,
               l.choice AS before,
               (
                 l.block_check_id IS NOT NULL AND EXISTS (
                   SELECT 1 FROM bank_checks c
                   WHERE c.id = l.block_check_id
                     AND NOT c.passed
                     AND NOT EXISTS (SELECT 1 FROM bank_check_waivers w WHERE w.check_id = c.id)
                 )
               ) AS blocked
        FROM bank_tranche_lines l
        WHERE l.id = @line::uuid AND l.tranche_id = @id::uuid
      '''),
      parameters: {'line': lineId, 'id': id},
    );
    if (rows.isEmpty) throw const BankFailure(404, 'not_found', 'Статья не найдена');
    final map = rows.first.toColumnMap();
    if (bankBool(map['blocked']) && choice != 'withhold') {
      throw const BankFailure(
        409,
        'blocked',
        'Статья заблокирована проверкой. Примите проверку с обоснованием или не выдавайте',
      );
    }
    if (choice == 'requested' && !bankBool(map['can_request'])) {
      throw const BankFailure(409, 'above_confirmed', 'Выдать больше подтверждённого нельзя');
    }
    await tx.execute(
      Sql.named('UPDATE bank_tranche_lines SET choice = @choice WHERE id = @line::uuid'),
      parameters: {'choice': choice, 'line': lineId},
    );
    await bankAudit(
      tx,
      bankId: actor.bankId,
      trancheId: id,
      userId: actor.userId,
      actorLabel: actor.name,
      action: 'choose',
      detail: {'line': map['title'], 'from': map['before'], 'to': choice},
    );
    return {'ok': true};
  });
}

Future<Response> _waive(Request request, AppDatabase db, String id, String checkId) {
  return _run(request, db, id, (tx, actor, state, body) async {
    if (!bankIsUuid(checkId)) throw const BankFailure(404, 'not_found', 'Проверка не найдена');
    final reason = body['reason'];
    final comment = ('${body['comment'] ?? ''}').trim();
    if (reason is! String || !_waiveReasons.contains(reason)) {
      throw const BankFailure(400, 'validation', 'Выберите основание');
    }
    if (comment.isEmpty) {
      throw const BankFailure(400, 'validation', 'Опишите обоснование: оно останется в журнале');
    }
    if (comment.length > 1000 || comment.contains(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'))) {
      throw const BankFailure(400, 'validation', 'Обоснование слишком длинное');
    }
    _mustDecide(state);
    final rows = await tx.execute(
      Sql.named('''
        SELECT c.code, c.level, c.passed,
               EXISTS (SELECT 1 FROM bank_check_waivers w WHERE w.check_id = c.id) AS waived
        FROM bank_checks c
        WHERE c.id = @check::uuid AND c.tranche_id = @id::uuid
      '''),
      parameters: {'check': checkId, 'id': id},
    );
    if (rows.isEmpty) throw const BankFailure(404, 'not_found', 'Проверка не найдена');
    final map = rows.first.toColumnMap();
    if (bankBool(map['passed']) || bankBool(map['waived'])) {
      throw const BankFailure(409, 'already_closed', 'Эта проверка уже не требует решения');
    }
    if (!bankCheckActions(map['code'] as String, map['level'] as String).contains('waive')) {
      throw const BankFailure(409, 'not_waivable', 'Эту проверку принять с обоснованием нельзя');
    }
    await tx.execute(
      Sql.named('''
        INSERT INTO bank_check_waivers (check_id, tranche_id, reason, comment, user_id, actor_label)
        VALUES (@check::uuid, @id::uuid, @reason, @comment, @user::uuid, @label)
      '''),
      parameters: {
        'check': checkId,
        'id': id,
        'reason': reason,
        'comment': comment,
        'user': actor.userId,
        'label': actor.name,
      },
    );
    await bankAudit(
      tx,
      bankId: actor.bankId,
      trancheId: id,
      userId: actor.userId,
      actorLabel: actor.name,
      action: 'waive',
      detail: {'check': map['code'], 'level': map['level'], 'reason': reason, 'comment': comment},
    );
    return {'ok': true};
  });
}

Future<Response> _requestCheck(Request request, AppDatabase db, String id, String checkId) {
  return _run(
    request,
    db,
    id,
    (tx, actor, state, body) async {
      if (!bankIsUuid(checkId)) throw const BankFailure(404, 'not_found', 'Проверка не найдена');
      if (state.outcome != null || state.waiting) {
        throw const BankFailure(409, 'closed', 'По траншу сейчас нельзя ничего запросить');
      }
      if (state.stage != 'specialist' && state.stage != 'docs') {
        throw const BankFailure(409, 'wrong_stage', 'Транш уже не на этапе проверки');
      }
      final rows = await tx.execute(
        Sql.named('''
          SELECT code, level, passed FROM bank_checks
          WHERE id = @check::uuid AND tranche_id = @id::uuid
        '''),
        parameters: {'check': checkId, 'id': id},
      );
      if (rows.isEmpty) throw const BankFailure(404, 'not_found', 'Проверка не найдена');
      final map = rows.first.toColumnMap();
      final actions = bankCheckActions(map['code'] as String, map['level'] as String);
      final kind = actions.contains('request_schedule')
          ? 'schedule'
          : actions.contains('request_document')
              ? 'document'
              : null;
      if (bankBool(map['passed']) || kind == null) {
        throw const BankFailure(409, 'not_requestable', 'По этой проверке запрашивать нечего');
      }
      await tx.execute(
        Sql.named('''
          UPDATE bank_checks SET requested_kind = @kind, requested_at = now()
          WHERE id = @check::uuid
        '''),
        parameters: {'kind': kind, 'check': checkId},
      );
      await bankAudit(
        tx,
        bankId: actor.bankId,
        trancheId: id,
        userId: actor.userId,
        actorLabel: actor.name,
        action: 'request',
        detail: {'check': map['code'], 'kind': kind},
      );
      return {'ok': true};
    },
    needsBody: false,
  );
}

Future<Response> _resume(Request request, AppDatabase db, String id) {
  return _run(
    request,
    db,
    id,
    (tx, actor, state, body) async {
      if (state.outcome != null || !state.waiting) {
        throw const BankFailure(409, 'not_waiting', 'Транш не ждёт застройщика');
      }
      await tx.execute(
        Sql.named('''
          UPDATE bank_tranches
          SET waiting_developer = false,
              stage_label = 'Решение специалиста',
              holder_user_id = @user::uuid,
              holder_label = @label
          WHERE id = @id::uuid
        '''),
        parameters: {'id': id, 'user': actor.userId, 'label': actor.name},
      );
      await tx.execute(
        Sql.named('''
          UPDATE project_facilities SET funding_paused = false WHERE id = @facility::uuid
        '''),
        parameters: {'facility': state.facilityId},
      );
      await bankResumeClock(tx, id);
      await _decision(tx, id, actor, state.round, 'resume', note: '');
      await bankAudit(tx, bankId: actor.bankId, trancheId: id, userId: actor.userId, actorLabel: actor.name, action: 'resume');
      return {'ok': true};
    },
    needsBody: false,
  );
}

Future<Response> _decide(Request request, AppDatabase db, String id) {
  final key = request.headers['idempotency-key'] ?? '';
  if (!_keyPattern.hasMatch(key)) {
    return Future.value(
      jsonError(400, 'validation', 'Не хватает ключа повторной отправки. Обновите страницу и повторите'),
    );
  }
  return _run(request, db, id, (tx, actor, state, body) async {
    final kind = body['kind'];
    final note = ('${body['note'] ?? ''}').trim();
    if (kind is! String || !_decisionKinds.contains(kind)) {
      throw const BankFailure(400, 'validation', 'Выберите решение');
    }
    if (note.length > 2000) throw const BankFailure(400, 'validation', 'Комментарий слишком длинный');
    final fingerprint = bankFingerprint({'id': id, 'kind': kind, 'note': note});
    final replay = await bankReplay(tx, actor.userId, key, fingerprint);
    if (replay != null) return null;
    if (kind != 'partial' && note.isEmpty) {
      throw const BankFailure(400, 'validation', 'Опишите причину: застройщик увидит её в запросе');
    }
    _mustDecide(state);
    await bankRecompute(tx, id);
    switch (kind) {
      case 'partial':
        await _partial(tx, id, actor, state, note);
      case 'return_all':
        await _returnAll(tx, id, actor, state, note);
      case 'control_measure':
        await _controlMeasure(tx, id, actor, state, note);
      case 'suspend':
        await _suspend(tx, id, actor, state, note);
    }
    final totals = await tx.execute(
      Sql.named('''
        SELECT to_char(issue_amount, $bankMoneyFormat), to_char(requested_amount - issue_amount, $bankMoneyFormat)
        FROM bank_tranches WHERE id = @id::uuid
      '''),
      parameters: {'id': id},
    );
    await bankAudit(
      tx,
      bankId: actor.bankId,
      trancheId: id,
      userId: actor.userId,
      actorLabel: actor.name,
      action: 'decision',
      detail: {
        'kind': kind,
        'issue': totals.first[0],
        'returned': totals.first[1],
        'note': note,
      },
    );
    await bankRemember(tx, actor.userId, key, fingerprint, {'kind': kind});
    return {'kind': kind};
  });
}

Future<void> _decision(
  Session tx,
  String id,
  BankActor actor,
  int round,
  String kind, {
  required String note,
  String issue = '0',
  String returned = '0',
  int waived = 0,
  List<Map<String, Object?>> lines = const [],
}) {
  return tx.execute(
    Sql.named('''
      INSERT INTO bank_decisions (
        tranche_id, kind, round, issue_amount, returned_amount, waived_count,
        return_lines, note, user_id, actor_label
      ) VALUES (
        @id::uuid, @kind, @round, @issue::numeric, @returned::numeric, @waived,
        @lines::jsonb, @note, @user::uuid, @label
      )
    '''),
    parameters: {
      'id': id,
      'kind': kind,
      'round': round,
      'issue': issue,
      'returned': returned,
      'waived': waived,
      'lines': jsonEncode(lines),
      'note': note,
      'user': actor.userId,
      'label': actor.name,
    },
  );
}

Future<void> _partial(Session tx, String id, BankActor actor, _State state, String note) async {
  final totals = await tx.execute(
    Sql.named('''
      SELECT to_char(issue_amount, $bankMoneyFormat) AS issue,
             to_char(requested_amount - issue_amount, $bankMoneyFormat) AS returned,
             issue_amount
      FROM bank_tranches WHERE id = @id::uuid
    '''),
    parameters: {'id': id},
  );
  final map = totals.first.toColumnMap();
  if (bankCents(map['issue'] as String) <= BigInt.zero) {
    throw const BankFailure(
      409,
      'nothing_to_issue',
      'К выдаче ничего нет. Верните транш застройщику целиком',
    );
  }
  final basisRows = await tx.execute(
    Sql.named("SELECT basis FROM bank_checks WHERE tranche_id = @id::uuid AND code = 'above_confirmed'"),
    parameters: {'id': id},
  );
  final aboveBasis = basisRows.isEmpty ? 'ГС п. 3.6' : basisRows.first[0]! as String;
  final lineRows = await tx.execute(
    Sql.named('''
      SELECT l.id::text AS id, l.title,
             to_char(l.requested - l.to_issue, $bankMoneyFormat) AS amount,
             (l.requested - l.to_issue) AS gap,
             c.title AS block_title, c.basis AS block_basis,
             (c.id IS NOT NULL AND NOT c.passed
               AND NOT EXISTS (SELECT 1 FROM bank_check_waivers w WHERE w.check_id = c.id)) AS blocked,
             l.choice
      FROM bank_tranche_lines l
      LEFT JOIN bank_checks c ON c.id = l.block_check_id
      WHERE l.tranche_id = @id::uuid
      ORDER BY l.sort_order
    '''),
    parameters: {'id': id},
  );
  final returned = <Map<String, Object?>>[];
  for (final row in lineRows) {
    final line = row.toColumnMap();
    if (bankCents(line['amount'] as String) <= BigInt.zero) continue;
    final reason = bankBool(line['blocked'])
        ? '${line['block_title']} (${line['block_basis']})'
        : line['choice'] == 'withhold'
            ? 'Эксперт не подтвердил выдачу по этой статье'
            : 'Объём в акте больше подтверждённого ($aboveBasis)';
    returned.add({
      'lineId': line['id'],
      'title': line['title'],
      'amount': line['amount'],
      'reason': reason,
    });
  }
  final waived = await tx.execute(
    Sql.named('SELECT count(*) FROM bank_check_waivers WHERE tranche_id = @id::uuid'),
    parameters: {'id': id},
  );
  await _decision(
    tx,
    id,
    actor,
    state.round,
    'partial',
    note: note,
    issue: map['issue'] as String,
    returned: map['returned'] as String,
    waived: bankInt(waived.first[0]),
    lines: returned,
  );
  await tx.execute(
    Sql.named('''
      UPDATE bank_approval_steps
      SET status = 'done', actor_user_id = @user::uuid, actor_label = @label,
          decided_at = now(), note = ''
      WHERE tranche_id = @id::uuid AND code = 'specialist'
    '''),
    parameters: {'id': id, 'user': actor.userId, 'label': actor.name},
  );
  await tx.execute(
    Sql.named('''
      UPDATE bank_tranches
      SET stage = 'approval', stage_label = 'Согласование',
          holder_user_id = NULL, holder_label = 'Начальник отдела',
          elapsed_days = 0, elapsed_hours = 0,
          sla_days = bank_stage_days(rules_version_id, 'approval', sla_days)
      WHERE id = @id::uuid
    '''),
    parameters: {'id': id},
  );
  await bankMoveClock(tx, id, 'approval');
}

Future<void> _returnAll(Session tx, String id, BankActor actor, _State state, String note) async {
  await tx.execute(
    Sql.named("UPDATE bank_tranche_lines SET choice = 'withhold', to_issue = 0 WHERE tranche_id = @id::uuid"),
    parameters: {'id': id},
  );
  final totals = await tx.execute(
    Sql.named('''
      SELECT to_char(requested_amount, $bankMoneyFormat) FROM bank_tranches WHERE id = @id::uuid
    '''),
    parameters: {'id': id},
  );
  await _decision(
    tx,
    id,
    actor,
    state.round,
    'return_all',
    note: note,
    returned: totals.first[0]! as String,
  );
  await _toDeveloper(tx, id, 'Возвращена застройщику');
}

Future<void> _suspend(Session tx, String id, BankActor actor, _State state, String note) async {
  await tx.execute(
    Sql.named('UPDATE project_facilities SET funding_paused = true WHERE id = @facility::uuid'),
    parameters: {'facility': state.facilityId},
  );
  await _decision(tx, id, actor, state.round, 'suspend', note: note);
  await _toDeveloper(tx, id, 'Финансирование приостановлено');
}

Future<void> _toDeveloper(Session tx, String id, String label) async {
  await tx.execute(
    Sql.named('''
      UPDATE bank_tranches
      SET waiting_developer = true, stage_label = @label,
          holder_user_id = NULL, holder_label = 'Застройщик'
      WHERE id = @id::uuid
    '''),
    parameters: {'id': id, 'label': label},
  );
  await bankPauseClock(tx, id);
}

Future<void> _controlMeasure(Session tx, String id, BankActor actor, _State state, String note) async {
  final expert = await tx.execute(
    Sql.named('''
      SELECT s.user_id::text AS user_id, u.name
      FROM bank_staff s JOIN users u ON u.id = s.user_id
      WHERE s.bank_id = @bank::uuid AND s.role = 'expert' AND s.active
      ORDER BY u.name LIMIT 1
    '''),
    parameters: {'bank': actor.bankId},
  );
  final tranche = await tx.execute(
    Sql.named('SELECT project_id::text FROM bank_tranches WHERE id = @id::uuid'),
    parameters: {'id': id},
  );
  final expertMap = expert.isEmpty ? null : expert.first.toColumnMap();
  await tx.execute(
    Sql.named('''
      INSERT INTO bank_inspections (
        tranche_id, project_id, bank_id, kind, scheduled_on,
        expert_user_id, expert_label, created_by
      ) VALUES (
        @id::uuid, @project::uuid, @bank::uuid, 'control',
        (now() AT TIME ZONE 'Asia/Tashkent')::date + 3,
        @expert::uuid, @label, @user::uuid
      )
    '''),
    parameters: {
      'id': id,
      'project': tranche.first[0],
      'bank': actor.bankId,
      'expert': expertMap?['user_id'],
      'label': expertMap == null ? '' : '${expertMap['name']}, эксперт',
      'user': actor.userId,
    },
  );
  await _decision(tx, id, actor, state.round, 'control_measure', note: note);
  await tx.execute(
    Sql.named('''
      UPDATE bank_tranches
      SET stage = 'inspection', stage_label = 'Контрольный осмотр',
          holder_user_id = @expert::uuid, holder_label = @label
      WHERE id = @id::uuid
    '''),
    parameters: {
      'id': id,
      'expert': expertMap?['user_id'],
      'label': expertMap == null ? 'Эксперт' : '${expertMap['name']}, эксперт',
    },
  );
  await bankMoveClock(tx, id, 'inspection');
}
