import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'bank_card.dart' show bankCents;
import 'money.dart';
import 'bank_common.dart';
import 'mail.dart';
import 'bank_data.dart';
import 'bank_rules.dart' show bankMillions;
import 'bank_sla.dart';
import 'db.dart';
import 'mailbox.dart';
import 'http_util.dart';

/// Portfolio, objects, inspections and developers of the bank. Every number
/// comes from the real tables; where the data does not exist yet the screen
/// says so instead of showing an invented figure.

const _writers = {'specialist', 'head', 'risk', 'admin', 'expert'};

void mountBankPortfolio(Router router, AppDatabase db) {
  router
    ..get('/api/bank/portfolio', (Request r) => _portfolio(r, db))
    ..get('/api/bank/objects', (Request r) => _objects(r, db))
    ..get('/api/bank/objects/<id>', (Request r, String id) => _object(r, db, id))
    ..post('/api/bank/objects/<id>/limit', (Request r, String id) => _setLimit(r, db, id))
    ..post('/api/bank/objects/<id>/remind', (Request r, String id) => _remind(r, db, id))
    ..get('/api/bank/inspections', (Request r) => _inspections(r, db))
    ..post('/api/bank/inspections', (Request r) => _planInspection(r, db))
    ..post('/api/bank/inspections/<id>/complete', (Request r, String id) => _completeInspection(r, db, id))
    ..get('/api/bank/developers', (Request r) => _developers(r, db))
    ..get('/api/bank/developers/<id>', (Request r, String id) => _developer(r, db, id))
    ..post('/api/bank/developers/<id>/filings', (Request r, String id) => _file(r, db, id));
}

/// The rule values of the version in force.
Future<Map<String, Object?>> bankRulesNow(AppDatabase db, String bankId) async {
  final rows = await bankRows(
    db,
    '''
      SELECT snapshot, version FROM bank_rule_versions
      WHERE bank_id = @bank::uuid AND effective_from <= $bankToday
      ORDER BY version DESC LIMIT 1
    ''',
    {'bank': bankId},
  );
  if (rows.isEmpty) return const {};
  return {
    ...Map<String, Object?>.from(rows.first['snapshot']! as Map),
    'version': rows.first['version'],
  };
}

String _ruDate(String day) => '${day.substring(8, 10)}.${day.substring(5, 7)}';

String _dayText(DateTime day) => bankDay(day)!;

/// The last date of the sales report that has already passed, for the days the
/// bank set (for example the 15th and the 28th of each month).
String bankLastSalesDue(DateTime today, List<int> days) {
  final sorted = [...days]..sort();
  for (var back = 0; back < 2; back++) {
    final month = DateTime.utc(today.year, today.month - back, 1);
    for (final day in sorted.reversed) {
      final due = DateTime.utc(month.year, month.month, day);
      if (due.month == month.month && !due.isAfter(today)) return _dayText(due);
    }
  }
  return _dayText(today);
}

List<String> _nextSalesDues(DateTime today, List<int> days) {
  final result = <String>[];
  final sorted = [...days]..sort();
  for (var ahead = 0; ahead < 3 && result.length < 2; ahead++) {
    final month = DateTime.utc(today.year, today.month + ahead, 1);
    for (final day in sorted) {
      final due = DateTime.utc(month.year, month.month, day);
      if (due.month == month.month && due.isAfter(today)) result.add(_dayText(due));
    }
  }
  return result.take(2).toList();
}

List<int> _salesDays(Map<String, Object?> rules) {
  final raw = rules['salesReportDays'];
  final days = [
    if (raw is List)
      for (final day in raw)
        if (day is num && day >= 1 && day <= 28) day.toInt(),
  ];
  return days.isEmpty ? const [15, 28] : days;
}

