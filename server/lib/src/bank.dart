import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'bank_approval.dart';
import 'bank_card.dart';
import 'bank_common.dart';
import 'bank_decision.dart';
import 'bank_portfolio.dart';
import 'bank_reports.dart';
import 'bank_rules_api.dart';
import 'db.dart';
import 'http_util.dart';

const _queueTabs = {'mine', 'all', 'developer', 'overdue'};

void mountBank(Router router, AppDatabase db) {
  router
    ..get('/api/bank/queue', (Request request) => _queue(request, db))
    ..get('/api/bank/tranches/<id>', (Request request, String id) => _tranche(request, db, id))
    ..get('/api/bank/tranches/<id>/journal', (Request request, String id) => _journal(request, db, id));
  mountBankDecision(router, db);
  mountBankApproval(router, db);
  mountBankPortfolio(router, db);
  mountBankReports(router, db);
  mountBankRules(router, db);
}

Future<Map<String, Object?>?> bankProfile(AppDatabase db, String userId) async {
  await bankRefreshElapsed(db);
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT s.bank_id::text AS bank_id,
             c.name AS name,
             p.department AS department,
             s.role AS role,
             s.title AS title,
             s.branch AS branch
      FROM bank_staff s
      JOIN bank_profiles p ON p.company_id = s.bank_id
      JOIN companies c ON c.id = s.bank_id
      WHERE s.user_id = @userId::uuid AND s.active
    '''),
    parameters: {'userId': userId},
  );
  if (rows.isEmpty) return null;
  final staff = rows.first.toColumnMap();
  final bankId = staff['bank_id'] as String;
  final counts = await _counts(db, bankId, userId, staff['role'] as String);
  return {
    'id': bankId,
    'name': staff['name'],
    'department': staff['department'],
    'role': staff['role'],
    'title': staff['title'],
    'branch': staff['branch'],
    'queueCount': counts.mine,
    'trancheCount': counts.all,
    'waitingAmount': counts.waitingAmount,
  };
}

Future<Response> _queue(Request request, AppDatabase db) async {
  final session = await bankSession(request, db);
  if (session is Response) return session;
  final user = (session as SessionLookup).user!;
  final profile = await bankProfile(db, user.id);
  if (profile == null) return jsonError(404, 'not_found', 'Ничего не найдено.');
  final tab = request.url.queryParameters['tab'] ?? 'mine';
  if (!_queueTabs.contains(tab)) {
    return jsonError(400, 'validation', 'Такой вкладки нет.');
  }
  final items = await _items(db, profile['id'] as String, user.id, profile['role'] as String);
  final counts = {
    'mine': items.where((item) => item['mine'] == true).length,
    'all': items.length,
    'developer': items.where((item) => item['waitingDeveloper'] == true).length,
    'overdue': items.where((item) => item['overdue'] == true).length,
  };
  final shown = items.where((item) {
    return switch (tab) {
      'mine' => item['mine'] == true,
      'developer' => item['waitingDeveloper'] == true,
      'overdue' => item['overdue'] == true,
      _ => true,
    };
  }).toList();
  return jsonResponse(200, {
    'bankName': profile['name'],
    'department': profile['department'],
    'tab': tab,
    'counts': counts,
    'waitingAmount': profile['waitingAmount'],
    'items': shown,
  });
}

Future<Response> _tranche(Request request, AppDatabase db, String id) async {
  final session = await bankSession(request, db);
  if (session is Response) return session;
  if (!bankIsUuid(id)) return jsonError(404, 'not_found', 'Не найдено');
  final actor = await bankActor(db, (session as SessionLookup).user!);
  if (actor == null) return jsonError(404, 'not_found', 'Не найдено');
  await bankRefreshElapsed(db);
  final card = await bankTrancheCard(db, id, actor);
  if (card == null) return jsonError(404, 'not_found', 'Не найдено');
  return jsonResponse(200, card);
}

Future<({int mine, int all, String waitingAmount})> _counts(
  AppDatabase db,
  String bankId,
  String userId,
  String role,
) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT count(*) AS all_count,
             count(*) FILTER (WHERE ${_mineSql('bank_tranches')}) AS mine_count,
             to_char(COALESCE(sum(requested_amount), 0), 'FM999999999999990.00') AS waiting_amount
      FROM bank_tranches
      WHERE bank_id = @bankId::uuid
    '''),
    parameters: {'bankId': bankId, 'userId': userId, 'role': role},
  );
  final map = rows.first.toColumnMap();
  return (
    mine: bankInt(map['mine_count']),
    all: bankInt(map['all_count']),
    waitingAmount: map['waiting_amount'] as String,
  );
}

