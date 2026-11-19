import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import 'bank_sla.dart';
import 'db.dart';
import 'http_util.dart';
import 'passwords.dart';

const bankUuidPattern =
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

const bankMoneyFormat = "'FM999999999999990.00'";

/// Working days the developer gets to fix the lines that were sent back.
const bankReturnDays = 5;

bool bankIsUuid(String value) => RegExp(bankUuidPattern).hasMatch(value);

int bankInt(Object? value) {
  if (value is int) return value;
  if (value is BigInt) return value.toInt();
  if (value is double) return value.round();
  return int.parse(value.toString());
}

bool bankBool(Object? value) {
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  return text == 'true' || text == 't';
}

Future<Object> bankSession(Request request, AppDatabase db) async {
  final token = readCookies(request)[sessionCookieName];
  if (token == null || token.isEmpty) {
    return jsonError(401, 'unauthenticated', 'Нужно войти');
  }
  final lookup = await db.lookupSession(sha256Hex(token));
  switch (lookup.state) {
    case SessionState.ok:
      return lookup;
    case SessionState.inactive:
      return jsonError(403, 'inactive', 'Учётная запись отключена');
    case SessionState.missing:
    case SessionState.expired:
      return jsonError(401, 'unauthenticated', 'Нужно войти');
  }
}