/// What needs attention at the objects of the bank, with the ground of the
/// contract and the next step. One list for the portfolio and for the objects.
Future<List<Map<String, Object?>>> bankSignals(AppDatabase db, String bankId, {String? projectId}) async {
  final rules = await bankRulesNow(db, bankId);
  final today = DateTime.now().toUtc().add(const Duration(hours: 5));
  final midnight = DateTime.utc(today.year, today.month, today.day);
  final filter = projectId == null ? '' : 'AND f.project_id = @project::uuid';
  final params = {'bank': bankId, if (projectId != null) 'project': projectId};

  final facilities = await bankRows(
    db,
    '''
      SELECT f.project_id::text AS project_id, p.name AS name, f.funding_paused AS paused,
             f.utilize_until AS until
      FROM project_facilities f JOIN projects p ON p.id = f.project_id
      WHERE f.bank_id = @bank::uuid AND p.active $filter
    ''',
    params,
  );
  final signals = <Map<String, Object?>>[];
  void add(Map<String, Object?> facility, String level, String code, String title, String basis, String action,
      {String detail = '', Map<String, Object?> params = const {}}) {
    signals.add({
      'params': params,
      'projectId': facility['project_id'],
      'projectName': facility['name'],
      'level': level,
      'code': code,
      'title': title,
      'detail': detail,
      'basis': basis,
      'action': action,
    });
  }

  // Issued above what the inspections confirmed.
  final over = await bankRows(
    db,
    '''
      SELECT x.project_id::text AS project_id, sum(x.issue)::text AS issue, sum(x.confirmed)::text AS confirmed
      FROM (
        SELECT DISTINCT ON (d.tranche_id) t.project_id, d.issue_amount AS issue,
               COALESCE((SELECT sum(l.confirmed) FROM bank_tranche_lines l WHERE l.tranche_id = t.id), 0) AS confirmed
        FROM bank_decisions d JOIN bank_tranches t ON t.id = d.tranche_id
        WHERE t.bank_id = @bank::uuid AND d.kind = 'partial'
        ORDER BY d.tranche_id, d.created_at DESC
      ) x
      GROUP BY x.project_id
    ''',
    {'bank': bankId},
  );
  final overBy = {for (final row in over) row['project_id']! as String: row};
  final threshold = (rules['issuedAbovePercent'] as num?)?.toInt() ?? 1;
  final warnDays = (rules['forecastWarningDays'] as num?)?.toInt() ?? 30;
  final redDays = ((rules['forecastRedMonths'] as num?)?.toInt() ?? 6) * 30 - 30;
  final salesDue = bankLastSalesDue(midnight, _salesDays(rules));

  for (final facility in facilities) {
    final id = facility['project_id']! as String;
    if (facility['paused'] == true) {
      add(facility, 'block', 'paused', 'Финансирование приостановлено', 'ГС п. 4.10', 'open');
    }
    final row = overBy[id];
    if (row != null) {
      final issue = bankCents(row['issue']! as String);
      final confirmed = bankCents(row['confirmed']! as String);
      final extra = issue - confirmed;
      if (extra > BigInt.zero && issue > BigInt.zero && extra * BigInt.from(100) > issue * BigInt.from(threshold)) {
        add(
          facility,
          extra * BigInt.from(20) > issue ? 'block' : 'warning',
          'over_confirmed',
          'Выдано на ${bankMillions(extra)} млн больше, чем подтверждено осмотрами',
          'ГС п. 3.6',
          'stop_lines',
          params: {'amount': bankMillions(extra)},
        );
      }
    }
    final until = facility['until'] as DateTime?;
    if (until != null) {
      final left = until.difference(midnight).inDays;
      if (left < 0) {
        add(facility, 'block', 'facility_ended', 'Срок освоения кредита закончился ${_ruDate(bankDay(until)!)}', 'ГС п. 3.7', 'open',
            params: {'date': bankDay(until)});
      } else if (left <= 30) {
        add(facility, 'warning', 'facility_ending', 'Срок освоения кредита заканчивается ${_ruDate(bankDay(until)!)}', 'ГС п. 3.7', 'open',
            params: {'date': bankDay(until)});
      }
    }
  }

  // The forecast of the expert against the term of the credit.
  final forecasts = await bankRows(
    db,
    '''
      SELECT DISTINCT ON (i.project_id) i.project_id::text AS project_id, i.expected_finish AS finish
      FROM bank_inspections i
      WHERE i.bank_id = @bank::uuid AND i.status = 'done' AND i.expected_finish IS NOT NULL
      ORDER BY i.project_id, i.completed_on DESC NULLS LAST, i.created_at DESC
    ''',
    {'bank': bankId},
  );
  final finishBy = {for (final row in forecasts) row['project_id']! as String: row['finish'] as DateTime};
  for (final facility in facilities) {
    final finish = finishBy[facility['project_id']];
    final until = facility['until'] as DateTime?;
    if (finish == null || until == null) continue;
    final late = finish.difference(until).inDays;
    if (late > warnDays) {
      add(
        facility,
        late >= redDays ? 'block' : 'warning',
        'forecast_late',
        'Прогноз сдачи позже срока на $late дн.',
        'УП-11',
        'request_schedule',
        detail: 'Срок ${bankDay(until)}, прогноз эксперта ${bankDay(finish)}.',
        params: {'days': late, 'until': bankDay(until), 'finish': bankDay(finish)},
      );
    }
  }

  // The sales report of the developer for the last date that has passed.
  final filings = await bankRows(
    db,
    "SELECT project_id::text AS project_id FROM bank_filings WHERE bank_id = @bank::uuid AND kind = 'sales' AND period = @period",
    {'bank': bankId, 'period': salesDue},
  );
  final filed = {for (final row in filings) row['project_id']! as String};
  for (final facility in facilities) {
    if (filed.contains(facility['project_id'])) continue;
    add(facility, 'reminder', 'sales_report', 'Не сдан отчёт о продажах за ${_ruDate(salesDue)}', 'ГС п. 5.9', 'remind', params: {'date': salesDue});
  }

  // A visit that was planned and has not been done.
  final late = await bankRows(
    db,
    '''
      SELECT project_id::text AS project_id, min(scheduled_on) AS day
      FROM bank_inspections
      WHERE bank_id = @bank::uuid AND status = 'planned' AND scheduled_on < $bankToday
      GROUP BY project_id
    ''',
    {'bank': bankId},
  );
  final lateBy = {for (final row in late) row['project_id']! as String: row['day'] as DateTime};
  for (final facility in facilities) {
    final day = lateBy[facility['project_id']];
    if (day == null) continue;
    add(facility, 'warning', 'inspection_overdue', 'Просрочен осмотр от ${_ruDate(bankDay(day)!)}', 'ГС п. 3.6', 'schedule_inspection',
        params: {'date': bankDay(day)});
  }

  const order = {'block': 0, 'warning': 1, 'reminder': 2};
  signals.sort((a, b) => order[a['level']]!.compareTo(order[b['level']]!));
  return signals;
}

Future<Set<String>> _holidays(AppDatabase db) async {
  final rows = await bankRows(db, 'SELECT day FROM bank_holidays');
  return {for (final row in rows) bankDay(row['day'])!};
}

