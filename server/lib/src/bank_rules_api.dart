import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'bank_common.dart';
import 'bank_data.dart';
import 'bank_portfolio.dart' show bankRulesNow;
import 'db.dart';
import 'http_util.dart';
import 'money.dart';

/// Rules and routes. The checks and the stages that the contract demands are
/// fixed. The bank changes only the thresholds, the days of the stages, the
/// documents and the groups. Every change of the rules is a new version: new
/// tranches follow it, the tranches already in work keep the version they began with.

const _admin = {'admin'};
const _stageCodes = ['docs', 'inspection', 'specialist', 'approval', 'payout'];
const _owners = {'specialist', 'expert', 'head', 'committee', 'payment'};

const _defaultDocuments = [
  {'code': 'act', 'title': 'Акт выполненных работ', 'when': 'каждый транш', 'obligation': 'Обязателен', 'effect': 'block', 'basis': 'ГС п. 3.5, договор п. 2.12'},
  {'code': 'form3', 'title': 'Справка ф.3 о стоимости работ', 'when': 'каждый транш по строительным работам', 'obligation': 'Обязательна', 'effect': 'block', 'basis': 'ГС п. 4.12'},
  {'code': 'invoice', 'title': 'ЭСФ или счёт-фактура', 'when': 'каждый платёж', 'obligation': 'Обязательна', 'effect': 'block', 'basis': 'ГС п. 3.5'},
  {'code': 'supervision', 'title': 'Отчёт технадзора застройщика', 'when': 'не реже двух раз в месяц и к траншу', 'obligation': 'Обязателен', 'effect': 'warning', 'basis': 'ГС п. 4.2, 4.7'},
  {'code': 'contract', 'title': 'Копия договора с подрядчиком или поставщиком', 'when': 'первый платёж по договору', 'obligation': 'Обязательна', 'effect': 'block', 'basis': 'ГС п. 3.5'},
  {'code': 'license', 'title': 'Лицензия подрядчика или поставщика', 'when': 'первый платёж по договору', 'obligation': 'Если вид деятельности лицензируется', 'effect': 'block', 'basis': 'ГС п. 3.5'},
  {'code': 'waybill', 'title': 'Накладная', 'when': 'поставка материалов', 'obligation': 'Для материалов', 'effect': 'block', 'basis': 'ГС п. 3.5'},
  {'code': 'certificate', 'title': 'Сертификат соответствия', 'when': 'материалы, оборудование, работы', 'obligation': 'Обязателен', 'effect': 'block', 'basis': 'ГС п. 3.5'},
  {'code': 'customs', 'title': 'Таможенная декларация', 'when': 'импортные товары', 'obligation': 'Если импорт', 'effect': 'block', 'basis': 'ГС п. 3.5'},
  {'code': 'concrete_log', 'title': 'Журнал бетонных работ, акты скрытых работ', 'when': 'по соответствующим видам работ', 'obligation': 'Для этих видов работ', 'effect': 'warning', 'basis': 'ГС п. 4.5'},
];

void mountBankRules(Router router, AppDatabase db) {
  router
    ..get('/api/bank/rules', (Request r) => _show(r, db))
    ..get('/api/bank/rules/versions/<version>', (Request r, String version) => _version(r, db, version))
    ..get('/api/bank/audit', (Request r) => _audit(r, db))
    ..post('/api/bank/rules', (Request r) => _save(r, db))
    ..post('/api/bank/rules/groups/<code>', (Request r, String code) => _group(r, db, code))
    ..post('/api/bank/rules/members/<userId>', (Request r, String userId) => _member(r, db, userId));
}

