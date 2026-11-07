import 'package:postgres/postgres.dart';

import 'bank_common.dart';
import 'db.dart';

const _fmt = bankMoneyFormat;
const _moment = "'DD.MM.YYYY HH24:MI'";

/// Buttons next to an open check. Accepting with a reason is only possible for
/// checks the rules let the bank accept; the forecast can only be requested.
List<String> bankCheckActions(String code, String level) {
  if (code == 'forecast') return const ['request_schedule'];
  if (level == 'block') return const ['request_document', 'waive'];
  return const ['waive'];
}

/// The whole card of a tranche for one person of the bank. Null when the
/// tranche does not exist for that bank.
Future<Map<String, Object?>?> bankTrancheCard(
  AppDatabase db,
  String id,
  BankActor actor,
) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT t.id::text AS id,
             p.id::text AS project_id,
             p.name AS project_name,
             p.address AS address,
             f.developer_name AS developer_name,
             f.funding_paused AS funding_paused,
             t.tranche_no AS tranche_no,
             t.stage AS stage,
             t.stage_label AS stage_label,
             t.waiting_developer AS waiting_developer,
             t.outcome AS outcome,
             t.approval_round AS approval_round,
             t.elapsed_days AS elapsed_days,
             t.elapsed_hours AS elapsed_hours,
             t.sla_days AS sla_days,
             to_char(t.submitted_at AT TIME ZONE 'Asia/Tashkent', 'DD.MM.YYYY') AS submitted_date,
             to_char(t.submitted_at AT TIME ZONE 'Asia/Tashkent', 'HH24:MI') AS submitted_time,
             to_char(t.tech_confirmed_on, 'DD.MM') AS tech_confirmed,
             to_char(t.requested_amount, $_fmt) AS requested,
             to_char(t.confirmed_amount, $_fmt) AS confirmed,
             to_char(t.blocked_amount, $_fmt) AS blocked,
             to_char(t.issue_amount, $_fmt) AS issue,
             to_char(t.requested_amount - t.issue_amount, $_fmt) AS returned,
             to_char(f.credit_limit, $_fmt) AS credit_limit,
             to_char(f.issued_amount, $_fmt) AS issued_total,
             to_char(f.credit_limit - f.issued_amount - t.issue_amount, $_fmt) AS remaining,
             v.version AS rules_version,
             (SELECT count(*) FROM bank_check_waivers w WHERE w.tranche_id = t.id) AS waived_count
      FROM bank_tranches t
      JOIN projects p ON p.id = t.project_id
      JOIN project_facilities f ON f.project_id = t.project_id AND f.bank_id = t.bank_id
      JOIN bank_rule_versions v ON v.id = t.rules_version_id
      WHERE t.id = @id::uuid AND t.bank_id = @bankId::uuid
    '''),
    parameters: {'id': id, 'bankId': actor.bankId},
  );
  if (rows.isEmpty) return null;
  final map = rows.first.toColumnMap();
  final checks = await _checks(db, id);
  final lines = await _lines(db, id);
  final decision = await _latestDecision(db, id);
  final days = bankInt(map['elapsed_days']);
  final hours = bankInt(map['elapsed_hours']);
  final sla = bankInt(map['sla_days']);
  final waiting = bankBool(map['waiting_developer']);
  final paused = bankBool(map['funding_paused']);
  final outcome = map['outcome'] as String?;
  final stage = map['stage'] as String;
  final current = bankStageOrder.indexOf(stage);
  final specialist = actor.role == 'specialist';
  final open = outcome == null && !waiting;
  return {
    'id': map['id'],
    'projectId': map['project_id'],
    'projectName': map['project_name'],
    'projectAddress': map['address'],
    'developerName': map['developer_name'],
    'trancheNo': bankInt(map['tranche_no']),
    'stage': stage,
    'stageLabel': map['stage_label'],
    'stages': [
      for (var i = 0; i < bankStageOrder.length; i++)
        {
          'code': bankStageOrder[i],
          'state': i < current ? 'done' : (i == current ? 'current' : 'pending'),
        },
    ],
    'waitingDeveloper': waiting,
    'outcome': outcome,
    'fundingPaused': paused,
    'submittedDate': map['submitted_date'],
    'submittedTime': map['submitted_time'],
    'techConfirmed': map['tech_confirmed'],
    'elapsedDays': days,
    'elapsedHours': hours,
    'slaDays': sla,
    'overdue': bankOverdue(waiting: waiting, days: days, hours: hours, sla: sla),
    'rulesVersion': bankInt(map['rules_version']),
    'creditLimit': map['credit_limit'],
    'issuedTotal': map['issued_total'],
    'waivedCount': bankInt(map['waived_count']),
    'totals': {
      'requested': map['requested'],
      'confirmed': map['confirmed'],
      'blocked': map['blocked'],
      'issue': map['issue'],
      'returned': map['returned'],
      'remaining': map['remaining'],
    },
    'permissions': {
      // Choose amounts, accept checks and decide: the specialist, while the
      // tranche is on his stage and nobody waits for the developer.
      'canDecide': specialist && open && stage == 'specialist' && !paused,
      'canRequest': specialist && open && (stage == 'specialist' || stage == 'docs'),
      'canResume': specialist && waiting && outcome == null,
      'canSuspend': specialist && outcome == null,
    },
    'checks': {
      'open': [for (final check in checks) if (check['passed'] != true) check],
      'passed': [for (final check in checks) if (check['passed'] == true) check],
    },
    'lines': lines,
    'decision': decision,
  };
}

bool bankOverdue({
  required bool waiting,
  required int days,
  required int hours,
  required int sla,
}) {
  return !waiting && (days > sla || (days == sla && hours > 0));
}

Future<List<Map<String, Object?>>> _checks(AppDatabase db, String trancheId) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT c.id::text AS id, c.code, c.level, c.basis, c.title, c.detail, c.passed,
             c.requested_kind AS requested_kind,
             to_char(c.requested_at AT TIME ZONE 'Asia/Tashkent', $_moment) AS requested_at,
             w.reason AS w_reason,
             w.comment AS w_comment,
             w.actor_label AS w_by,
             to_char(w.created_at AT TIME ZONE 'Asia/Tashkent', $_moment) AS w_at
      FROM bank_checks c
      LEFT JOIN bank_check_waivers w ON w.check_id = c.id
      WHERE c.tranche_id = @id::uuid
      ORDER BY c.sort_order, c.code
    '''),
    parameters: {'id': trancheId},
  );
  return [
    for (final row in rows)
      () {
        final map = row.toColumnMap();
        final passed = bankBool(map['passed']);
        final waived = map['w_reason'] != null;
        return <String, Object?>{
          'id': map['id'],
          'code': map['code'],
          'level': map['level'],
          'basis': map['basis'],
          'title': map['title'],
          'detail': map['detail'],
          'passed': passed,
          'actions': passed || waived
              ? const <String>[]
              : bankCheckActions(map['code'] as String, map['level'] as String),
          'requested': map['requested_kind'] == null
              ? null
              : {'kind': map['requested_kind'], 'at': map['requested_at']},
          'waiver': !waived
              ? null
              : {
                  'reason': map['w_reason'],
                  'comment': map['w_comment'],
                  'by': map['w_by'],
                  'at': map['w_at'],
                },
        };
      }(),
  ];
}