/// Working days the tranches of this bank spent at each stage since [since].
Future<Map<String, Object?>> bankStageTimes(AppDatabase db, String bankId, DateTime since) async {
  final holidays = await _holidays(db);
  final rows = await bankRows(
    db,
    '''
      SELECT c.tranche_id::text AS tranche, c.stage AS stage, c.started_at AS started, c.ended_at AS ended
      FROM bank_tranche_clock c JOIN bank_tranches t ON t.id = c.tranche_id
      WHERE t.bank_id = @bank::uuid AND NOT c.paused AND c.started_at >= @since
    ''',
    {'bank': bankId, 'since': since},
  );
  final minutes = <String, int>{};
  final tranches = <String, Set<String>>{};
  final now = DateTime.now().toUtc();
  for (final row in rows) {
    final stage = row['stage']! as String;
    final end = (row['ended'] as DateTime?) ?? now;
    minutes[stage] = (minutes[stage] ?? 0) +
        bankWorkingMinutes(row['started']! as DateTime, end, holidays);
    (tranches[stage] ??= {}).add(row['tranche']! as String);
  }
  const stages = ['docs', 'inspection', 'specialist', 'approval', 'payout'];
  double days(String stage) {
    final count = tranches[stage]?.length ?? 0;
    if (count == 0) return 0;
    return (minutes[stage] ?? 0) / count / bankWorkdayMinutes;
  }

  final perStage = {for (final stage in stages) stage: double.parse(days(stage).toStringAsFixed(1))};
  final total = perStage.values.fold<double>(0, (sum, value) => sum + value);
  return {
    'stages': [
      for (final stage in stages) {'code': stage, 'days': perStage[stage]},
    ],
    'average': tranches.isEmpty ? null : double.parse(total.toStringAsFixed(1)),
  };
}

Future<Response> _portfolio(Request request, AppDatabase db) async {
  final opened = await bankContext(request, db);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final bank = ctx.bankId;
  final today = DateTime.now().toUtc().add(const Duration(hours: 5));
  final midnight = DateTime.utc(today.year, today.month, today.day);
  final quarter = DateTime.utc(today.year, ((today.month - 1) ~/ 3) * 3 + 1, 1);

  final totals = (await bankRows(
    db,
    '''
      SELECT count(*) AS objects,
             COALESCE(to_char(sum(f.credit_limit), $bankMoney), '0.00') AS credit_limit,
             COALESCE(to_char(sum(f.issued_amount), $bankMoney), '0.00') AS issued
      FROM project_facilities f JOIN projects p ON p.id = f.project_id
      WHERE f.bank_id = @bank::uuid AND p.active
    ''',
    {'bank': bank},
  ))
      .first;
  final inWork = (await bankRows(
    db,
    'SELECT count(*) AS n FROM bank_tranches WHERE bank_id = @bank::uuid AND outcome IS NULL',
    {'bank': bank},
  ))
      .first['n'];
  final signals = await bankSignals(db, bank);
  final attention = signals.where((s) => s['level'] != 'reminder' || s['code'] == 'sales_report').toList();
  final needing = {for (final s in attention) s['projectId']}.length;
  final times = await bankStageTimes(db, bank, quarter);
  final rules = await bankRulesNow(db, bank);

  final deadlines = <Map<String, Object?>>[];
  final planned = await bankRows(
    db,
    '''
      SELECT i.scheduled_on AS day, p.name AS name, i.expert_label AS expert
      FROM bank_inspections i JOIN projects p ON p.id = i.project_id
      WHERE i.bank_id = @bank::uuid AND i.status = 'planned' AND i.scheduled_on >= $bankToday
      ORDER BY i.scheduled_on LIMIT 5
    ''',
    {'bank': bank},
  );
  for (final row in planned) {
    deadlines.add({
      'day': bankDay(row['day']),
      'kind': 'inspection',
      'title': 'Осмотр ${row['name']}',
      'note': row['expert'],
    });
  }
  for (final due in _nextSalesDues(midnight, _salesDays(rules))) {
    deadlines.add({'day': due, 'kind': 'sales_report', 'title': 'Отчёты о продажах по ${totals['objects']} объектам', 'note': 'ГС п. 5.9'});
  }
  final quarterEnd = DateTime.utc(today.year, ((today.month - 1) ~/ 3) * 3 + 4, 1);
  final quarterlyDue = DateTime.utc(quarterEnd.year, quarterEnd.month + 1, 0);
  if (!quarterlyDue.isBefore(midnight)) {
    deadlines.add({'day': _dayText(quarterlyDue), 'kind': 'quarterly', 'title': 'Квартальная отчётность застройщиков', 'note': 'ГС п. 6.4.11'});
  }
  final ending = await bankRows(
    db,
    '''
      SELECT f.utilize_until AS day, p.name AS name
      FROM project_facilities f JOIN projects p ON p.id = f.project_id
      WHERE f.bank_id = @bank::uuid AND f.utilize_until >= $bankToday AND f.utilize_until <= $bankToday + 90
      ORDER BY f.utilize_until LIMIT 5
    ''',
    {'bank': bank},
  );
  for (final row in ending) {
    deadlines.add({'day': bankDay(row['day']), 'kind': 'facility', 'title': 'Конец срока освоения кредита, ${row['name']}', 'note': 'ГС п. 3.7'});
  }
  deadlines.sort((a, b) => (a['day']! as String).compareTo(b['day']! as String));

  return bankOk({
    'bankName': (await bankRows(db, 'SELECT name FROM companies WHERE id = @bank::uuid', {'bank': bank})).first['name'],
    'issued': totals['issued'],
    'limit': totals['credit_limit'],
    'kpi': {
      'objects': totals['objects'],
      'attention': needing,
      'tranchesInWork': inWork,
      'averageDays': times['average'],
    },
    'signals': attention.take(12).toList(),
    'moreObjects': (bankInt(totals['objects']) - needing).clamp(0, 1 << 30),
    'stageDays': times['stages'],
    'deadlines': deadlines.take(8).toList(),
  });
}