Future<List<Map<String, Object?>>> _items(
  AppDatabase db,
  String bankId,
  String userId,
  String role,
) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT t.id::text AS id,
             p.name AS project_name,
             f.developer_name AS developer_name,
             t.tranche_no AS tranche_no,
             to_char(t.requested_amount, 'FM999999999999990.00') AS requested_amount,
             t.stage AS stage,
             t.stage_label AS stage_label,
             t.elapsed_days AS elapsed_days,
             t.elapsed_hours AS elapsed_hours,
             t.sla_days AS sla_days,
             t.waiting_developer AS waiting_developer,
             t.problems_label AS problems_label,
             t.holder_label AS holder_label,
             t.signal AS signal,
             (${_mineSql('t')}) AS mine
      FROM bank_tranches t
      JOIN projects p ON p.id = t.project_id
      JOIN project_facilities f ON f.project_id = p.id AND f.bank_id = t.bank_id
      WHERE t.bank_id = @bankId::uuid
      ORDER BY t.sort_order, t.tranche_no
    '''),
    parameters: {'bankId': bankId, 'userId': userId, 'role': role},
  );
  return [
    for (final row in rows) _item(row.toColumnMap()),
  ];
}

String _mineSql(String t) => '''
  CASE
    WHEN @role = 'specialist'
      AND NOT $t.waiting_developer
      AND $t.stage IN ('docs', 'specialist')
      AND $t.holder_user_id = @userId::uuid THEN true
    WHEN @role = 'expert'
      AND NOT $t.waiting_developer
      AND $t.stage = 'inspection'
      AND $t.holder_user_id = @userId::uuid THEN true
    ELSE false
  END
''';

Map<String, Object?> _item(Map<String, Object?> map) {
  final days = bankInt(map['elapsed_days']);
  final hours = bankInt(map['elapsed_hours']);
  final sla = bankInt(map['sla_days']);
  final waiting = bankBool(map['waiting_developer']);
  return {
    'id': map['id'],
    'projectName': map['project_name'],
    'developerName': map['developer_name'],
    'trancheNo': bankInt(map['tranche_no']),
    'requestedAmount': map['requested_amount'],
    'stage': map['stage'],
    'stageLabel': map['stage_label'],
    'elapsedDays': days,
    'elapsedHours': hours,
    'slaDays': sla,
    'elapsedLabel': _elapsedLabel(waiting: waiting, days: days, hours: hours, sla: sla),
    'problemsLabel': map['problems_label'],
    'holderLabel': map['holder_label'],
    'signal': map['signal'],
    'waitingDeveloper': waiting,
    'overdue': _isOverdue(waiting: waiting, days: days, hours: hours, sla: sla),
    'mine': bankBool(map['mine']),
  };
}

/// Time at the developer is not bank time, so a waiting tranche is never late.
bool _isOverdue({
  required bool waiting,
  required int days,
  required int hours,
  required int sla,
}) {
  return !waiting && (days > sla || (days == sla && hours > 0));
}

String _elapsedLabel({
  required bool waiting,
  required int days,
  required int hours,
  required int sla,
}) {
  if (waiting) return '$days д у застройщика';
  final spent = hours == 0
      ? '$days д'
      : days == 0
          ? '$hours ч'
          : '$days д $hours ч';
  return '$spent из $sla д';
}

/// Who, what, when for one tranche, newest first. The bank reads only its own
/// journal: the database filters rows by the bank of the person.
Future<Response> _journal(Request request, AppDatabase db, String id) async {
  final session = await bankSession(request, db);
  if (session is Response) return session;
  if (!bankIsUuid(id)) return jsonError(404, 'not_found', 'Не найдено');
  final actor = await bankActor(db, (session as SessionLookup).user!);
  if (actor == null) return jsonError(404, 'not_found', 'Не найдено');
  final exists = await db.pool.execute(
    Sql.named('SELECT 1 FROM bank_tranches WHERE id = @id::uuid AND bank_id = @bank::uuid'),
    parameters: {'id': id, 'bank': actor.bankId},
  );
  if (exists.isEmpty) return jsonError(404, 'not_found', 'Не найдено');
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT id::text AS id, action, actor_label, created_at, detail
      FROM bank_audit_events
      WHERE tranche_id = @id::uuid
      ORDER BY created_at DESC, id DESC
      LIMIT 200
    '''),
    parameters: {'id': id},
  );
  return jsonResponse(200, {
    'events': [
      for (final row in rows)
        {
          'id': row[0],
          'action': row[1],
          'actor': row[2],
          'at': (row[3]! as DateTime).toUtc().toIso8601String(),
          'detail': row[4],
        },
    ],
  });
}