/// What the snapshot says, with the defaults for what an older version lacks.
Map<String, Object?> bankNormalizedRules(Map<String, Object?> raw) {
  final stages = <String, Map<String, Object?>>{
    for (final item in (raw['stages'] as List? ?? const []))
      if (item is Map) item['code'].toString(): item.map((key, value) => MapEntry(key.toString(), value)),
  };
  const defaults = {'docs': 1, 'inspection': 5, 'specialist': 2, 'approval': 2, 'payout': 1};
  const owners = {'docs': 'specialist', 'inspection': 'expert', 'specialist': 'specialist', 'approval': 'head', 'payout': 'payment'};
  return {
    'committeeAmount': raw['committeeAmount'] ?? '2000000000.00',
    'issuedAbovePercent': raw['issuedAbovePercent'] ?? 1,
    'scheduleLagMonths': raw['scheduleLagMonths'] ?? 3,
    'forecastWarningDays': raw['forecastWarningDays'] ?? 30,
    'forecastRedMonths': raw['forecastRedMonths'] ?? 6,
    'salesReportDays': raw['salesReportDays'] ?? const [15, 28],
    'remindGroup': raw['remindGroup'] ?? true,
    'stages': [
      for (final code in _stageCodes)
        {
          'code': code,
          'days': stages[code]?['days'] ?? defaults[code],
          'owner': stages[code]?['owner'] ?? owners[code],
        },
    ],
    'documents': raw['documents'] ?? _defaultDocuments,
  };
}

Future<Response> _show(Request request, AppDatabase db) async {
  final opened = await bankContext(request, db, roles: _admin);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final versions = await bankRows(
    db,
    '''
      SELECT v.version AS version, v.effective_from AS effective_from, v.snapshot AS snapshot,
             v.note AS note, COALESCE(u.name, '') AS author, v.created_at AS created_at
      FROM bank_rule_versions v LEFT JOIN users u ON u.id = v.author_id
      WHERE v.bank_id = @bank::uuid ORDER BY v.version DESC
    ''',
    {'bank': ctx.bankId},
  );
  if (versions.isEmpty) return jsonError(404, 'not_found', 'Правила банка не заданы');
  final snapshots = [
    for (final row in versions) bankNormalizedRules(Map<String, Object?>.from(row['snapshot']! as Map)),
  ];
  final history = <Map<String, Object?>>[];
  for (var i = 0; i < versions.length; i++) {
    final older = i + 1 < versions.length ? snapshots[i + 1] : null;
    final changed = <String>[
      if (older != null)
        for (final key in snapshots[i].keys)
          if (jsonEncode(snapshots[i][key]) != jsonEncode(older[key])) key,
    ];
    history.add({
      'version': versions[i]['version'],
      'effectiveFrom': bankDay(versions[i]['effective_from']),
      'author': versions[i]['author'],
      'note': versions[i]['note'],
      'createdAt': versions[i]['created_at'],
      'changed': changed,
    });
  }
  final groups = await bankRows(
    db,
    '''
      SELECT g.code AS code, g.name AS name, g.required_approvals AS required,
             COALESCE(json_agg(json_build_object(
               'userId', m.user_id::text, 'name', u.name, 'title', m.title, 'branch', m.branch,
               'onLeaveUntil', s.on_leave_until, 'active', s.active) ORDER BY u.name)
               FILTER (WHERE m.user_id IS NOT NULL), '[]'::json) AS members
      FROM bank_groups g
      LEFT JOIN bank_group_members m ON m.group_id = g.id
      LEFT JOIN users u ON u.id = m.user_id
      LEFT JOIN bank_staff s ON s.user_id = m.user_id
      WHERE g.bank_id = @bank::uuid GROUP BY g.id ORDER BY g.code
    ''',
    {'bank': ctx.bankId},
  );
  final changes = await bankRows(
    db,
    '''
      SELECT action, actor_label, created_at, detail FROM bank_audit_events
      WHERE bank_id = @bank::uuid AND action IN ('rules_saved', 'rules_group', 'rules_member')
      ORDER BY created_at DESC LIMIT 100
    ''',
    {'bank': ctx.bankId},
  );
  return bankOk({
    'version': versions.first['version'],
    'effectiveFrom': bankDay(versions.first['effective_from']),
    'rules': snapshots.first,
    'history': history,
    'groups': groups,
    'changes': changes,
  });
}

Future<Response> _version(Request request, AppDatabase db, String version) async {
  final opened = await bankContext(request, db, roles: _admin);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final number = int.tryParse(version);
  if (number == null) return jsonError(404, 'not_found', 'Версия не найдена');
  final rows = await bankRows(
    db,
    'SELECT snapshot, effective_from FROM bank_rule_versions WHERE bank_id = @bank::uuid AND version = @version',
    {'bank': ctx.bankId, 'version': number},
  );
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Версия не найдена');
  return bankOk({
    'version': number,
    'effectiveFrom': bankDay(rows.first['effective_from']),
    'rules': bankNormalizedRules(Map<String, Object?>.from(rows.first['snapshot']! as Map)),
  });
}