Future<Response> _setLimit(Request request, AppDatabase db, String id) async {
  final opened = await bankContext(request, db, mutating: true, roles: const {'admin'});
  if (opened is Response) return opened;
  if (!bankIsUuid(id)) return jsonError(404, 'not_found', 'Объект не найден.');
  final ctx = opened as BankCtx;
  final body = await bankBody(request);
  if (body == null) return jsonError(400, 'validation', 'Не удалось прочитать запрос');
  final amount = normalizeMoney('${body['creditLimit'] ?? ''}');
  if (amount == null) return jsonError(400, 'validation', 'Лимит должен быть больше нуля.');
  final untilRaw = '${body['utilizeUntil'] ?? ''}'.trim();
  final until = untilRaw.isEmpty ? null : bankDateInput(untilRaw);
  if (untilRaw.isNotEmpty && until == null) {
    return jsonError(400, 'validation', 'Срок освоения укажите как ГГГГ-ММ-ДД.');
  }
  final untilParts = until?.split('-') ?? const <String>[];
  final found = await db.owner.execute(
    Sql.named('SELECT 1 FROM project_facilities WHERE project_id = @project::uuid AND bank_id = @bank::uuid'),
    parameters: {'project': id, 'bank': ctx.bankId},
  );
  if (found.isEmpty) return jsonError(404, 'not_found', 'Объект не найден.');
  final updated = await db.owner.execute(
    Sql.named('''
      UPDATE project_facilities
      SET credit_limit = @limit::numeric,
          utilize_until = CASE
            WHEN @hasUntil THEN make_date(@year, @month, @day)
            ELSE utilize_until
          END
      WHERE project_id = @project::uuid AND bank_id = @bank::uuid
        AND @limit::numeric >= issued_amount
      RETURNING id::text
    '''),
    parameters: {
      'limit': amount,
      'hasUntil': until != null,
      'year': until == null ? 2000 : int.parse(untilParts[0]),
      'month': until == null ? 1 : int.parse(untilParts[1]),
      'day': until == null ? 1 : int.parse(untilParts[2]),
      'project': id,
      'bank': ctx.bankId,
    },
  );
  if (updated.isEmpty) {
    return jsonError(409, 'conflict', 'Лимит не может быть меньше уже выданной суммы.');
  }
  return bankOk({'ok': true, 'creditLimit': amount});
}

Future<Response> _objects(Request request, AppDatabase db) async {
  final opened = await bankContext(request, db);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final rows = await bankRows(
    db,
    '''
      SELECT f.project_id::text AS id, p.name AS name, p.address AS address, f.developer_name AS developer,
             f.branch AS branch, f.funding_paused AS paused, f.utilize_until AS until,
             to_char(f.credit_limit, $bankMoney) AS credit_limit,
             to_char(f.issued_amount, $bankMoney) AS issued,
             (SELECT count(*) FROM bank_tranches t WHERE t.project_id = f.project_id
                AND t.bank_id = f.bank_id AND t.outcome IS NULL) AS in_work
      FROM project_facilities f JOIN projects p ON p.id = f.project_id
      WHERE f.bank_id = @bank::uuid AND p.active
      ORDER BY p.name
    ''',
    {'bank': ctx.bankId},
  );
  final signals = await bankSignals(db, ctx.bankId);
  const rank = {'block': 0, 'warning': 1, 'reminder': 2};
  String? worst(String id) {
    String? level;
    for (final signal in signals) {
      if (signal['projectId'] != id) continue;
      final current = signal['level'] as String;
      if (level == null || rank[current]! < rank[level]!) level = current;
    }
    return level;
  }

  return bankOk({
    'items': [
      for (final row in rows)
        {
          ...row,
          'until': bankDay(row['until']),
          'level': worst(row['id']! as String),
          'signalCount': signals.where((s) => s['projectId'] == row['id'] && s['level'] != 'reminder').length,
        },
    ],
  });
}

