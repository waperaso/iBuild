import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'bank_card.dart' show bankCents;
import 'bank_common.dart';
import 'mail.dart';
import 'bank_data.dart';
import 'bank_export.dart';
import 'bank_portfolio.dart';
import 'bank_rules.dart' show bankMillions;
import 'db.dart';
import 'http_util.dart';

/// Reports of the bank: money, time, control, audit. Each one is a table that
/// the screen draws and the files repeat. Filters: period, branch, one object.

const _catalog = [
  ('money', 'portfolio_summary', 'Сводка по портфелю', 'Лимит, выдано, остаток по каждому объекту'),
  ('money', 'over_confirmed', 'Выдано сверх подтверждённого', 'Где выплат больше, чем подтвердили осмотры'),
  ('money', 'limit_expiry', 'Остаток лимита и срок освоения', 'Кредиты, у которых заканчивается срок выдач'),
  ('time', 'stage_time', 'Время транша по этапам', 'Сколько дней заявка проводит на каждом шаге'),
  ('time', 'overdue_stages', 'Просроченные этапы', 'Кто и на каком этапе превысил срок банка'),
  ('time', 'forecast', 'Прогноз сдачи против срока кредита', 'Объекты, у которых сдача уходит'),
  ('control', 'returns', 'Возвраты заявок и причины', 'Что чаще всего возвращают застройщикам'),
  ('control', 'discipline', 'Дисциплина застройщиков', 'Отчёты о продажах 15-го и 28-го, квартальная отчётность'),
  ('control', 'inspections', 'Осмотры и замеры', 'Выполнено, просрочено, по экспертам'),
  ('audit', 'decision_journal', 'Журнал решений', 'Кто, когда и на каком основании выдал транш'),
  ('audit', 'waived', 'Принято с обоснованием', 'Все исключения: причина, комментарий, кто принял'),
];

const _waiveReasons = {
  'outside_system': 'Документ получен вне системы',
  'fixed_elsewhere': 'Исправлено в другой части заявки',
  'approved_exception': 'Утверждённое исключение',
  'other': 'Другое',
};

const _decisionKinds = {
  'partial': 'Частичная выдача',
  'return_all': 'Возврат целиком',
  'control_measure': 'Контрольный замер',
  'suspend': 'Приостановка финансирования',
  'resume': 'Возобновление финансирования',
};

const _stageNames = {
  'docs': 'Проверка документов',
  'inspection': 'Осмотр эксперта',
  'specialist': 'Решение специалиста',
  'approval': 'Согласование',
  'payout': 'Выплата',
};

void mountBankReports(Router router, AppDatabase db) {
  router
    ..get('/api/bank/reports', (Request r) => _list(r, db))
    ..get('/api/bank/reports/<code>', (Request r, String code) => _show(r, db, code))
    ..get('/api/bank/reports/<code>/file', (Request r, String code) => _file(r, db, code))
    ..post('/api/bank/reports/<code>/schedule', (Request r, String code) => _schedule(r, db, code))
    ..post('/api/bank/reports/<code>/send', (Request r, String code) => _sendNow(r, db, code));
}

class _Filter {
  const _Filter(this.from, this.to, this.branch, this.project);

  final String from;
  final String to;
  final String branch;
  final String project;

  Map<String, Object?> get params => {'from': from, 'to': to, 'branch': branch, 'project': project};
}

/// Period from the request. A month by default; both ends are real dates.
_Filter? _filter(Request request) {
  final query = request.url.queryParameters;
  final now = DateTime.now().toUtc().add(const Duration(hours: 5));
  final first = DateTime.utc(now.year, now.month, 1);
  final last = DateTime.utc(now.year, now.month + 1, 0);
  final from = query['from'] == null ? bankDay(first)! : bankDateInput(query['from']);
  final to = query['to'] == null ? bankDay(last)! : bankDateInput(query['to']);
  if (from == null || to == null || from.compareTo(to) > 0) return null;
  final project = query['project'] ?? '';
  if (project.isNotEmpty && !bankIsUuid(project)) return null;
  final branch = (query['branch'] ?? '').trim();
  if (branch.length > 120) return null;
  return _Filter(from, to, branch, project);
}