class _Invalid implements Exception {
  const _Invalid(this.message);

  final String message;
}

int _int(Object? value, String name, int min, int max) {
  if (value is! num || value != value.toInt() || value < min || value > max) {
    throw _Invalid('$name: число от $min до $max');
  }
  return value.toInt();
}

String _text(Object? value, String name, int max, {bool required = true}) {
  final text = (value is String ? value : '').trim();
  if (required && text.isEmpty) throw _Invalid('$name: заполните поле');
  if (text.length > max) throw _Invalid('$name: не длиннее $max знаков');
  return text;
}

Map<String, Object?> _validated(Map<String, Object?> body, Map<String, Object?> current) {
  final committee = normalizeMoney('${body['committeeAmount'] ?? current['committeeAmount']}');
  if (committee == null) throw const _Invalid('Порог комитета: сумма в сумах, например 2000000000');
  final days = body['salesReportDays'] ?? current['salesReportDays'];
  if (days is! List || days.isEmpty || days.length > 4) throw const _Invalid('Отчёт о продажах: от одного до четырёх чисел месяца');
  final salesDays = {for (final day in days) _int(day, 'Отчёт о продажах', 1, 28)}.toList()..sort();

  final stagesInput = body['stages'] ?? current['stages'];
  if (stagesInput is! List) throw const _Invalid('Сроки этапов не заданы');
  final byCode = {
    for (final item in stagesInput)
      if (item is Map) item['code'].toString(): item,
  };
  final stages = [
    for (final code in _stageCodes)
      {
        'code': code,
        'days': _int(byCode[code]?['days'], 'Срок этапа', 1, 30),
        'owner': _owners.contains(byCode[code]?['owner']) ? byCode[code]!['owner'] : (throw const _Invalid('Исполнитель этапа указан неверно')),
      },
  ];

  final documentsInput = body['documents'] ?? current['documents'];
  if (documentsInput is! List || documentsInput.length > 40) throw const _Invalid('Список документов слишком длинный');
  final seen = <String>{};
  final documents = [
    for (final item in documentsInput)
      if (item is Map)
        () {
          final code = _text(item['code'], 'Код документа', 40);
          if (!RegExp(r'^[a-z0-9_]+$').hasMatch(code) || !seen.add(code)) {
            throw const _Invalid('Код документа: латиница, цифры и «_», без повторов');
          }
          final effect = item['effect'];
          if (effect != 'block' && effect != 'warning') throw const _Invalid('Укажите, что происходит без документа');
          return {
            'code': code,
            'title': _text(item['title'], 'Название документа', 120),
            'when': _text(item['when'], 'Когда нужен', 200),
            'obligation': _text(item['obligation'], 'Обязательность', 120),
            'effect': effect,
            'basis': _text(item['basis'], 'Основание', 60, required: false),
          };
        }(),
  ];

  return {
    'committeeAmount': committee,
    'issuedAbovePercent': _int(body['issuedAbovePercent'] ?? current['issuedAbovePercent'], 'Выдано сверх подтверждённого, %', 0, 100),
    'scheduleLagMonths': _int(body['scheduleLagMonths'] ?? current['scheduleLagMonths'], 'Отставание от графика, мес.', 1, 24),
    'forecastWarningDays': _int(body['forecastWarningDays'] ?? current['forecastWarningDays'], 'Прогноз: предупреждение, дн.', 1, 365),
    'forecastRedMonths': _int(body['forecastRedMonths'] ?? current['forecastRedMonths'], 'Прогноз: красный сигнал, мес.', 1, 24),
    'salesReportDays': salesDays,
    'remindGroup': (body['remindGroup'] ?? current['remindGroup']) == true,
    'stages': stages,
    'documents': documents,
  };
}