Future<Response> _object(Request request, AppDatabase db, String id) async {
  final opened = await bankContext(request, db);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  if (!bankIsUuid(id)) return jsonError(404, 'not_found', 'Не найдено');
  final head = await bankRows(
    db,
    '''
      SELECT f.project_id::text AS id, p.name AS name, p.address AS address, p.description AS description,
             f.developer_name AS developer, f.branch AS branch, f.funding_paused AS paused,
             f.utilize_until AS until, to_char(f.credit_limit, $bankMoney) AS credit_limit,
             to_char(f.issued_amount, $bankMoney) AS issued,
             to_char(f.credit_limit - f.issued_amount, $bankMoney) AS left,
             p.company_id::text AS developer_id, c.contact AS contact
      FROM project_facilities f JOIN projects p ON p.id = f.project_id
      JOIN companies c ON c.id = p.company_id
      WHERE f.bank_id = @bank::uuid AND f.project_id = @id::uuid
    ''',
    {'bank': ctx.bankId, 'id': id},
  );
  if (head.isEmpty) return jsonError(404, 'not_found', 'Не найдено');

  final budget = await bankRows(
    db,
    '''
      SELECT bi.title AS title,
             CASE WHEN bi.plan_set THEN to_char(bi.planned_amount, $bankMoney) END AS plan,
             to_char(COALESCE((
               SELECT sum(COALESCE(dl.approved_amount, dl.requested - dl.retainage_withheld + dl.retainage_released))
               FROM draw_lines dl JOIN funding_requests f ON f.id = dl.request_id
               WHERE dl.budget_item_id = bi.id AND f.status IN ('approved', 'paid')), 0), $bankMoney) AS issued,
             (SELECT il.percent::text FROM inspection_lines il JOIN inspections i ON i.id = il.inspection_id
              WHERE il.budget_item_id = bi.id AND i.status = 'reported'
              ORDER BY i.created_at DESC LIMIT 1) AS percent,
             CASE WHEN bi.plan_set THEN to_char(bi.planned_amount * COALESCE((
               SELECT il.percent FROM inspection_lines il JOIN inspections i ON i.id = il.inspection_id
               WHERE il.budget_item_id = bi.id AND i.status = 'reported'
               ORDER BY i.created_at DESC LIMIT 1), 0) / 100, $bankMoney) END AS confirmed
      FROM budget_items bi
      WHERE bi.project_id = @id::uuid AND bi.budget_side = 'use'
      ORDER BY bi.title
    ''',
    {'id': id},
  );
  final tranches = await bankRows(
    db,
    '''
      SELECT t.id::text AS id, t.tranche_no AS no, t.stage AS stage, t.stage_label AS stage_label,
             to_char(t.requested_amount, $bankMoney) AS requested, to_char(t.issue_amount, $bankMoney) AS issue,
             t.signal AS signal, t.submitted_at AS submitted
      FROM bank_tranches t WHERE t.project_id = @id::uuid AND t.bank_id = @bank::uuid
      ORDER BY t.tranche_no DESC
    ''',
    {'id': id, 'bank': ctx.bankId},
  );
  final inspections = await bankRows(
    db,
    '''
      SELECT i.id::text AS id, i.kind AS kind, i.status AS status, i.scheduled_on AS scheduled,
             i.completed_on AS completed, i.expert_label AS expert, i.risk AS risk,
             i.recommendation AS recommendation, i.note AS note, i.expected_finish AS finish
      FROM bank_inspections i WHERE i.project_id = @id::uuid AND i.bank_id = @bank::uuid
      ORDER BY i.scheduled_on DESC LIMIT 20
    ''',
    {'id': id, 'bank': ctx.bankId},
  );
  final documents = await bankRows(
    db,
    'SELECT title, doc_number AS number, issued_on AS issued, note FROM project_documents WHERE project_id = @id::uuid ORDER BY issued_on DESC NULLS LAST, title',
    {'id': id},
  );
  final filings = await bankRows(
    db,
    'SELECT kind, period, filed_on AS filed FROM bank_filings WHERE project_id = @id::uuid AND bank_id = @bank::uuid ORDER BY period DESC LIMIT 12',
    {'id': id, 'bank': ctx.bankId},
  );
  final signals = await bankSignals(db, ctx.bankId, projectId: id);

  String dateOr(Object? value) => bankDay(value) ?? '';
  return bankOk({
    'object': {...head.first, 'until': bankDay(head.first['until'])},
    'signals': signals,
    'budget': budget,
    'tranches': tranches,
    'inspections': [
      for (final row in inspections)
        {
          ...row,
          'status': _inspectionStatus(row['status']! as String, row['scheduled'] as DateTime),
          'scheduled': dateOr(row['scheduled']),
          'completed': bankDay(row['completed']),
          'finish': bankDay(row['finish']),
        },
    ],
    'documents': [
      for (final row in documents) {...row, 'issued': bankDay(row['issued'])},
    ],
    'filings': [
      for (final row in filings) {...row, 'filed': bankDay(row['filed'])},
    ],
  });
}

String _inspectionStatus(String status, DateTime scheduled) {
  if (status != 'planned') return status;
  final now = DateTime.now().toUtc().add(const Duration(hours: 5));
  final today = DateTime.utc(now.year, now.month, now.day);
  return scheduled.isBefore(today) ? 'overdue' : 'planned';
}

Future<Response> _remind(Request request, AppDatabase db, String id) async {
  final opened = await bankContext(request, db, mutating: true, roles: _writers);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  if (!bankIsUuid(id)) return jsonError(404, 'not_found', 'Не найдено');
  final exists = await bankRows(
    db,
    'SELECT 1 FROM project_facilities WHERE project_id = @id::uuid AND bank_id = @bank::uuid',
    {'id': id, 'bank': ctx.bankId},
  );
  if (exists.isEmpty) return jsonError(404, 'not_found', 'Не найдено');
  final body = await bankBody(request);
  final kind = body?['kind'];
  if (kind is! String || !const {'sales_report', 'schedule', 'documents'}.contains(kind)) {
    return jsonError(400, 'validation', 'Выберите, о чём напомнить');
  }
  await bankEvent(db, ctx, 'reminder', projectId: id, detail: {'kind': kind});
  final info = await bankRows(
    db,
    '''
      SELECT p.name AS project, c.name AS company, b.name AS bank
      FROM projects p JOIN companies c ON c.id = p.company_id
      JOIN companies b ON b.id = @bank::uuid
      WHERE p.id = @id::uuid
    ''',
    {'id': id, 'bank': ctx.bankId},
  );
  final people = await bankRows(
    db,
    '''
      SELECT u.login AS login FROM users u JOIN projects p ON p.company_id = u.company_id
      WHERE p.id = @id::uuid AND u.active AND u.login LIKE '%@%' ORDER BY u.created_at LIMIT 3
    ''',
    {'id': id},
  );
  const asks = {
    'sales_report': 'Просим передать отчёт о продажах по объекту.',
    'schedule': 'Просим обновить график работ по объекту.',
    'documents': 'Просим передать недостающие документы по объекту.',
  };
  var status = 'no_recipient';
  if (info.isNotEmpty) {
    for (final person in people) {
      status = await sendMail(
        db,
        to: person['login']! as String,
        subject: '${info.first['bank']}: напоминание по объекту «${info.first['project']}»',
        body: 'Здравствуйте!\n\n${asks[kind]}\n\nОбъект: ${info.first['project']}\nОтправитель: ${ctx.actor.name}, ${info.first['bank']}\n\niBuild',
        kind: 'reminder',
        bankId: ctx.bankId,
      );
    }
  }
  // The same reminder goes into the in-app mailbox of the developer's people.
  if (info.isNotEmpty) {
    final inside = await bankRows(
      db,
      '''
        SELECT DISTINCT u.id::text AS id FROM users u JOIN projects p ON p.company_id = u.company_id
        WHERE p.id = @id::uuid AND u.active
      ''',
      {'id': id},
    );
    if (inside.isNotEmpty) {
      await deliverInternal(
        db,
        senderId: ctx.actor.userId,
        recipientIds: [for (final row in inside) row['id']! as String],
        subject: '${info.first['bank']}: напоминание по объекту «${info.first['project']}»',
        body: '${asks[kind]}\n\nОбъект: ${info.first['project']}\nОтправитель: ${ctx.actor.name}, ${info.first['bank']}',
      );
    }
  }
  return bankOk({'ok': true, 'mail': status});
}