Future<List<Map<String, Object?>>> _lines(AppDatabase db, String trancheId) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT l.id::text AS id,
             l.title,
             to_char(l.issued_before, $_fmt) AS issued_before,
             to_char(l.requested, $_fmt) AS requested,
             to_char(l.readiness_percent, 'FM990.00') AS readiness_percent,
             to_char(l.previous_percent, 'FM990.00') AS previous_percent,
             l.readiness_note,
             to_char(l.confirmed, $_fmt) AS confirmed,
             to_char(l.to_issue, $_fmt) AS to_issue,
             l.choice,
             (l.requested <= l.confirmed) AS can_request,
             l.expert_name,
             to_char(l.expert_signed_on, 'DD.MM.YYYY') AS expert_signed_on,
             l.expert_note,
             to_char(l.remaining_to_build, $_fmt) AS remaining_to_build,
             to_char(l.recommended, $_fmt) AS recommended,
             l.risk_flag,
             to_char(l.plan_amount, $_fmt) AS plan_amount,
             to_char(l.plan_amount * l.readiness_percent / 100, $_fmt) AS gross,
             (
               l.block_check_id IS NOT NULL AND EXISTS (
                 SELECT 1 FROM bank_checks c
                 WHERE c.id = l.block_check_id
                   AND NOT c.passed
                   AND NOT EXISTS (SELECT 1 FROM bank_check_waivers w WHERE w.check_id = c.id)
               )
             ) AS blocked,
             (SELECT c.code FROM bank_checks c WHERE c.id = l.block_check_id) AS block_code
      FROM bank_tranche_lines l
      WHERE l.tranche_id = @id::uuid
      ORDER BY l.sort_order
    '''),
    parameters: {'id': trancheId},
  );
  final photos = await _children(db, trancheId, 'bank_line_photos', 'c.caption, c.meta', 'c.sort_order');
  final documents = await _children(db, trancheId, 'bank_line_documents', 'c.title, c.state', 'c.sort_order');
  final payments = await _children(
    db,
    trancheId,
    'bank_line_payments',
    "c.label, to_char(c.paid_on, 'DD.MM.YYYY') AS paid_on, to_char(c.amount, $_fmt) AS amount",
    'c.paid_on',
  );
  return [
    for (final row in rows)
      () {
        final map = row.toColumnMap();
        final lineId = map['id'] as String;
        final blocked = bankBool(map['blocked']);
        final requested = map['requested'] as String;
        final confirmed = map['confirmed'] as String;
        final percent = _percent(map['readiness_percent'] as String?);
        final toIssue = map['to_issue'] as String;
        final level = blocked
            ? 'block'
            : bankCents(confirmed) < bankCents(requested)
                ? 'warning'
                : 'ok';
        final expertName = map['expert_name'] as String;
        return <String, Object?>{
          'id': lineId,
          'title': map['title'],
          'issuedBefore': map['issued_before'],
          'requested': requested,
          'readinessPercent': percent,
          'readinessNote': map['readiness_note'],
          'confirmed': confirmed,
          'toIssue': toIssue,
          'choice': map['choice'],
          'canChooseRequested': bankBool(map['can_request']),
          'blocked': blocked,
          'blockCode': map['block_code'],
          'level': level,
          'expert': expertName.isEmpty
              ? null
              : {
                  'name': expertName,
                  'signedOn': map['expert_signed_on'],
                  'note': map['expert_note'],
                  'readinessPercent': percent,
                  'previousPercent': _percent(map['previous_percent'] as String?),
                  'remaining': map['remaining_to_build'],
                  'recommended': map['recommended'],
                  'riskFlag': bankBool(map['risk_flag']),
                },
          'formula': map['plan_amount'] == null || percent == null
              ? null
              : {
                  'percent': percent,
                  'plan': map['plan_amount'],
                  'gross': map['gross'],
                  'issuedBefore': map['issued_before'],
                  'result': confirmed,
                },
          'photos': photos[lineId] ?? const <Map<String, Object?>>[],
          'documents': documents[lineId] ?? const <Map<String, Object?>>[],
          'payments': payments[lineId] ?? const <Map<String, Object?>>[],
        };
      }(),
  ];
}

Future<Map<String, List<Map<String, Object?>>>> _children(
  AppDatabase db,
  String trancheId,
  String table,
  String columns,
  String order,
) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT c.line_id::text AS line_id, $columns
      FROM $table c
      JOIN bank_tranche_lines l ON l.id = c.line_id
      WHERE l.tranche_id = @id::uuid
      ORDER BY c.line_id, $order
    '''),
    parameters: {'id': trancheId},
  );
  final grouped = <String, List<Map<String, Object?>>>{};
  for (final row in rows) {
    final map = row.toColumnMap();
    final lineId = map.remove('line_id') as String;
    grouped.putIfAbsent(lineId, () => []).add({
      for (final entry in map.entries) _camel(entry.key): entry.value,
    });
  }
  return grouped;
}