/// A session that may also change data: the CSRF token must match.
Future<Object> bankMutating(Request request, AppDatabase db) async {
  final opened = await bankSession(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  final header = request.headers['x-csrf-token'] ?? '';
  final expected = session.csrfToken ?? '';
  if (header.isEmpty || expected.isEmpty || !tokensEqual(header, expected)) {
    return jsonError(403, 'csrf', 'Сессия устарела. Обновите страницу и войдите снова');
  }
  return session;
}

class BankActor {
  const BankActor({
    required this.userId,
    required this.name,
    required this.bankId,
    required this.role,
  });

  final String userId;
  final String name;
  final String bankId;
  final String role;
}

Future<BankActor?> bankActor(AppDatabase db, UserRecord user) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT bank_id::text AS bank_id, role
      FROM bank_staff
      WHERE user_id = @userId::uuid AND active
    '''),
    parameters: {'userId': user.id},
  );
  if (rows.isEmpty) return null;
  final map = rows.first.toColumnMap();
  return BankActor(
    userId: user.id,
    name: user.name,
    bankId: map['bank_id'] as String,
    role: map['role'] as String,
  );
}

class BankFailure implements Exception {
  const BankFailure(this.status, this.code, this.message);

  final int status;
  final String code;
  final String message;

  Response toResponse() => jsonError(status, code, message);
}

class BankKeyReused implements Exception {}

/// Same rules as the requests of the developer: the same key with the same
/// content returns the first answer, the same key with other content is a 409.
String bankFingerprint(Object? value) => sha256Hex(jsonEncode(value));

Future<Map<String, Object?>?> bankReplay(
  Session session,
  String userId,
  String key,
  String fingerprint,
) async {
  final rows = await session.execute(
    Sql.named('''
      SELECT fingerprint, body
      FROM idempotency_keys
      WHERE user_id = @userId::uuid AND idempotency_key = @key
    '''),
    parameters: {'userId': userId, 'key': key},
  );
  if (rows.isEmpty) return null;
  final map = rows.first.toColumnMap();
  if (map['fingerprint'] != fingerprint) throw BankKeyReused();
  return (jsonDecode(map['body'] as String) as Map).map(
    (name, value) => MapEntry(name.toString(), value),
  );
}

Future<void> bankRemember(
  Session session,
  String userId,
  String key,
  String fingerprint,
  Map<String, Object?> body,
) {
  return session.execute(
    Sql.named('''
      INSERT INTO idempotency_keys (user_id, idempotency_key, fingerprint, status_code, body)
      VALUES (@userId::uuid, @key, @fingerprint, 200, @body)
    '''),
    parameters: {
      'userId': userId,
      'key': key,
      'fingerprint': fingerprint,
      'body': jsonEncode(body),
    },
  );
}

/// The stages in the order of the route.
const bankStageOrder = ['submitted', 'docs', 'inspection', 'specialist', 'approval', 'payout'];

String bankPlural(int count, String one, String few, String many) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

/// Everything that depends on the choices of the specialist is counted here,
/// in one place, and only on the server: amounts per line, blocked, to issue,
/// the label of problems and the need for the credit committee.
Future<void> bankRecompute(Session tx, String trancheId) async {
  final params = {'id': trancheId};
  const blockedLine = '''
    l.block_check_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM bank_checks c
      WHERE c.id = l.block_check_id
        AND NOT c.passed
        AND NOT EXISTS (SELECT 1 FROM bank_check_waivers w WHERE w.check_id = c.id)
    )
  ''';
  final lineCount = await tx.execute(
    Sql.named('SELECT count(*) FROM bank_tranche_lines WHERE tranche_id = @id::uuid'),
    parameters: params,
  );
  if (bankInt(lineCount.first[0]) > 0) {
    await tx.execute(
      Sql.named('''
        UPDATE bank_tranche_lines l
        SET to_issue = CASE
          WHEN $blockedLine THEN 0
          WHEN l.choice = 'confirmed' THEN l.confirmed
          WHEN l.choice = 'requested' THEN l.requested
          ELSE 0
        END
        WHERE l.tranche_id = @id::uuid
      '''),
      parameters: params,
    );
    await tx.execute(
      Sql.named('''
        UPDATE bank_tranches t
        SET issue_amount = s.issue,
            blocked_amount = s.blocked,
            confirmed_amount = s.confirmed
        FROM (
          SELECT COALESCE(sum(l.to_issue), 0) AS issue,
                 COALESCE(sum(CASE WHEN $blockedLine THEN l.confirmed ELSE 0 END), 0) AS blocked,
                 COALESCE(sum(l.confirmed), 0) AS confirmed
          FROM bank_tranche_lines l
          WHERE l.tranche_id = @id::uuid
        ) s
        WHERE t.id = @id::uuid
      '''),
      parameters: params,
    );
  }

  final checks = await tx.execute(
    Sql.named('''
      SELECT c.level AS level,
             (w.id IS NOT NULL) AS waived
      FROM bank_checks c
      LEFT JOIN bank_check_waivers w ON w.check_id = c.id
      WHERE c.tranche_id = @id::uuid AND NOT c.passed
    '''),
    parameters: params,
  );
  final allChecks = await tx.execute(
    Sql.named('SELECT count(*) FROM bank_checks WHERE tranche_id = @id::uuid'),
    parameters: params,
  );
  if (bankInt(allChecks.first[0]) > 0) {
    var blocks = 0;
    var warnings = 0;
    var waived = 0;
    for (final row in checks) {
      final map = row.toColumnMap();
      if (bankBool(map['waived'])) {
        waived++;
      } else if (map['level'] == 'block') {
        blocks++;
      } else if (map['level'] == 'warning') {
        warnings++;
      }
    }
    final parts = <String>[
      if (blocks > 0) '$blocks ${bankPlural(blocks, 'блок', 'блока', 'блоков')}',
      if (warnings > 0)
        '$warnings ${bankPlural(warnings, 'предупреждение', 'предупреждения', 'предупреждений')}',
      if (waived > 0) 'Принято с обоснованием: $waived',
    ];
    final signal = blocks > 0
        ? 'block'
        : (warnings > 0 || waived > 0)
            ? 'warning'
            : 'none';
    final tranche = await tx.execute(
      Sql.named('SELECT waiting_developer FROM bank_tranches WHERE id = @id::uuid'),
      parameters: params,
    );
    final waiting = bankBool(tranche.first[0]);
    await tx.execute(
      Sql.named('''
        UPDATE bank_tranches
        SET problems_label = @label,
            signal = CASE WHEN @waiting THEN 'developer' ELSE @signal END
        WHERE id = @id::uuid
      '''),
      parameters: {
        'id': trancheId,
        'label': parts.join(' · '),
        'signal': signal,
        'waiting': waiting,
      },
    );
  }

  await bankRecomputeCommittee(tx, trancheId);
}

/// The credit committee joins the route when the amount is above the threshold
/// of the rules this tranche was submitted under, or when a blocking check was
/// accepted with a reason.
Future<void> bankRecomputeCommittee(Session tx, String trancheId) async {
  final rows = await tx.execute(
    Sql.named('''
      SELECT s.id::text AS step_id,
             s.status AS status,
             t.issue_amount > COALESCE((v.snapshot ->> 'committeeAmount')::numeric, 0) AS over_amount,
             EXISTS (
               SELECT 1 FROM bank_check_waivers w
               JOIN bank_checks c ON c.id = w.check_id
               WHERE w.tranche_id = t.id AND c.level = 'block'
             ) AS waived_block
      FROM bank_approval_steps s
      JOIN bank_tranches t ON t.id = s.tranche_id
      JOIN bank_rule_versions v ON v.id = t.rules_version_id
      WHERE t.id = @id::uuid AND s.code = 'committee'
    '''),
    parameters: {'id': trancheId},
  );
  if (rows.isEmpty) return;
  final map = rows.first.toColumnMap();
  final status = map['status'] as String;
  if (status == 'done') return;
  final waivedBlock = bankBool(map['waived_block']);
  final overAmount = bankBool(map['over_amount']);
  final required = waivedBlock || overAmount;
  final reason = waivedBlock
      ? 'waived_block'
      : overAmount
          ? 'amount_over'
          : 'below_threshold';
  await tx.execute(
    Sql.named('''
      UPDATE bank_approval_steps
      SET status = @status, reason = @reason
      WHERE id = @stepId::uuid
    '''),
    parameters: {
      'stepId': map['step_id'],
      'status': required ? 'pending' : 'skipped',
      'reason': reason,
    },
  );
}

/// One line of the journal of the bank. Written in the same transaction as the
/// change itself, so a change without a trace cannot happen.
Future<void> bankAudit(
  Session tx, {
  required String bankId,
  required String action,
  String? trancheId,
  String? userId,
  String actorLabel = '',
  Map<String, Object?> detail = const {},
}) {
  return tx.execute(
    Sql.named('''
      INSERT INTO bank_audit_events (bank_id, tranche_id, project_id, user_id, actor_label, action, detail)
      VALUES (
        @bank::uuid,
        @tranche::uuid,
        (SELECT project_id FROM bank_tranches WHERE id = @tranche::uuid),
        @user::uuid,
        @label,
        @action,
        @detail::jsonb
      )
    '''),
    parameters: {
      'bank': bankId,
      'tranche': trancheId,
      'user': userId,
      'label': actorLabel,
      'action': action,
      'detail': jsonEncode(detail),
    },
  );
}

Future<void> _closeOpenClock(Session tx, String id) {
  return tx.execute(
    Sql.named('''
      UPDATE bank_tranche_clock SET ended_at = now()
      WHERE tranche_id = @id::uuid AND ended_at IS NULL
    '''),
    parameters: {'id': id},
  );
}

Future<void> _openClock(Session tx, String id, String stageSql, {required bool paused}) {
  return tx.execute(
    Sql.named('''
      INSERT INTO bank_tranche_clock (tranche_id, stage, started_at, paused)
      VALUES (@id::uuid, $stageSql, now(), @paused)
    '''),
    parameters: {'id': id, 'paused': paused},
  );
}

/// The expert visit of this tranche is done. The tranche leaves inspection and
/// the specialist may decide. A tranche on any other stage is left as it is.
Future<bool> bankReleaseExpertVisit(Session tx, String id, String bankId) async {
  final rows = await tx.execute(
    Sql.named('SELECT stage FROM bank_tranches WHERE id = @id::uuid AND bank_id = @bank::uuid'),
    parameters: {'id': id, 'bank': bankId},
  );
  if (rows.isEmpty || rows.first[0] != 'inspection') return false;
  final holder = await tx.execute(
    Sql.named('''
      SELECT s.user_id::text, u.name
      FROM bank_staff s JOIN users u ON u.id = s.user_id
      WHERE s.bank_id = @bank::uuid AND s.role = 'specialist' AND s.active
      ORDER BY (
        SELECT count(*) FROM bank_tranches t
        WHERE t.holder_user_id = s.user_id AND t.outcome IS NULL
      ), u.name
      LIMIT 1
    '''),
    parameters: {'bank': bankId},
  );
  await tx.execute(
    Sql.named('''
      UPDATE bank_approval_steps
      SET status = 'done', decided_at = now(), actor_label = 'Осмотр зафиксирован'
      WHERE tranche_id = @id::uuid AND code = 'expert' AND status = 'pending'
    '''),
    parameters: {'id': id},
  );
  await tx.execute(
    Sql.named('''
      UPDATE bank_tranches
      SET stage = 'specialist',
          stage_label = 'Решение специалиста',
          holder_user_id = @holder::uuid,
          holder_label = @label,
          problems_label = CASE WHEN problems_label = 'Ждёт осмотра' THEN '' ELSE problems_label END,
          signal = CASE WHEN signal = 'inspection' THEN 'none' ELSE signal END,
          sla_days = bank_stage_days(rules_version_id, 'specialist', sla_days),
          elapsed_days = 0,
          elapsed_hours = 0
      WHERE id = @id::uuid
    '''),
    parameters: {
      'id': id,
      'holder': holder.isEmpty ? null : holder.first[0],
      'label': holder.isEmpty ? '' : '${holder.first[1]}, кредитный специалист',
    },
  );
  await bankMoveClock(tx, id, 'specialist');
  await bankAudit(
    tx,
    bankId: bankId,
    trancheId: id,
    actorLabel: 'Система',
    action: 'inspection_reported',
    detail: {'stage': 'specialist'},
  );
  return true;
}

/// The tranche enters a new stage: the old interval ends, the new one starts and
/// the stage deadline counts from now.
Future<void> bankMoveClock(Session tx, String id, String stage) async {
  await _closeOpenClock(tx, id);
  await tx.execute(
    Sql.named('''
      INSERT INTO bank_tranche_clock (tranche_id, stage, started_at, paused)
      VALUES (@id::uuid, @stage, now(), false)
    '''),
    parameters: {'id': id, 'stage': stage},
  );
  await tx.execute(
    Sql.named('UPDATE bank_tranches SET stage_entered_at = now() WHERE id = @id::uuid'),
    parameters: {'id': id},
  );
}

/// The tranche goes to the developer: bank time stops.
Future<void> bankPauseClock(Session tx, String id) async {
  await _closeOpenClock(tx, id);
  await _openClock(tx, id, '(SELECT stage FROM bank_tranches WHERE id = @id::uuid)', paused: true);
}

/// The developer answered: bank time runs again on the same stage.
Future<void> bankResumeClock(Session tx, String id) async {
  await _closeOpenClock(tx, id);
  await _openClock(tx, id, '(SELECT stage FROM bank_tranches WHERE id = @id::uuid)', paused: false);
}

/// Recounts the time the bank spent on the current stage of every tranche that
/// came from a real draw. Tranches of the demo set keep the numbers they were
/// given. Runs before the queue and the card are read.
Future<void> bankRefreshElapsed(AppDatabase db, {DateTime? now}) async {
  final moment = (now ?? DateTime.now()).toUtc();
  final rows = await db.owner.execute(
    Sql.named('''
      SELECT t.id::text AS id, t.stage_entered_at AS entered, t.elapsed_days, t.elapsed_hours
      FROM bank_tranches t
      WHERE t.request_id IS NOT NULL AND t.outcome IS NULL
    '''),
  );
  if (rows.isEmpty) return;
  final holidays = {
    for (final row in await db.owner.execute("SELECT to_char(day, 'YYYY-MM-DD') FROM bank_holidays"))
      row[0]! as String,
  };
  for (final row in rows) {
    final map = row.toColumnMap();
    final id = map['id'] as String;
    final entered = (map['entered'] as DateTime).toUtc();
    final clock = await db.owner.execute(
      Sql.named('''
        SELECT started_at, ended_at FROM bank_tranche_clock
        WHERE tranche_id = @id::uuid AND NOT paused
      '''),
      parameters: {'id': id},
    );
    final minutes = bankStageMinutes(
      [
        for (final item in clock)
          BankInterval(
            (item[0]! as DateTime).toUtc(),
            (item[1] as DateTime?)?.toUtc(),
          ),
      ],
      entered,
      moment,
      holidays,
    );
    final elapsed = bankElapsedOf(minutes);
    if (elapsed.days == bankInt(map['elapsed_days']) && elapsed.hours == bankInt(map['elapsed_hours'])) {
      continue;
    }
    await db.owner.execute(
      Sql.named('''
        UPDATE bank_tranches SET elapsed_days = @days, elapsed_hours = @hours WHERE id = @id::uuid
      '''),
      parameters: {'id': id, 'days': elapsed.days, 'hours': elapsed.hours},
    );
  }
}