Future<Response> _inspections(Request request, AppDatabase db) async {
  final opened = await bankContext(request, db);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final rows = await bankRows(
    db,
    '''
      SELECT i.id::text AS id, i.project_id::text AS project_id, p.name AS project_name, i.kind AS kind,
             i.status AS status, i.scheduled_on AS scheduled, i.completed_on AS completed,
             i.expert_label AS expert, i.expert_user_id::text AS expert_id, i.risk AS risk,
             i.recommendation AS recommendation, i.note AS note, i.expected_finish AS finish,
             t.tranche_no AS tranche_no
      FROM bank_inspections i JOIN projects p ON p.id = i.project_id
      LEFT JOIN bank_tranches t ON t.id = i.tranche_id
      WHERE i.bank_id = @bank::uuid
      ORDER BY (i.status = 'planned') DESC, i.scheduled_on DESC
      LIMIT 300
    ''',
    {'bank': ctx.bankId},
  );
  final items = [
    for (final row in rows)
      {
        ...row,
        'status': _inspectionStatus(row['status']! as String, row['scheduled']! as DateTime),
        'scheduled': bankDay(row['scheduled']),
        'completed': bankDay(row['completed']),
        'finish': bankDay(row['finish']),
      },
  ];
  final experts = await bankRows(
    db,
    '''
      SELECT s.user_id::text AS id, u.name AS name
      FROM bank_staff s JOIN users u ON u.id = s.user_id
      WHERE s.bank_id = @bank::uuid AND s.role = 'expert' AND s.active ORDER BY u.name
    ''',
    {'bank': ctx.bankId},
  );
  final objects = await bankRows(
    db,
    '''
      SELECT f.project_id::text AS id, p.name AS name
      FROM project_facilities f JOIN projects p ON p.id = f.project_id
      WHERE f.bank_id = @bank::uuid AND p.active ORDER BY p.name
    ''',
    {'bank': ctx.bankId},
  );
  int count(String status) => items.where((item) => item['status'] == status).length;
  return bankOk({
    'items': items,
    'counts': {'planned': count('planned'), 'done': count('done'), 'overdue': count('overdue')},
    'experts': experts,
    'objects': objects,
    'canPlan': _writers.contains(ctx.actor.role),
    'canComplete': ctx.actor.role == 'expert' || ctx.actor.role == 'admin',
  });
}

Future<Response> _planInspection(Request request, AppDatabase db) async {
  final opened = await bankContext(request, db, mutating: true, roles: _writers);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final body = await bankBody(request);
  if (body == null) return jsonError(400, 'validation', 'Не удалось прочитать запрос');
  final project = body['projectId'];
  final day = bankDateInput(body['scheduledOn']);
  final kind = body['kind'] == 'regular' ? 'regular' : 'control';
  if (project is! String || !bankIsUuid(project) || day == null) {
    return jsonError(400, 'validation', 'Выберите объект и дату осмотра');
  }
  final exists = await bankRows(
    db,
    'SELECT 1 FROM project_facilities WHERE project_id = @id::uuid AND bank_id = @bank::uuid',
    {'id': project, 'bank': ctx.bankId},
  );
  if (exists.isEmpty) return jsonError(404, 'not_found', 'Объект не найден');

  var expertId = body['expertUserId'];
  Map<String, Object?>? expert;
  final experts = await bankRows(
    db,
    '''
      SELECT s.user_id::text AS id, u.name AS name,
             (SELECT count(*) FROM bank_inspections i WHERE i.expert_user_id = s.user_id AND i.status = 'planned') AS load
      FROM bank_staff s JOIN users u ON u.id = s.user_id
      WHERE s.bank_id = @bank::uuid AND s.role = 'expert' AND s.active
      ORDER BY load, u.name
    ''',
    {'bank': ctx.bankId},
  );
  if (expertId is String && expertId.isNotEmpty) {
    for (final row in experts) {
      if (row['id'] == expertId) expert = row;
    }
    if (expert == null) return jsonError(400, 'validation', 'Выберите эксперта банка');
  } else if (experts.isNotEmpty) {
    expert = experts.first;
    expertId = expert['id'];
  }
  final rows = await bankRows(
    db,
    '''
      INSERT INTO bank_inspections (project_id, bank_id, kind, scheduled_on, expert_user_id, expert_label, created_by)
      VALUES (@project::uuid, @bank::uuid, @kind, @day::date, @expert::uuid, @label, @user::uuid)
      RETURNING id::text AS id
    ''',
    {
      'project': project,
      'bank': ctx.bankId,
      'kind': kind,
      'day': day,
      'expert': expert == null ? null : expertId,
      'label': expert == null ? '' : '${expert['name']}, эксперт',
      'user': ctx.actor.userId,
    },
  );
  await bankEvent(db, ctx, 'inspection_planned', projectId: project, detail: {'day': day, 'kind': kind, 'expert': expert?['name']});
  return jsonResponse(201, {'id': rows.first['id']});
}