const _scope = '''
  f.bank_id = @bank::uuid
  AND (@branch = '' OR f.branch = @branch)
  AND (@project = '' OR f.project_id = @project::uuid)
''';

Future<Response> _list(Request request, AppDatabase db) async {
  final opened = await bankContext(request, db);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final branches = await bankRows(
    db,
    "SELECT DISTINCT branch FROM project_facilities WHERE bank_id = @bank::uuid AND branch <> '' ORDER BY branch",
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
  final schedules = await bankRows(
    db,
    'SELECT code, enabled, recipients FROM bank_report_schedules WHERE bank_id = @bank::uuid',
    {'bank': ctx.bankId},
  );
  final updated = await bankRows(db, 'SELECT now() AS at');
  return bankOk({
    'catalog': [
      for (final item in _catalog) {'group': item.$1, 'code': item.$2, 'title': item.$3, 'subtitle': item.$4},
    ],
    'branches': [for (final row in branches) row['branch']],
    'objects': objects,
    'schedules': schedules,
    'updatedAt': updated.first['at'],
    'canSchedule': ctx.actor.role == 'admin' || ctx.actor.role == 'head' || ctx.actor.role == 'risk',
  });
}

class _Report {
  _Report(this.code, this.title, this.subtitle, this.columns, this.rows, {this.summary = const [], this.note = ''});

  final String code;
  final String title;
  final String subtitle;
  final List<ReportColumn> columns;
  final List<Map<String, Object?>> rows;
  final List<Map<String, Object?>> summary;
  final String note;
}

Future<_Report?> _build(AppDatabase db, BankCtx ctx, String code, _Filter filter) async {
  final entry = _catalog.where((item) => item.$2 == code);
  if (entry.isEmpty) return null;
  final title = entry.first.$3;
  final subtitle = entry.first.$4;
  final base = {'bank': ctx.bankId, ...filter.params};
  Map<String, Object?> stat(String label, String value, {String tone = ''}) =>
      {'label': label, 'value': value, 'tone': tone};

  switch (code) {
    case 'portfolio_summary':
      final rows = await bankRows(
        db,
        '''
          SELECT p.name AS object, f.developer_name AS developer, f.branch AS branch,
                 to_char(f.credit_limit, $bankMoney) AS credit_limit, to_char(f.issued_amount, $bankMoney) AS issued,
                 to_char(f.credit_limit - f.issued_amount, $bankMoney) AS left,
                 (SELECT count(*) FROM bank_tranches t WHERE t.project_id = f.project_id
                    AND t.bank_id = f.bank_id AND t.outcome IS NULL) AS in_work,
                 f.utilize_until AS until
          FROM project_facilities f JOIN projects p ON p.id = f.project_id
          WHERE p.active AND $_scope ORDER BY p.name
        ''',
        base,
      );
      var limit = BigInt.zero;
      var issued = BigInt.zero;
      for (final row in rows) {
        limit += bankCents(row['credit_limit']! as String);
        issued += bankCents(row['issued']! as String);
      }
      return _Report(
        code,
        title,
        subtitle,
        const [
          ReportColumn('object', 'Объект'),
          ReportColumn('developer', 'Застройщик'),
          ReportColumn('branch', 'Филиал'),
          ReportColumn('credit_limit', 'Лимит', kind: 'money'),
          ReportColumn('issued', 'Выдано', kind: 'money'),
          ReportColumn('left', 'Остаток', kind: 'money'),
          ReportColumn('in_work', 'Траншей в работе', kind: 'int'),
          ReportColumn('until', 'Срок освоения', kind: 'date'),
        ],
        [for (final row in rows) {...row, 'until': bankDay(row['until'])}],
        summary: [
          stat('Объектов', '${rows.length}'),
          stat('Лимит, млн UZS', bankMillions(limit)),
          stat('Выдано, млн UZS', bankMillions(issued)),
        ],
      );
    case 'over_confirmed':
      final rules = await bankRulesNow(db, ctx.bankId);
      final threshold = (rules['issuedAbovePercent'] as num?)?.toInt() ?? 1;
      final rows = await bankRows(
        db,
        '''
          SELECT p.name AS object, f.developer_name AS developer, x.issue::text AS issued, x.confirmed::text AS confirmed,
                 (SELECT max(i.completed_on) FROM bank_inspections i
                  WHERE i.project_id = f.project_id AND i.status = 'done') AS last_inspection
          FROM project_facilities f JOIN projects p ON p.id = f.project_id
          JOIN (
            SELECT t.project_id, sum(y.issue) AS issue, sum(y.confirmed) AS confirmed FROM (
              SELECT DISTINCT ON (d.tranche_id) d.tranche_id, d.issue_amount AS issue,
                     COALESCE((SELECT sum(l.confirmed) FROM bank_tranche_lines l WHERE l.tranche_id = d.tranche_id), 0) AS confirmed
              FROM bank_decisions d
              WHERE d.kind = 'partial' AND d.created_at::date BETWEEN @from::date AND @to::date
              ORDER BY d.tranche_id, d.created_at DESC
            ) y JOIN bank_tranches t ON t.id = y.tranche_id GROUP BY t.project_id
          ) x ON x.project_id = f.project_id
          WHERE p.active AND $_scope ORDER BY p.name
        ''',
        base,
      );
      final shown = <Map<String, Object?>>[];
      var rest = 0;
      var over = BigInt.zero;
      for (final row in rows) {
        final issue = bankCents(row['issued']! as String);
        final confirmed = bankCents(row['confirmed']! as String);
        final extra = issue > confirmed ? issue - confirmed : BigInt.zero;
        final percent = issue == BigInt.zero ? BigInt.zero : extra * BigInt.from(1000) ~/ issue;
        if (extra > BigInt.zero && percent * BigInt.from(100) > BigInt.from(threshold) * BigInt.from(1000)) {
          over += extra;
          shown.add({
            'object': row['object'],
            'developer': row['developer'],
            'issued': row['issued'],
            'confirmed': row['confirmed'],
            'over': '${extra ~/ BigInt.from(100)}.${(extra % BigInt.from(100)).toString().padLeft(2, '0')}',
            'percent': '${percent ~/ BigInt.from(10)},${percent % BigInt.from(10)}',
            'last_inspection': bankDay(row['last_inspection']),
          });
        } else {
          rest += 1;
        }
      }
      if (rest > 0) {
        shown.add({'object': 'Остальные $rest объектов', 'developer': 'ниже порога', 'percent': '< $threshold'});
      }
      return _Report(
        code,
        title,
        subtitle,
        const [
          ReportColumn('object', 'Объект'),
          ReportColumn('developer', 'Застройщик'),
          ReportColumn('issued', 'К выдаче по решениям', kind: 'money'),
          ReportColumn('confirmed', 'Подтверждено', kind: 'money'),
          ReportColumn('over', 'Сверх подтверждённого', kind: 'money'),
          ReportColumn('percent', '% выданного', kind: 'percent'),
          ReportColumn('last_inspection', 'Последний осмотр', kind: 'date'),
        ],
        shown,
        summary: [
          stat('Сверх подтверждённого, млн UZS', bankMillions(over), tone: over > BigInt.zero ? 'bad' : ''),
          stat('Объектов выше порога', '${shown.length - (rest > 0 ? 1 : 0)} из ${rows.length}'),
          stat('Порог показа, % от выданного', '$threshold%'),
        ],
        note: 'Порог задаётся в «Правилах». Банк не даёт выдать больше подтверждённого, поэтому отчёт показывает исключения, снятые вручную, и старые данные.',
      );
    case 'limit_expiry':
      final rows = await bankRows(
        db,
        '''
          SELECT p.name AS object, f.developer_name AS developer, f.utilize_until AS until,
                 (f.utilize_until - $bankToday) AS days_left,
                 to_char(f.credit_limit - f.issued_amount, $bankMoney) AS left
          FROM project_facilities f JOIN projects p ON p.id = f.project_id
          WHERE p.active AND f.utilize_until IS NOT NULL AND $_scope
          ORDER BY f.utilize_until
        ''',
        base,
      );
      return _Report(
        code,
        title,
        subtitle,
        const [
          ReportColumn('object', 'Объект'),
          ReportColumn('developer', 'Застройщик'),
          ReportColumn('until', 'Срок освоения', kind: 'date'),
          ReportColumn('days_left', 'Дней осталось', kind: 'int'),
          ReportColumn('left', 'Остаток лимита', kind: 'money'),
        ],
        [for (final row in rows) {...row, 'until': bankDay(row['until'])}],
        summary: [stat('Кредитов со сроком', '${rows.length}')],
      );
    case 'stage_time':
      final times = await bankStageTimes(db, ctx.bankId, DateTime.parse('${filter.from}T00:00:00Z'));
      final rules = await bankRulesNow(db, ctx.bankId);
      final norms = {
        for (final stage in (rules['stages'] as List? ?? const []))
          if (stage is Map) stage['code'].toString(): stage['days'],
      };
      return _Report(
        code,
        title,
        subtitle,
        const [
          ReportColumn('stage', 'Этап'),
          ReportColumn('days', 'Среднее, раб. дней'),
          ReportColumn('norm', 'Срок банка, раб. дней'),
        ],
        [
          for (final stage in times['stages']! as List)
            {
              'stage': _stageNames[(stage as Map)['code']],
              'days': stage['days'].toString().replaceAll('.', ','),
              'norm': norms[stage['code']]?.toString() ?? '',
            },
        ],
        summary: [
          stat('Средний срок транша, раб. дней', times['average'] == null ? 'нет данных' : '${times['average']}'.replaceAll('.', ',')),
        ],
        note: 'Считается по рабочему календарю банка; время у застройщика не входит.',
      );
    case 'overdue_stages':
      final rows = await bankRows(
        db,
        '''
          SELECT p.name AS object, t.tranche_no AS tranche, t.stage AS stage, t.holder_label AS holder,
                 (t.elapsed_days || ' д ' || t.elapsed_hours || ' ч') AS elapsed, t.sla_days AS sla
          FROM bank_tranches t JOIN projects p ON p.id = t.project_id
          JOIN project_facilities f ON f.project_id = t.project_id AND f.bank_id = t.bank_id
          WHERE t.outcome IS NULL AND NOT t.waiting_developer
            AND (t.elapsed_days > t.sla_days OR (t.elapsed_days = t.sla_days AND t.elapsed_hours > 0))
            AND $_scope
          ORDER BY t.elapsed_days DESC
        ''',
        base,
      );
      return _Report(
        code,
        title,
        subtitle,
        const [
          ReportColumn('object', 'Объект'),
          ReportColumn('tranche', 'Транш', kind: 'int'),
          ReportColumn('stage', 'Этап'),
          ReportColumn('holder', 'У кого'),
          ReportColumn('elapsed', 'На этапе'),
          ReportColumn('sla', 'Срок, дн.', kind: 'int'),
        ],
        [for (final row in rows) {...row, 'stage': _stageNames[row['stage']] ?? row['stage']}],
        summary: [stat('Просрочено', '${rows.length}', tone: rows.isEmpty ? '' : 'bad')],
      );
    case 'forecast':
      final rows = await bankRows(
        db,
        '''
          SELECT p.name AS object, f.utilize_until AS until, i.expected_finish AS finish,
                 (i.expected_finish - f.utilize_until) AS late_days, i.completed_on AS inspection
          FROM project_facilities f JOIN projects p ON p.id = f.project_id
          JOIN LATERAL (
            SELECT expected_finish, completed_on FROM bank_inspections
            WHERE project_id = f.project_id AND bank_id = f.bank_id AND status = 'done' AND expected_finish IS NOT NULL
            ORDER BY completed_on DESC NULLS LAST LIMIT 1
          ) i ON true
          WHERE p.active AND f.utilize_until IS NOT NULL AND $_scope
          ORDER BY (i.expected_finish - f.utilize_until) DESC
        ''',
        base,
      );
      return _Report(
        code,
        title,
        subtitle,
        const [
          ReportColumn('object', 'Объект'),
          ReportColumn('until', 'Срок кредита', kind: 'date'),
          ReportColumn('finish', 'Прогноз эксперта', kind: 'date'),
          ReportColumn('late_days', 'Отставание, дн.', kind: 'int'),
          ReportColumn('inspection', 'Осмотр', kind: 'date'),
        ],
        [
          for (final row in rows)
            {
              ...row,
              'until': bankDay(row['until']),
              'finish': bankDay(row['finish']),
              'inspection': bankDay(row['inspection']),
            },
        ],
        summary: [stat('Объектов с прогнозом', '${rows.length}')],
        note: rows.isEmpty
            ? 'Прогноз появляется, когда эксперт указывает ожидаемую дату завершения при закрытии осмотра.'
            : 'Прогноз берётся из последнего осмотра, срок — из кредитного договора.',
      );
    case 'returns':
      final rows = await bankRows(
        db,
        '''
          SELECT x.reason AS reason, count(*) AS count, sum(x.amount)::text AS amount FROM (
            SELECT line ->> 'reason' AS reason, COALESCE((line ->> 'amount')::numeric, 0) AS amount
            FROM bank_decisions d JOIN bank_tranches t ON t.id = d.tranche_id
            JOIN project_facilities f ON f.project_id = t.project_id AND f.bank_id = t.bank_id,
                 jsonb_array_elements(d.return_lines) AS line
            WHERE d.created_at::date BETWEEN @from::date AND @to::date AND $_scope
          ) x WHERE x.reason IS NOT NULL GROUP BY x.reason ORDER BY count(*) DESC
        ''',
        base,
      );
      return _Report(
        code,
        title,
        subtitle,
        const [
          ReportColumn('reason', 'Причина'),
          ReportColumn('count', 'Строк', kind: 'int'),
          ReportColumn('amount', 'Сумма', kind: 'money'),
        ],
        rows,
        summary: [stat('Причин', '${rows.length}')],
      );
    case 'discipline':
      final rules = await bankRulesNow(db, ctx.bankId);
      final devs = await bankDeveloperRows(db, ctx.bankId);
      final rows = <Map<String, Object?>>[];
      for (final dev in devs) {
        final facts = await bankDeveloperFacts(db, ctx.bankId, dev, rules);
        final sales = facts['salesReport']! as Map;
        final quarterly = facts['quarterly']! as Map;
        final supervision = facts['supervision']! as Map;
        rows.add({
          'developer': dev['name'],
          'objects': dev['objects'],
          'sales': '${sales['filed']} из ${sales['of']}',
          'quarterly': '${quarterly['filed']} из ${quarterly['of']}',
          'supervision': '${supervision['regular']} из ${supervision['of']}',
        });
      }
      return _Report(
        code,
        title,
        subtitle,
        const [
          ReportColumn('developer', 'Застройщик'),
          ReportColumn('objects', 'Объектов', kind: 'int'),
          ReportColumn('sales', 'Отчёт о продажах сдан'),
          ReportColumn('quarterly', 'Квартальная отчётность'),
          ReportColumn('supervision', 'Технадзор не реже 2 раз в месяц'),
        ],
        rows,
        summary: [stat('Застройщиков', '${rows.length}')],
      );
    case 'inspections':
      final rows = await bankRows(
        db,
        '''
          SELECT COALESCE(NULLIF(i.expert_label, ''), 'Не назначен') AS expert,
                 count(*) FILTER (WHERE i.status = 'done') AS done,
                 count(*) FILTER (WHERE i.status = 'planned' AND i.scheduled_on >= $bankToday) AS planned,
                 count(*) FILTER (WHERE i.status = 'planned' AND i.scheduled_on < $bankToday) AS overdue
          FROM bank_inspections i
          JOIN project_facilities f ON f.project_id = i.project_id AND f.bank_id = i.bank_id
          WHERE i.scheduled_on BETWEEN @from::date AND @to::date AND $_scope
          GROUP BY 1 ORDER BY 1
        ''',
        base,
      );
      return _Report(
        code,
        title,
        subtitle,
        const [
          ReportColumn('expert', 'Эксперт'),
          ReportColumn('done', 'Выполнено', kind: 'int'),
          ReportColumn('planned', 'Запланировано', kind: 'int'),
          ReportColumn('overdue', 'Просрочено', kind: 'int'),
        ],
        rows,
        summary: [stat('Экспертов', '${rows.length}')],
      );
    case 'decision_journal':
      final rows = await bankRows(
        db,
        '''
          SELECT d.created_at AS at, p.name AS object, t.tranche_no AS tranche, d.kind AS kind,
                 to_char(d.issue_amount, $bankMoney) AS issue, to_char(d.returned_amount, $bankMoney) AS returned,
                 d.waived_count AS waived, d.actor_label AS actor, d.note AS note
          FROM bank_decisions d JOIN bank_tranches t ON t.id = d.tranche_id JOIN projects p ON p.id = t.project_id
          JOIN project_facilities f ON f.project_id = t.project_id AND f.bank_id = t.bank_id
          WHERE d.created_at::date BETWEEN @from::date AND @to::date AND $_scope
          ORDER BY d.created_at DESC LIMIT 1000
        ''',
        base,
      );
      return _Report(
        code,
        title,
        subtitle,
        const [
          ReportColumn('at', 'Когда', kind: 'date'),
          ReportColumn('object', 'Объект'),
          ReportColumn('tranche', 'Транш', kind: 'int'),
          ReportColumn('kind', 'Решение'),
          ReportColumn('issue', 'К выдаче', kind: 'money'),
          ReportColumn('returned', 'Возвращено', kind: 'money'),
          ReportColumn('waived', 'Принято с обоснованием', kind: 'int'),
          ReportColumn('actor', 'Кто'),
          ReportColumn('note', 'Комментарий'),
        ],
        [
          for (final row in rows)
            {...row, 'at': bankDay(row['at']), 'kind': _decisionKinds[row['kind']] ?? row['kind']},
        ],
        summary: [stat('Решений', '${rows.length}')],
      );
    case 'waived':
      final rows = await bankRows(
        db,
        '''
          SELECT w.created_at AS at, p.name AS object, t.tranche_no AS tranche, c.title AS check_title,
                 c.basis AS basis, w.reason AS reason, w.comment AS comment, w.actor_label AS actor
          FROM bank_check_waivers w JOIN bank_checks c ON c.id = w.check_id
          JOIN bank_tranches t ON t.id = w.tranche_id JOIN projects p ON p.id = t.project_id
          JOIN project_facilities f ON f.project_id = t.project_id AND f.bank_id = t.bank_id
          WHERE w.created_at::date BETWEEN @from::date AND @to::date AND $_scope
          ORDER BY w.created_at DESC LIMIT 1000
        ''',
        base,
      );
      return _Report(
        code,
        title,
        subtitle,
        const [
          ReportColumn('at', 'Когда', kind: 'date'),
          ReportColumn('object', 'Объект'),
          ReportColumn('tranche', 'Транш', kind: 'int'),
          ReportColumn('check_title', 'Проверка'),
          ReportColumn('basis', 'Основание'),
          ReportColumn('reason', 'Причина'),
          ReportColumn('comment', 'Комментарий'),
          ReportColumn('actor', 'Кто принял'),
        ],
        [
          for (final row in rows)
            {...row, 'at': bankDay(row['at']), 'reason': _waiveReasons[row['reason']] ?? row['reason']},
        ],
        summary: [stat('Исключений', '${rows.length}')],
      );
  }
  return null;
}

Future<Response> _show(Request request, AppDatabase db, String code) async {
  final opened = await bankContext(request, db);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final filter = _filter(request);
  if (filter == null) return jsonError(400, 'validation', 'Проверьте период и фильтры');
  final report = await _build(db, ctx, code, filter);
  if (report == null) return jsonError(404, 'not_found', 'Такого отчёта нет');
  final schedule = await bankRows(
    db,
    'SELECT enabled, recipients FROM bank_report_schedules WHERE bank_id = @bank::uuid AND code = @code',
    {'bank': ctx.bankId, 'code': code},
  );
  return bankOk({
    'code': report.code,
    'title': report.title,
    'subtitle': report.subtitle,
    'from': filter.from,
    'to': filter.to,
    'summary': report.summary,
    'columns': [for (final column in report.columns) column.toJson()],
    'rows': report.rows,
    'note': report.note,
    'schedule': schedule.isEmpty ? {'enabled': false, 'recipients': ''} : schedule.first,
  });
}

Future<Response> _file(Request request, AppDatabase db, String code) async {
  final opened = await bankContext(request, db);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final filter = _filter(request);
  final format = request.url.queryParameters['format'] ?? 'xlsx';
  if (filter == null || !const {'xlsx', 'pdf', 'csv'}.contains(format)) {
    return jsonError(400, 'validation', 'Проверьте период и формат');
  }
  final report = await _build(db, ctx, code, filter);
  if (report == null) return jsonError(404, 'not_found', 'Такого отчёта нет');
  final rows = [
    for (final row in report.rows) bankJson(row)! as Map<String, Object?>,
  ];
  final stamp = '${report.code}_${filter.from}_${filter.to}';
  await bankEvent(db, ctx, 'report_exported', detail: {'code': code, 'format': format, 'from': filter.from, 'to': filter.to});
  switch (format) {
    case 'csv':
      return Response.ok(reportCsv(report.columns, rows), headers: _fileHeaders('text/csv; charset=utf-8', '$stamp.csv'));
    case 'pdf':
      final bytes = await reportPdf(
        report.title,
        '${ctx.actor.name} · ${filter.from} — ${filter.to}',
        report.columns,
        rows,
      );
      return Response.ok(bytes, headers: _fileHeaders('application/pdf', '$stamp.pdf'));
    default:
      return Response.ok(
        reportXlsx(report.title, report.columns, rows),
        headers: _fileHeaders('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', '$stamp.xlsx'),
      );
  }
}

Map<String, String> _fileHeaders(String type, String name) => {
      'content-type': type,
      'content-disposition': 'attachment; filename="$name"',
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
    };

Future<Response> _schedule(Request request, AppDatabase db, String code) async {
  final opened = await bankContext(request, db, mutating: true, roles: const {'admin', 'head', 'risk'});
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  if (!_catalog.any((item) => item.$2 == code)) return jsonError(404, 'not_found', 'Такого отчёта нет');
  final body = await bankBody(request);
  if (body == null) return jsonError(400, 'validation', 'Не удалось прочитать запрос');
  final enabled = body['enabled'] == true;
  final recipients = (body['recipients'] as String? ?? '').trim();
  final list = recipients.isEmpty ? <String>[] : recipients.split(RegExp(r'[,;\s]+')).where((part) => part.isNotEmpty).toList();
  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (list.length > 20 || list.any((mail) => !valid.hasMatch(mail))) {
    return jsonError(400, 'validation', 'Проверьте адреса почты');
  }
  if (enabled && list.isEmpty) return jsonError(400, 'validation', 'Укажите, кому отправлять');
  await db.owner.execute(
    Sql.named('''
      INSERT INTO bank_report_schedules (bank_id, code, enabled, recipients, updated_at)
      VALUES (@bank::uuid, @code, @enabled, @recipients, now())
      ON CONFLICT (bank_id, code) DO UPDATE
      SET enabled = EXCLUDED.enabled, recipients = EXCLUDED.recipients, updated_at = now()
    '''),
    parameters: {'bank': ctx.bankId, 'code': code, 'enabled': enabled, 'recipients': list.join(', ')},
  );
  await bankEvent(db, ctx, 'report_schedule', detail: {'code': code, 'enabled': enabled, 'recipients': list});
  return bankOk({'ok': true, 'enabled': enabled, 'recipients': list.join(', ')});
}

/// Builds the report and mails it as an Excel file to every address. Returns
/// the worst status of the letters: sent, queued or failed.
Future<String> _mailReport(AppDatabase db, BankCtx ctx, _Report report, _Filter filter, List<String> recipients, String kind) async {
  final rows = [for (final row in report.rows) bankJson(row)! as Map<String, Object?>];
  final bytes = reportXlsx(report.title, report.columns, rows);
  final name = '${report.code}_${filter.from}_${filter.to}.xlsx';
  var worst = 'sent';
  for (final to in recipients) {
    final status = await sendMail(
      db,
      to: to,
      subject: '${report.title}: ${filter.from} — ${filter.to}',
      body: 'Отчёт «${report.title}» за период ${filter.from} — ${filter.to} во вложении.\n$kind\n\niBuild',
      kind: 'report',
      bankId: ctx.bankId,
      attachment: Attachment(name, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', bytes),
    );
    if (status != 'sent') worst = status;
  }
  return worst;
}

List<String> _addresses(Object? recipients) =>
    '${recipients ?? ''}'.split(RegExp(r'[,;\s]+')).where(isMailAddress).toList();

/// Sends the report to the people of the schedule now, as an Excel file.
Future<Response> _sendNow(Request request, AppDatabase db, String code) async {
  final opened = await bankContext(request, db, mutating: true, roles: const {'admin', 'head', 'risk'});
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final filter = _filter(request);
  if (filter == null) return jsonError(400, 'validation', 'Проверьте период и фильтры');
  final report = await _build(db, ctx, code, filter);
  if (report == null) return jsonError(404, 'not_found', 'Такого отчёта нет');
  final schedule = await bankRows(
    db,
    'SELECT recipients FROM bank_report_schedules WHERE bank_id = @bank::uuid AND code = @code',
    {'bank': ctx.bankId, 'code': code},
  );
  final recipients = schedule.isEmpty ? <String>[] : _addresses(schedule.first['recipients']);
  if (recipients.isEmpty) return jsonError(400, 'validation', 'Сначала укажите, кому отправлять');
  final worst = await _mailReport(db, ctx, report, filter, recipients, 'Сформировал: ${ctx.actor.name}.');
  await bankEvent(db, ctx, 'report_sent', detail: {'code': code, 'recipients': recipients, 'mail': worst});
  return bankOk({'ok': true, 'mail': worst, 'count': recipients.length});
}

/// The Monday mailing: every enabled schedule gets last week's report once.
/// Runs from a timer; [force] skips the day and hour check (for tests).
Future<int> runReportSchedules(AppDatabase db, {DateTime? now, bool force = false}) async {
  final local = (now ?? DateTime.now().toUtc()).add(const Duration(hours: 5));
  if (!force && (local.weekday != DateTime.monday || local.hour < 9)) return 0;
  final today = DateTime.utc(local.year, local.month, local.day);
  final due = await bankRows(
    db,
    '''
      SELECT bank_id::text AS bank_id, code, recipients FROM bank_report_schedules
      WHERE enabled AND (last_sent_on IS NULL OR last_sent_on < @today::date)
    ''',
    {'today': bankDay(today)},
  );
  final filter = _Filter(bankDay(today.subtract(const Duration(days: 7)))!, bankDay(today.subtract(const Duration(days: 1)))!, '', '');
  var sent = 0;
  for (final row in due) {
    final bankId = row['bank_id']! as String;
    final owner = await bankRows(
      db,
      "SELECT user_id::text AS id, 'iBuild по расписанию' AS name FROM bank_staff WHERE bank_id = @bank::uuid AND role = 'admin' AND active LIMIT 1",
      {'bank': bankId},
    );
    if (owner.isEmpty) continue;
    final ctx = BankCtx(
      const SessionLookup(SessionState.ok),
      BankActor(userId: owner.first['id']! as String, name: owner.first['name']! as String, bankId: bankId, role: 'admin'),
    );
    final report = await _build(db, ctx, row['code']! as String, filter);
    final recipients = _addresses(row['recipients']);
    await db.owner.execute(
      Sql.named('UPDATE bank_report_schedules SET last_sent_on = @today::date WHERE bank_id = @bank::uuid AND code = @code'),
      parameters: {'today': bankDay(today), 'bank': bankId, 'code': row['code']},
    );
    if (report == null || recipients.isEmpty) continue;
    final worst = await _mailReport(db, ctx, report, filter, recipients, 'Отправлено по расписанию.');
    await bankEvent(db, ctx, 'report_sent', detail: {'code': row['code'], 'recipients': recipients, 'mail': worst, 'scheduled': true});
    sent++;
  }
  return sent;
}
