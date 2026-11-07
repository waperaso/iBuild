import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'bank_common.dart';
import 'db.dart';
import 'http_util.dart';

const _fmt = bankMoneyFormat;
const _votes = {'approve', 'return', 'reject'};
const _groupOfStep = {'head': 'heads', 'committee': 'committee'};

void mountBankApproval(Router router, AppDatabase db) {
  router
    ..get(
      '/api/bank/tranches/<id>/approval',
      (Request request, String id) => _read(request, db, id),
    )
    ..post(
      '/api/bank/tranches/<id>/approval',
      (Request request, String id) => _act(request, db, id),
    );
}

Future<Response> _read(Request request, AppDatabase db, String id) async {
  final opened = await bankSession(request, db);
  if (opened is Response) return opened;
  if (!bankIsUuid(id)) return jsonError(404, 'not_found', 'Не найдено');
  final actor = await bankActor(db, (opened as SessionLookup).user!);
  if (actor == null) return jsonError(404, 'not_found', 'Не найдено');
  final payload = await bankApprovalPayload(db, id, actor);
  if (payload == null) return jsonError(404, 'not_found', 'Не найдено');
  return jsonResponse(200, payload);
}

/// Why this person cannot vote right now, or null when the person can.
String? _blocker({
  required String stage,
  required String? outcome,
  required Map<String, Object?>? current,
  required bool member,
  required bool onLeave,
  required bool preparer,
  required bool voted,
}) {
  if (outcome != null) return 'closed';
  if (stage != 'approval' || current == null) return 'not_now';
  if (current['kind'] != 'group') return 'external';
  if (!member) return 'not_member';
  if (onLeave) return 'on_leave';
  if (preparer) return 'preparer';
  if (voted) return 'voted';
  return null;
}