Future<Response> _completeInspection(Request request, AppDatabase db, String id) async {
  final opened = await bankContext(request, db, mutating: true, roles: const {'expert', 'admin'});
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  if (!bankIsUuid(id)) return jsonError(404, 'not_found', 'Не найдено');
  final body = await bankBody(request);
  if (body == null) return jsonError(400, 'validation', 'Не удалось прочитать запрос');
  final risk = body['risk'];
  final recommendation = body['recommendation'];
  final note = (body['note'] as String? ?? '').trim();
  final finishRaw = body['expectedFinish'];
  final finish = finishRaw == null || finishRaw == '' ? null : bankDateInput(finishRaw);
  if (risk is! String || !const {'ok', 'watch', 'high'}.contains(risk) ||
      recommendation is! String || !const {'issue', 'withhold'}.contains(recommendation)) {
    return jsonError(400, 'validation', 'Укажите риск и рекомендацию');
  }
  if (finishRaw != null && finishRaw != '' && finish == null) {
    return jsonError(400, 'validation', 'Дата завершения указана неверно');
  }
  if (note.length > 2000) return jsonError(400, 'validation', 'Комментарий слишком длинный');
  final rows = await bankRows(
    db,
    '''
      UPDATE bank_inspections
      SET status = 'done', completed_on = $bankToday, risk = @risk, recommendation = @recommendation,
          note = @note, expected_finish = @finish::date
      WHERE id = @id::uuid AND bank_id = @bank::uuid AND status = 'planned'
        AND (@role = 'admin' OR expert_user_id = @user::uuid)
      RETURNING project_id::text AS project_id
    ''',
    {
      'id': id,
      'bank': ctx.bankId,
      'risk': risk,
      'recommendation': recommendation,
      'note': note,
      'finish': finish,
      'role': ctx.actor.role,
      'user': ctx.actor.userId,
    },
  );
  if (rows.isEmpty) return jsonError(409, 'not_open', 'Этот осмотр уже закрыт или назначен другому эксперту');
  await bankEvent(db, ctx, 'inspection_done', projectId: rows.first['project_id']! as String,
      detail: {'risk': risk, 'recommendation': recommendation, 'finish': finish});
  return bankOk({'ok': true});
}

String _periodKey(String due) => due;

Future<List<Map<String, Object?>>> bankDeveloperRows(AppDatabase db, String bankId, {String? developerId}) {
  return bankRows(
    db,
    '''
      SELECT p.company_id::text AS id, min(f.developer_name) AS name, min(c.contact) AS contact,
             count(*) AS objects, to_char(sum(f.credit_limit), $bankMoney) AS credit_limit,
             to_char(sum(f.issued_amount), $bankMoney) AS issued,
             array_agg(f.project_id::text ORDER BY p.name) AS project_ids,
             array_agg(p.name ORDER BY p.name) AS project_names
      FROM project_facilities f JOIN projects p ON p.id = f.project_id
      JOIN companies c ON c.id = p.company_id
      WHERE f.bank_id = @bank::uuid AND p.active ${developerId == null ? '' : 'AND p.company_id = @dev::uuid'}
      GROUP BY p.company_id
      ORDER BY min(f.developer_name)
    ''',
    {'bank': bankId, if (developerId != null) 'dev': developerId},
  );
}

Future<Map<String, Object?>> bankDeveloperFacts(
  AppDatabase db,
  String bankId,
  Map<String, Object?> dev,
  Map<String, Object?> rules,
) async {
  final ids = (dev['project_ids'] as List).cast<String>();
  final today = DateTime.now().toUtc().add(const Duration(hours: 5));
  final midnight = DateTime.utc(today.year, today.month, today.day);
  final salesDue = bankLastSalesDue(midnight, _salesDays(rules));
  final quarterStart = DateTime.utc(today.year, ((today.month - 1) ~/ 3) * 3 + 1, 1);
  final lastQuarter = DateTime.utc(quarterStart.year, quarterStart.month - 3, 1);
  final lastQuarterKey = '${lastQuarter.year}-Q${(lastQuarter.month - 1) ~/ 3 + 1}';

  final sales = await bankRows(
    db,
    "SELECT count(*) AS n FROM bank_filings WHERE bank_id = @bank::uuid AND kind = 'sales' AND period = @period AND project_id = ANY(@ids::uuid[])",
    {'bank': bankId, 'period': salesDue, 'ids': ids},
  );
  final quarterly = await bankRows(
    db,
    "SELECT count(*) AS n FROM bank_filings WHERE bank_id = @bank::uuid AND kind = 'quarterly' AND period = @period AND project_id = ANY(@ids::uuid[])",
    {'bank': bankId, 'period': lastQuarterKey, 'ids': ids},
  );
  final supervision = await bankRows(
    db,
    '''
      SELECT p.id::text AS id, (
        SELECT count(*) FROM inspections i
        WHERE i.project_id = p.id AND i.status = 'reported' AND i.created_at >= now() - interval '30 days'
      ) AS visits
      FROM projects p WHERE p.id = ANY(@ids::uuid[])
    ''',
    {'ids': ids},
  );
  final regular = supervision.where((row) => bankInt(row['visits']) >= 2).length;
  final tranches = await bankRows(
    db,
    '''
      SELECT count(*) AS total,
             count(*) FILTER (WHERE EXISTS (
               SELECT 1 FROM bank_decisions d WHERE d.tranche_id = t.id
                 AND (d.kind = 'return_all' OR (d.kind = 'partial' AND d.returned_amount > 0)))) AS returned
      FROM bank_tranches t WHERE t.bank_id = @bank::uuid AND t.project_id = ANY(@ids::uuid[])
    ''',
    {'bank': bankId, 'ids': ids},
  );
  final response = await bankRows(
    db,
    '''
      SELECT avg(extract(epoch FROM (c.ended_at - c.started_at)) / 3600.0)::numeric(10,1)::text AS hours
      FROM bank_tranche_clock c JOIN bank_tranches t ON t.id = c.tranche_id
      WHERE c.paused AND c.ended_at IS NOT NULL AND t.bank_id = @bank::uuid AND t.project_id = ANY(@ids::uuid[])
    ''',
    {'bank': bankId, 'ids': ids},
  );
  final reasons = await bankRows(
    db,
    '''
      SELECT reason, count(*) AS n FROM (
        SELECT line ->> 'reason' AS reason
        FROM bank_decisions d JOIN bank_tranches t ON t.id = d.tranche_id,
             jsonb_array_elements(d.return_lines) AS line
        WHERE t.bank_id = @bank::uuid AND t.project_id = ANY(@ids::uuid[])
      ) x WHERE reason IS NOT NULL GROUP BY reason ORDER BY n DESC LIMIT 5
    ''',
    {'bank': bankId, 'ids': ids},
  );
  final total = bankInt(tranches.first['total']);
  return {
    'salesReport': {'period': salesDue, 'filed': bankInt(sales.first['n']), 'of': ids.length},
    'quarterly': {'period': lastQuarterKey, 'filed': bankInt(quarterly.first['n']), 'of': ids.length},
    'supervision': {'regular': regular, 'of': ids.length},
    'returns': {'total': total, 'returned': bankInt(tranches.first['returned'])},
    'responseHours': response.first['hours'],
    'reasons': reasons,
  };
}