Future<Response> _save(Request request, AppDatabase db) async {
  final opened = await bankContext(request, db, mutating: true, roles: _admin);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final body = await bankBody(request);
  if (body == null) return jsonError(400, 'validation', 'Не удалось прочитать запрос');
  final current = bankNormalizedRules(await bankRulesNow(db, ctx.bankId));
  final Map<String, Object?> next;
  try {
    next = _validated(body, current);
  } on _Invalid catch (failure) {
    return jsonError(400, 'validation', failure.message);
  }
  final note = _noteOf(body['note']);
  if (jsonEncode(next) == jsonEncode(current)) {
    return jsonError(409, 'no_changes', 'Ничего не изменилось');
  }
  final version = await db.owner.runTx((tx) async {
    await tx.execute(Sql.named('SELECT pg_advisory_xact_lock(hashtext(@bank))'), parameters: {'bank': ctx.bankId});
    final number = await tx.execute(
      Sql.named('SELECT COALESCE(max(version), 0) + 1 FROM bank_rule_versions WHERE bank_id = @bank::uuid'),
      parameters: {'bank': ctx.bankId},
    );
    final created = number.first[0]! as int;
    await tx.execute(
      Sql.named('''
        INSERT INTO bank_rule_versions (bank_id, version, effective_from, snapshot, author_id, note)
        VALUES (@bank::uuid, @version, (now() AT TIME ZONE 'Asia/Tashkent')::date, @snapshot::jsonb, @user::uuid, @note)
      '''),
      parameters: {
        'bank': ctx.bankId,
        'version': created,
        'snapshot': jsonEncode(next),
        'user': ctx.actor.userId,
        'note': note,
      },
    );
    await bankAudit(
      tx,
      bankId: ctx.bankId,
      userId: ctx.actor.userId,
      actorLabel: ctx.actor.name,
      action: 'rules_saved',
      detail: {'version': created, 'note': note},
    );
    return created;
  });
  return bankOk({'version': version, 'rules': next});
}

String _noteOf(Object? value) {
  final text = (value is String ? value : '').trim();
  return text.length > 500 ? text.substring(0, 500) : text;
}

Future<Response> _group(Request request, AppDatabase db, String code) async {
  final opened = await bankContext(request, db, mutating: true, roles: _admin);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final body = await bankBody(request);
  final required = body?['requiredApprovals'];
  if (required is! int || required < 1 || required > 20) {
    return jsonError(400, 'validation', 'Число согласий: от 1 до 20');
  }
  final active = await bankRows(
    db,
    '''
      SELECT g.id::text AS id, count(*) FILTER (
               WHERE s.active AND (s.on_leave_until IS NULL OR s.on_leave_until < $bankToday)) AS free
      FROM bank_groups g
      LEFT JOIN bank_group_members m ON m.group_id = g.id
      LEFT JOIN bank_staff s ON s.user_id = m.user_id
      WHERE g.bank_id = @bank::uuid AND g.code = @code GROUP BY g.id
    ''',
    {'bank': ctx.bankId, 'code': code},
  );
  if (active.isEmpty) return jsonError(404, 'not_found', 'Группа не найдена');
  if (required > bankInt(active.first['free'])) {
    return jsonError(409, 'quorum', 'Согласий не может быть больше, чем активных участников группы');
  }
  await db.owner.execute(
    Sql.named('UPDATE bank_groups SET required_approvals = @required WHERE id = @id::uuid'),
    parameters: {'required': required, 'id': active.first['id']},
  );
  await bankEvent(db, ctx, 'rules_group', detail: {'group': code, 'required': required});
  return bankOk({'ok': true});
}

Future<Response> _member(Request request, AppDatabase db, String userId) async {
  final opened = await bankContext(request, db, mutating: true, roles: _admin);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  if (!bankIsUuid(userId)) return jsonError(404, 'not_found', 'Не найдено');
  final body = await bankBody(request);
  if (body == null) return jsonError(400, 'validation', 'Не удалось прочитать запрос');
  final raw = body['onLeaveUntil'];
  final until = raw == null || raw == '' ? null : bankDateInput(raw);
  if (raw != null && raw != '' && until == null) return jsonError(400, 'validation', 'Дата возвращения указана неверно');
  final updated = await bankRows(
    db,
    '''
      UPDATE bank_staff SET on_leave_until = @until::date
      WHERE user_id = @user::uuid AND bank_id = @bank::uuid
      RETURNING user_id::text AS id
    ''',
    {'until': until, 'user': userId, 'bank': ctx.bankId},
  );
  if (updated.isEmpty) return jsonError(404, 'not_found', 'Сотрудник не найден');
  await bankEvent(db, ctx, 'rules_member', detail: {'user': userId, 'onLeaveUntil': until});
  return bankOk({'ok': true});
}