Future<Map<String, Object?>?> bankApprovalPayload(
  AppDatabase db,
  String id,
  BankActor actor,
) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT t.id::text AS id, p.name AS project_name, t.tranche_no, t.stage, t.stage_label,
             t.outcome, t.approval_round,
             to_char(t.issue_amount, $_fmt) AS issue,
             to_char(t.requested_amount - t.issue_amount, $_fmt) AS returned,
             to_char(COALESCE((v.snapshot ->> 'committeeAmount')::numeric, 0), $_fmt) AS threshold,
             (SELECT to_char(min(l.expert_signed_on), 'DD.MM.YYYY')
              FROM bank_tranche_lines l WHERE l.tranche_id = t.id) AS expert_signed_on,
             (SELECT count(*) FROM bank_check_waivers w WHERE w.tranche_id = t.id) AS waived_count
      FROM bank_tranches t
      JOIN projects p ON p.id = t.project_id
      JOIN bank_rule_versions v ON v.id = t.rules_version_id
      WHERE t.id = @id::uuid AND t.bank_id = @bankId::uuid
    '''),
    parameters: {'id': id, 'bankId': actor.bankId},
  );
  if (rows.isEmpty) return null;
  final map = rows.first.toColumnMap();
  final round = bankInt(map['approval_round']);
  final stage = map['stage'] as String;
  final outcome = map['outcome'] as String?;

  final stepRows = await db.pool.execute(
    Sql.named('''
      SELECT s.id::text AS id, s.code, s.position, s.status, s.required_approvals,
             s.actor_label, s.reason,
             to_char(s.decided_at AT TIME ZONE 'Asia/Tashkent', 'DD.MM.YYYY HH24:MI') AS decided_at,
             s.actor_user_id::text AS actor_user_id
      FROM bank_approval_steps s
      WHERE s.tranche_id = @id::uuid
      ORDER BY s.position
    '''),
    parameters: {'id': id},
  );
  final votes = await db.pool.execute(
    Sql.named('''
      SELECT v.step_id::text AS step_id, v.user_id::text AS user_id, v.actor_label, v.vote, v.comment,
             to_char(v.created_at AT TIME ZONE 'Asia/Tashkent', 'DD.MM.YYYY HH24:MI') AS at
      FROM bank_approval_votes v
      JOIN bank_approval_steps s ON s.id = v.step_id
      WHERE s.tranche_id = @id::uuid AND v.round = @round
      ORDER BY v.created_at
    '''),
    parameters: {'id': id, 'round': round},
  );
  final members = await db.pool.execute(
    Sql.named('''
      SELECT g.code AS group_code, m.user_id::text AS user_id, u.name,
             (st.on_leave_until IS NOT NULL
              AND st.on_leave_until >= (now() AT TIME ZONE 'Asia/Tashkent')::date) AS on_leave,
             to_char(st.on_leave_until, 'DD.MM.YYYY') AS leave_until
      FROM bank_groups g
      JOIN bank_group_members m ON m.group_id = g.id
      JOIN users u ON u.id = m.user_id
      LEFT JOIN bank_staff st ON st.user_id = m.user_id
      WHERE g.bank_id = @bankId::uuid
      ORDER BY u.name
    '''),
    parameters: {'bankId': actor.bankId},
  );

  String? preparerId;
  for (final row in stepRows) {
    final step = row.toColumnMap();
    if (step['code'] == 'specialist') preparerId = step['actor_user_id'] as String?;
  }

  Map<String, Object?>? current;
  final steps = <Map<String, Object?>>[];
  for (final row in stepRows) {
    final step = row.toColumnMap();
    final code = step['code'] as String;
    final status = step['status'] as String;
    final groupCode = _groupOfStep[code];
    final kind = groupCode != null
        ? 'group'
        : (code == 'sign' || code == 'payment')
            ? 'external'
            : 'person';
    final groupMembers = [
      for (final member in members)
        if (member.toColumnMap()['group_code'] == groupCode) member.toColumnMap(),
    ];
    final stepVotes = [
      for (final vote in votes)
        if (vote.toColumnMap()['step_id'] == step['id']) vote.toColumnMap(),
    ];
    final approved = stepVotes.where((vote) => vote['vote'] == 'approve').length;
    final isCurrent = stage == 'approval' &&
        outcome == null &&
        current == null &&
        status == 'pending' &&
        kind == 'group';
    final entry = <String, Object?>{
      'code': code,
      'kind': kind,
      'status': isCurrent ? 'current' : status,
      'required': bankInt(step['required_approvals']),
      'approved': approved,
      'reason': step['reason'],
      'by': step['actor_label'],
      'decidedAt': step['decided_at'],
      if (kind == 'group')
        'group': {
          'size': groupMembers.length,
          'available': groupMembers.where((member) => !bankBool(member['on_leave'])).length,
          'onLeave': [
            for (final member in groupMembers)
              if (bankBool(member['on_leave']))
                {'name': member['name'], 'until': member['leave_until']},
          ],
        },
      'votes': [
        for (final vote in stepVotes)
          {
            'by': vote['actor_label'],
            'vote': vote['vote'],
            'comment': vote['comment'],
            'at': vote['at'],
          },
      ],
    };
    if (isCurrent) current = {...entry, 'id': step['id'], 'groupCode': groupCode};
    steps.add(entry);
  }

  var member = false;
  var onLeave = false;
  var voted = false;
  if (current != null) {
    for (final row in members) {
      final m = row.toColumnMap();
      if (m['group_code'] == current['groupCode'] && m['user_id'] == actor.userId) {
        member = true;
        onLeave = bankBool(m['on_leave']);
      }
    }
    voted = votes.any((row) {
      final v = row.toColumnMap();
      return v['step_id'] == current!['id'] && v['user_id'] == actor.userId;
    });
  }
  final blocker = _blocker(
    stage: stage,
    outcome: outcome,
    current: current,
    member: member,
    onLeave: onLeave,
    preparer: preparerId == actor.userId,
    voted: voted,
  );

  final decisionRows = await db.pool.execute(
    Sql.named('''
      SELECT return_lines, actor_label,
             to_char(created_at AT TIME ZONE 'Asia/Tashkent', 'DD.MM.YYYY HH24:MI') AS decided_at
      FROM bank_decisions
      WHERE tranche_id = @id::uuid AND kind = 'partial'
      ORDER BY created_at DESC LIMIT 1
    '''),
    parameters: {'id': id},
  );
  final decision = decisionRows.isEmpty ? null : decisionRows.first.toColumnMap();

  return {
    'id': map['id'],
    'projectName': map['project_name'],
    'trancheNo': bankInt(map['tranche_no']),
    'stage': stage,
    'stageLabel': map['stage_label'],
    'stages': [
      for (var i = 0; i < bankStageOrder.length; i++)
        {
          'code': bankStageOrder[i],
          'state': i < bankStageOrder.indexOf(stage)
              ? 'done'
              : (i == bankStageOrder.indexOf(stage) ? 'current' : 'pending'),
        },
    ],
    'round': round,
    'outcome': outcome,
    'expertSignedOn': map['expert_signed_on'],
    'threshold': map['threshold'],
    'totals': {'issue': map['issue'], 'returned': map['returned']},
    'waivedCount': bankInt(map['waived_count']),
    'returnDays': bankReturnDays,
    'returnLines': decision?['return_lines'] ?? const <Object>[],
    'steps': steps,
    'permissions': {'canAct': blocker == null, 'blocker': blocker},
  };
}

Future<Response> _act(Request request, AppDatabase db, String id) async {
  final opened = await bankMutating(request, db);
  if (opened is Response) return opened;
  if (!bankIsUuid(id)) return jsonError(404, 'not_found', 'Не найдено');
  final actor = await bankActor(db, (opened as SessionLookup).user!);
  if (actor == null) return jsonError(404, 'not_found', 'Не найдено');
  final parsed = await readJsonObject(request);
  if (parsed is String) return jsonError(400, 'validation', 'Не удалось прочитать запрос');
  final body = parsed as Map;
  final vote = body['vote'];
  final comment = ('${body['comment'] ?? ''}').trim();
  if (vote is! String || !_votes.contains(vote)) {
    return jsonError(400, 'validation', 'Выберите решение');
  }
  if (vote != 'approve' && comment.isEmpty) {
    return jsonError(400, 'validation', 'Опишите причину: её увидит специалист');
  }
  if (comment.length > 1000) return jsonError(400, 'validation', 'Комментарий слишком длинный');
  try {
    await db.pool.runTx((tx) async {
      await _vote(tx, db, id, actor, vote, comment);
    });
  } on BankFailure catch (failure) {
    return failure.toResponse();
  }
  final payload = await bankApprovalPayload(db, id, actor);
  return jsonResponse(200, {'approval': payload});
}

Future<void> _vote(
  Session tx,
  AppDatabase db,
  String id,
  BankActor actor,
  String vote,
  String comment,
) async {
  final locked = await tx.execute(
    Sql.named('''
      SELECT stage, outcome, approval_round FROM bank_tranches
      WHERE id = @id::uuid AND bank_id = @bank::uuid
      FOR UPDATE
    '''),
    parameters: {'id': id, 'bank': actor.bankId},
  );
  if (locked.isEmpty) throw const BankFailure(404, 'not_found', 'Не найдено');
  final tranche = locked.first.toColumnMap();
  if (tranche['outcome'] != null) {
    throw const BankFailure(409, 'closed', 'Транш уже закрыт');
  }
  if (tranche['stage'] != 'approval') {
    throw const BankFailure(409, 'not_now', 'Транш сейчас не на согласовании');
  }
  final round = bankInt(tranche['approval_round']);
  final steps = await tx.execute(
    Sql.named('''
      SELECT id::text AS id, code, status, required_approvals, actor_user_id::text AS actor_user_id
      FROM bank_approval_steps WHERE tranche_id = @id::uuid ORDER BY position
    '''),
    parameters: {'id': id},
  );
  Map<String, Object?>? current;
  String? preparerId;
  for (final row in steps) {
    final step = row.toColumnMap();
    if (step['code'] == 'specialist') preparerId = step['actor_user_id'] as String?;
    if (current == null && step['status'] == 'pending' && _groupOfStep.containsKey(step['code'])) {
      current = step;
    }
  }
  if (current == null) {
    throw const BankFailure(409, 'external', 'Следующий шаг выполняется во внешней системе');
  }
  final groupCode = _groupOfStep[current['code']]!;
  final member = await tx.execute(
    Sql.named('''
      SELECT (st.on_leave_until IS NOT NULL
              AND st.on_leave_until >= (now() AT TIME ZONE 'Asia/Tashkent')::date) AS on_leave
      FROM bank_groups g
      JOIN bank_group_members m ON m.group_id = g.id
      JOIN bank_staff st ON st.user_id = m.user_id
      WHERE g.bank_id = @bank::uuid AND g.code = @group AND m.user_id = @user::uuid
    '''),
    parameters: {'bank': actor.bankId, 'group': groupCode, 'user': actor.userId},
  );
  if (member.isEmpty) {
    throw const BankFailure(403, 'not_member', 'Вы не входите в группу, которая согласует этот шаг');
  }
  if (bankBool(member.first[0])) {
    throw const BankFailure(403, 'on_leave', 'Вы в отпуске и не участвуете в согласовании');
  }
  if (preparerId == actor.userId) {
    throw const BankFailure(403, 'preparer', 'Тот, кто готовил решение, согласовать его не может');
  }
  final seen = await tx.execute(
    Sql.named('''
      SELECT 1 FROM bank_approval_votes
      WHERE step_id = @step::uuid AND round = @round AND user_id = @user::uuid
    '''),
    parameters: {'step': current['id'], 'round': round, 'user': actor.userId},
  );
  if (seen.isNotEmpty) throw const BankFailure(409, 'voted', 'Вы уже проголосовали');

  await tx.execute(
    Sql.named('''
      INSERT INTO bank_approval_votes (step_id, round, user_id, actor_label, vote, comment)
      VALUES (@step::uuid, @round, @user::uuid, @label, @vote, @comment)
    '''),
    parameters: {
      'step': current['id'],
      'round': round,
      'user': actor.userId,
      'label': actor.name,
      'vote': vote,
      'comment': comment,
    },
  );
  await bankAudit(
    tx,
    bankId: actor.bankId,
    trancheId: id,
    userId: actor.userId,
    actorLabel: actor.name,
    action: 'vote',
    detail: {'step': current['code'], 'vote': vote, 'comment': comment, 'round': round},
  );

  if (vote == 'reject') {
    await tx.execute(
      Sql.named('''
        UPDATE bank_tranches
        SET outcome = 'rejected', stage_label = 'Отклонён банком', holder_user_id = NULL, holder_label = ''
        WHERE id = @id::uuid
      '''),
      parameters: {'id': id},
    );
    await _closeClock(tx, id);
    return;
  }

  if (vote == 'return') {
    await tx.execute(
      Sql.named('''
        UPDATE bank_approval_steps
        SET status = 'pending', actor_user_id = NULL, actor_label = '', decided_at = NULL
        WHERE tranche_id = @id::uuid AND code IN ('specialist', 'head', 'committee')
      '''),
      parameters: {'id': id},
    );
    await tx.execute(
      Sql.named('''
        UPDATE bank_tranches
        SET stage = 'specialist', stage_label = 'Возвращена специалисту',
            approval_round = approval_round + 1,
            holder_user_id = @prep::uuid,
            holder_label = COALESCE((SELECT name FROM users WHERE id = @prep::uuid), ''),
            elapsed_days = 0, elapsed_hours = 0
        WHERE id = @id::uuid
      '''),
      parameters: {'id': id, 'prep': preparerId},
    );
    await bankMoveClock(tx, id, 'specialist');
    await bankRecompute(tx, id);
    return;
  }

  final approvals = await tx.execute(
    Sql.named('''
      SELECT count(*) FROM bank_approval_votes
      WHERE step_id = @step::uuid AND round = @round AND vote = 'approve'
    '''),
    parameters: {'step': current['id'], 'round': round},
  );
  if (bankInt(approvals.first[0]) < bankInt(current['required_approvals'])) return;
  await tx.execute(
    Sql.named('''
      UPDATE bank_approval_steps
      SET status = 'done', decided_at = now(), actor_user_id = @user::uuid,
          actor_label = (
            SELECT string_agg(actor_label, ', ' ORDER BY created_at)
            FROM bank_approval_votes
            WHERE step_id = @step::uuid AND round = @round AND vote = 'approve')
      WHERE id = @step::uuid
    '''),
    parameters: {'step': current['id'], 'user': actor.userId, 'round': round},
  );
  final remaining = await tx.execute(
    Sql.named('''
      SELECT code FROM bank_approval_steps
      WHERE tranche_id = @id::uuid AND status = 'pending' AND code IN ('head', 'committee')
      ORDER BY position LIMIT 1
    '''),
    parameters: {'id': id},
  );
  if (remaining.isNotEmpty) {
    await tx.execute(
      Sql.named('''
        UPDATE bank_tranches SET holder_label = 'Кредитный комитет', stage_label = 'Согласование'
        WHERE id = @id::uuid
      '''),
      parameters: {'id': id},
    );
    return;
  }
  // Every internal approval is in. Signing and payment happen outside iBuild,
  // so the tranche only waits there and nothing here can finish them.
  await tx.execute(
    Sql.named('''
      UPDATE bank_tranches
      SET stage = 'payout', stage_label = 'Ожидает подписи ЭЦП',
          holder_user_id = NULL, holder_label = 'ЭЦП и платёж во внешней системе',
          elapsed_days = 0, elapsed_hours = 0
      WHERE id = @id::uuid
    '''),
    parameters: {'id': id},
  );
  await bankMoveClock(tx, id, 'payout');
}

Future<void> _closeClock(Session tx, String id) {
  return tx.execute(
    Sql.named('''
      UPDATE bank_tranche_clock SET ended_at = now()
      WHERE tranche_id = @id::uuid AND ended_at IS NULL
    '''),
    parameters: {'id': id},
  );
}