Future<Response> _developers(Request request, AppDatabase db) async {
  final opened = await bankContext(request, db);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final rules = await bankRulesNow(db, ctx.bankId);
  final rows = await bankDeveloperRows(db, ctx.bankId);
  final items = <Map<String, Object?>>[];
  for (final dev in rows) {
    final facts = await bankDeveloperFacts(db, ctx.bankId, dev, rules);
    items.add({
      'id': dev['id'],
      'name': dev['name'],
      'contact': dev['contact'],
      'objects': dev['objects'],
      'limit': dev['credit_limit'],
      'issued': dev['issued'],
      ...facts,
    });
  }
  return bankOk({'items': items});
}

Future<Response> _developer(Request request, AppDatabase db, String id) async {
  final opened = await bankContext(request, db);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  if (!bankIsUuid(id)) return jsonError(404, 'not_found', 'Не найдено');
  final rows = await bankDeveloperRows(db, ctx.bankId, developerId: id);
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Не найдено');
  final rules = await bankRulesNow(db, ctx.bankId);
  final dev = rows.first;
  final facts = await bankDeveloperFacts(db, ctx.bankId, dev, rules);
  final names = (dev['project_names'] as List).cast<String>();
  final ids = (dev['project_ids'] as List).cast<String>();
  final returns = await bankRows(
    db,
    '''
      SELECT p.name AS project, t.tranche_no AS no, d.kind AS kind, d.created_at AS at,
             to_char(d.returned_amount, $bankMoney) AS returned, d.note AS note
      FROM bank_decisions d JOIN bank_tranches t ON t.id = d.tranche_id JOIN projects p ON p.id = t.project_id
      WHERE t.bank_id = @bank::uuid AND t.project_id = ANY(@ids::uuid[])
        AND (d.kind = 'return_all' OR (d.kind = 'partial' AND d.returned_amount > 0))
      ORDER BY d.created_at DESC LIMIT 10
    ''',
    {'bank': ctx.bankId, 'ids': ids},
  );
  final salesDue = (facts['salesReport']! as Map)['period']! as String;
  return bankOk({
    'id': dev['id'],
    'name': dev['name'],
    'contact': dev['contact'],
    'limit': dev['credit_limit'],
    'issued': dev['issued'],
    'objects': [
      for (var i = 0; i < ids.length; i++) {'id': ids[i], 'name': names[i]},
    ],
    ...facts,
    'recentReturns': returns,
    'salesPeriod': _periodKey(salesDue),
    'canFile': _writers.contains(ctx.actor.role),
  });
}

Future<Response> _file(Request request, AppDatabase db, String id) async {
  final opened = await bankContext(request, db, mutating: true, roles: _writers);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  if (!bankIsUuid(id)) return jsonError(404, 'not_found', 'Не найдено');
  final body = await bankBody(request);
  if (body == null) return jsonError(400, 'validation', 'Не удалось прочитать запрос');
  final project = body['projectId'];
  final kind = body['kind'];
  final period = body['period'];
  if (project is! String || !bankIsUuid(project) || kind is! String || !const {'sales', 'quarterly'}.contains(kind) ||
      period is! String || !RegExp(r'^(\d{4}-\d{2}-\d{2}|\d{4}-Q[1-4])$').hasMatch(period)) {
    return jsonError(400, 'validation', 'Выберите объект, вид и период отчёта');
  }
  final owned = await bankRows(
    db,
    '''
      SELECT 1 FROM project_facilities f JOIN projects p ON p.id = f.project_id
      WHERE f.bank_id = @bank::uuid AND f.project_id = @project::uuid AND p.company_id = @dev::uuid
    ''',
    {'bank': ctx.bankId, 'project': project, 'dev': id},
  );
  if (owned.isEmpty) return jsonError(404, 'not_found', 'Объект не найден');
  await db.owner.execute(
    Sql.named('''
      INSERT INTO bank_filings (bank_id, project_id, kind, period, filed_on, user_id)
      VALUES (@bank::uuid, @project::uuid, @kind, @period, $bankToday, @user::uuid)
      ON CONFLICT (project_id, kind, period) DO NOTHING
    '''),
    parameters: {'bank': ctx.bankId, 'project': project, 'kind': kind, 'period': period, 'user': ctx.actor.userId},
  );
  await bankEvent(db, ctx, 'filing_received', projectId: project, detail: {'kind': kind, 'period': period});
  return bankOk({'ok': true});
}