const _auditRoles = {'admin', 'audit', 'risk', 'head'};

/// The journal of the whole bank: who did what and when. Read only.
Future<Response> _audit(Request request, AppDatabase db) async {
  final opened = await bankContext(request, db, roles: _auditRoles);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  final query = request.url.queryParameters;
  final from = query['from'] == null ? '' : (bankDateInput(query['from']) ?? 'bad');
  final to = query['to'] == null ? '' : (bankDateInput(query['to']) ?? 'bad');
  if (from == 'bad' || to == 'bad') return jsonError(400, 'validation', 'Дата указана неверно');
  final action = (query['action'] ?? '').trim();
  final person = (query['q'] ?? '').trim();
  final limit = (int.tryParse(query['limit'] ?? '') ?? 100).clamp(1, 500);
  final rows = await bankRows(
    db,
    '''
      SELECT e.id::text AS id, e.action AS action, e.actor_label AS actor, e.detail AS detail,
             e.created_at AS at, e.tranche_id::text AS tranche_id, COALESCE(p.name, '') AS project
      FROM bank_audit_events e LEFT JOIN projects p ON p.id = e.project_id
      WHERE e.bank_id = @bank::uuid
        AND (@action = '' OR e.action = @action)
        AND (@q = '' OR e.actor_label ILIKE '%' || @q || '%' OR COALESCE(p.name, '') ILIKE '%' || @q || '%')
        AND (@from = '' OR e.created_at >= (@from::date)::timestamp AT TIME ZONE 'Asia/Tashkent')
        AND (@to = '' OR e.created_at < ((@to::date) + 1)::timestamp AT TIME ZONE 'Asia/Tashkent')
      ORDER BY e.created_at DESC LIMIT @limit
    ''',
    {'bank': ctx.bankId, 'action': action, 'q': person, 'from': from, 'to': to, 'limit': limit},
  );
  final actions = await bankRows(
    db,
    'SELECT DISTINCT action FROM bank_audit_events WHERE bank_id = @bank::uuid ORDER BY action',
    {'bank': ctx.bankId},
  );
  return bankOk({'items': rows, 'actions': [for (final row in actions) row['action']]});
}

/// A bank that has just been approved has no contract thresholds and no
/// approval groups. The first version is the published default, which the
/// administrator can replace. Nothing here changes a bank that already chose
/// its own rules.
Future<void> ensureBankDefaults(Session tx, String bankId) async {
  final existing = await tx.execute(
    Sql.named('SELECT 1 FROM bank_rule_versions WHERE bank_id = @bank::uuid LIMIT 1'),
    parameters: {'bank': bankId},
  );
  if (existing.isEmpty) {
    await tx.execute(
      Sql.named('''
        INSERT INTO bank_rule_versions (bank_id, version, effective_from, snapshot, note)
        VALUES (
          @bank::uuid, 1, (now() AT TIME ZONE 'Asia/Tashkent')::date, @snapshot::jsonb,
          'Начальные правила'
        )
      '''),
      parameters: {'bank': bankId, 'snapshot': jsonEncode(bankNormalizedRules(const {}))},
    );
  }
  for (final group in const [
    ('heads', 'Начальники отдела', 1),
    ('committee', 'Кредитный комитет', 1),
  ]) {
    await tx.execute(
      Sql.named('''
        INSERT INTO bank_groups (bank_id, code, name, required_approvals)
        VALUES (@bank::uuid, @code, @name, @required)
        ON CONFLICT (bank_id, code) DO NOTHING
      '''),
      parameters: {'bank': bankId, 'code': group.$1, 'name': group.$2, 'required': group.$3},
    );
  }
}