String _camel(String name) {
  final parts = name.split('_');
  return parts.first + parts.skip(1).map((part) => part[0].toUpperCase() + part.substring(1)).join();
}

Future<Map<String, Object?>?> _latestDecision(AppDatabase db, String trancheId) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT kind, round,
             to_char(issue_amount, $_fmt) AS issue_amount,
             to_char(returned_amount, $_fmt) AS returned_amount,
             waived_count, return_lines, note, actor_label,
             to_char(created_at AT TIME ZONE 'Asia/Tashkent', $_moment) AS decided_at
      FROM bank_decisions
      WHERE tranche_id = @id::uuid
      ORDER BY created_at DESC
      LIMIT 1
    '''),
    parameters: {'id': trancheId},
  );
  if (rows.isEmpty) return null;
  final map = rows.first.toColumnMap();
  return {
    'kind': map['kind'],
    'round': bankInt(map['round']),
    'issueAmount': map['issue_amount'],
    'returnedAmount': map['returned_amount'],
    'waivedCount': bankInt(map['waived_count']),
    'returnLines': map['return_lines'],
    'note': map['note'],
    'by': map['actor_label'],
    'at': map['decided_at'],
  };
}

String? _percent(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.endsWith('.00')) return raw.substring(0, raw.length - 3);
  return raw;
}

BigInt bankCents(String value) {
  final negative = value.startsWith('-');
  final parts = (negative ? value.substring(1) : value).split('.');
  final cents = BigInt.parse(parts[0]) * BigInt.from(100) +
      BigInt.parse((parts.length > 1 ? parts[1] : '0').padRight(2, '0').substring(0, 2));
  return negative ? -cents : cents;
}
