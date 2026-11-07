import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'db.dart';
import 'http_util.dart';
import 'money.dart';
import 'passwords.dart';

const _uuid =
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

void mountLoan(Router router, AppDatabase db) {
  router
    ..get('/api/fx/usd', (Request request) => _fx(request, db))
    ..get('/api/inspections', (Request request) => _inspectionList(request, db))
    ..post('/api/inspections', (Request request) => _requestInspection(request, db))
    ..post('/api/inspections/<id>/report', (Request request, String id) => _reportInspection(request, db, id))
    ..get('/api/notices', (Request request) => _notices(request, db))
    ..get('/api/projects/<id>/loan', (Request request, String id) => _loan(request, db, id))
    ..post('/api/projects/<id>/sources', (Request request, String id) => _addSource(request, db, id))
    ..post('/api/projects/<id>/bank', (Request request, String id) => _connectBank(request, db, id))
    ..post('/api/projects/<id>/budget/import', (Request request, String id) => _import(request, db, id))
    ..post('/api/projects/<id>/budget/copy', (Request request, String id) => _copyBudget(request, db, id))
    ..post('/api/budget-templates', (Request request) => _saveTemplate(request, db))
    ..post('/api/projects/<id>/budget/from-template', (Request request, String id) => _applyTemplate(request, db, id))
    ..post('/api/draws', (Request request) => _createDraw(request, db))
    ..get('/api/draws/<id>', (Request request, String id) => _draw(request, db, id))
    ..patch('/api/draws/<id>', (Request request, String id) => _patchDraw(request, db, id))
    ..post('/api/draws/<id>/submit', (Request request, String id) => _submitDraw(request, db, id))
    ..post('/api/draws/<id>/decide', (Request request, String id) => _decide(request, db, id))
    ..post('/api/projects/<id>/inspections', (Request request, String id) => _inspect(request, db, id))
    ..post('/api/draws/<id>/comments', (Request request, String id) => _comment(request, db, id))
    ..post('/api/draws/<id>/payables', (Request request, String id) => _payable(request, db, id))
    ..get('/api/draws/<id>/package', (Request request, String id) => _package(request, db, id))
    ..patch('/api/contractor-firms/<id>', (Request request, String id) => _compliance(request, db, id));
}

Future<Object> _user(Request request, AppDatabase db) async {
  final token = readCookies(request)[sessionCookieName];
  if (token == null || token.isEmpty) {
    return jsonError(401, 'unauthenticated', 'Войдите, чтобы продолжить.');
  }
  final lookup = await db.lookupSession(sha256Hex(token));
  if (lookup.state != SessionState.ok || lookup.user == null) {
    return jsonError(401, 'unauthenticated', 'Войдите, чтобы продолжить.');
  }
  final header = request.headers['x-csrf-token'] ?? '';
  if (request.method != 'GET') {
    final expected = lookup.csrfToken ?? '';
    if (header.isEmpty || expected.isEmpty || !tokensEqual(header, expected)) {
      return jsonError(403, 'csrf', 'Сессия устарела. Обновите страницу и войдите снова.');
    }
  }
  return lookup.user!.id;
}

Future<Response> _fx(Request request, AppDatabase db) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final client = HttpClient();
  try {
    final outbound = await client.getUrl(
      Uri.parse('https://cbu.uz/ru/arkhiv-kursov-valyut/json/USD/'),
    );
    final incoming = await outbound.close();
    final raw = await incoming.transform(utf8.decoder).join();
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.isEmpty || decoded.first is! Map) {
      return jsonError(502, 'fx', 'Курс Центробанка сейчас недоступен.');
    }
    final row = (decoded.first as Map).map((key, value) => MapEntry(key.toString(), value));
    final rate = '${row['Rate'] ?? ''}'.trim();
    if (normalizeMoney(rate) == null && !RegExp(r'^\d+(\.\d+)?$').hasMatch(rate)) {
      return jsonError(502, 'fx', 'Курс Центробанка сейчас недоступен.');
    }
    return jsonResponse(200, {'rate': rate, 'date': '${row['Date'] ?? ''}'});
  } on SocketException {
    return jsonError(502, 'fx', 'Курс Центробанка сейчас недоступен.');
  } finally {
    client.close(force: true);
  }
}

Future<Response> _inspectionList(Request request, AppDatabase db) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT i.id::text, i.project_id::text, p.name AS project_name, i.status,
             COALESCE(i.scheduled_on::text, '') AS scheduled_on,
             i.note, i.gate_code,
             COALESCE(i.request_id::text, '') AS request_id,
             COALESCE(bi.title, '') AS request_line
      FROM inspections i
      JOIN projects p ON p.id = i.project_id
      LEFT JOIN funding_requests fr ON fr.id = i.request_id
      LEFT JOIN budget_items bi ON bi.id = fr.budget_item_id
      ORDER BY i.created_at DESC
    '''),
  );
  return jsonResponse(200, {
    'inspections': [for (final row in rows) row.toColumnMap()],
  });
}

Future<Response> _requestInspection(Request request, AppDatabase db) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final userId = opened as String;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final projectId = (json['projectId'] as String? ?? '').trim();
  final requestId = (json['requestId'] as String? ?? '').trim();
  final when = (json['scheduledOn'] as String? ?? '').trim();
  final note = (json['note'] as String? ?? '').trim();
  if (!RegExp(_uuid).hasMatch(projectId) || note.isEmpty) {
    return jsonError(400, 'validation', 'Выберите объект и напишите, что проверить.');
  }
  if (requestId.isNotEmpty && !RegExp(_uuid).hasMatch(requestId)) {
    return jsonError(404, 'not_found', 'Транш не найден.');
  }
  final rows = await db.pool.execute(
    Sql.named('''
      INSERT INTO inspections (
        project_id, request_id, scheduled_on, note, status, author_user_id
      )
      SELECT @project::uuid,
             NULLIF(@request, '')::uuid,
             NULLIF(@when, '')::date,
             @note,
             'requested',
             @user::uuid
      FROM project_members
      WHERE project_id = @project::uuid
        AND user_id = @user::uuid
        AND role = 'observer'
        AND (
          @request = ''
          OR EXISTS (
            SELECT 1 FROM funding_requests fr
            WHERE fr.id = @request::uuid AND fr.project_id = @project::uuid
          )
        )
      RETURNING id::text
    '''),
    parameters: {
      'project': projectId,
      'request': requestId,
      'when': when,
      'note': note,
      'user': userId,
    },
  );
  if (rows.isEmpty) return jsonError(403, 'forbidden', 'У вас нет прав на это действие.');
  return jsonResponse(201, {'id': rows.first[0], 'status': 'requested'});
}

Future<Response> _reportInspection(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final userId = opened as String;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final note = (json['note'] as String? ?? '').trim();
  final lines = json['lines'];
  if (!RegExp(_uuid).hasMatch(id) || lines is! List) {
    return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  }
  final updated = await db.pool.runTx((session) async {
    final head = await session.execute(
      Sql.named('''
        UPDATE inspections
        SET status = 'reported',
            note = CASE WHEN @note = '' THEN note ELSE note || E'\n' || @note END
        WHERE id = @id::uuid
          AND status = 'requested'
          AND app_member_role(project_id) IN ('director', 'developer')
        RETURNING id::text, COALESCE(request_id::text, '')
      '''),
      parameters: {'id': id, 'note': note},
    );
    if (head.isEmpty) return false;
    final requestId = head.first[1]! as String;
    for (final raw in lines) {
      final line = raw as Map<String, dynamic>;
      final item = (line['budgetItemId'] as String? ?? '').trim();
      if (!RegExp(_uuid).hasMatch(item)) continue;
      await session.execute(
        Sql.named('''
          INSERT INTO inspection_lines (inspection_id, budget_item_id, percent, recommend, comment)
          VALUES (@inspection::uuid, @item::uuid, @percent::numeric, @recommend::numeric, @comment)
        '''),
        parameters: {
          'inspection': id,
          'item': item,
          'percent': _nonNegative(line['percent']),
          'recommend': _nonNegative(line['recommend']),
          'comment': (line['comment'] as String? ?? '').trim(),
        },
      );
      if (RegExp(_uuid).hasMatch(requestId)) {
        await session.execute(
          Sql.named('''
            UPDATE draw_lines
            SET inspector_percent = @percent::numeric,
                inspector_recommend = @recommend::numeric,
                inspector_comment = @comment
            WHERE request_id = @request::uuid AND budget_item_id = @item::uuid
          '''),
          parameters: {
            'percent': _nonNegative(line['percent']),
            'recommend': _nonNegative(line['recommend']),
            'comment': (line['comment'] as String? ?? '').trim(),
            'request': requestId,
            'item': item,
          },
        );
      }
    }
    return true;
  });
  if (updated != true) return jsonError(404, 'not_found', 'Осмотр не найден.');
  return jsonResponse(200, {'id': id, 'status': 'reported', 'author': userId});
}

Future<Response> _loan(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  if (!RegExp(_uuid).hasMatch(id)) return jsonError(404, 'not_found', 'Объект не найден.');
  final visible = await db.pool.execute(
    Sql.named('SELECT 1 FROM projects WHERE id = @id::uuid'),
    parameters: {'id': id},
  );
  if (visible.isEmpty) return jsonError(404, 'not_found', 'Объект не найден.');
  await _ensureChecklist(db, id);
  final sources = await db.pool.execute(
    Sql.named('''
      SELECT id::text, name, kind, to_char(amount, 'FM999999999999990.00') AS amount
      FROM funding_sources WHERE project_id = @id::uuid ORDER BY name
    '''),
    parameters: {'id': id},
  );
  final checklist = await db.pool.execute(
    Sql.named('''
      SELECT id::text, code, title, required
      FROM checklist_items WHERE project_id = @id::uuid ORDER BY code
    '''),
    parameters: {'id': id},
  );
  final lines = await db.pool.execute(
    Sql.named('''
      SELECT bi.id::text, bi.cost_code, bi.title, bi.cost_kind, bi.budget_side,
             to_char(CASE WHEN bi.plan_set THEN bi.planned_amount ELSE 0 END, 'FM999999999999990.00') AS amount,
             to_char(CASE WHEN bi.plan_set THEN bi.planned_amount ELSE 0 END, 'FM999999999999990.00') AS original,
             to_char(CASE WHEN bi.plan_set THEN line_adjust(bi.id) ELSE 0 END, 'FM999999999999990.00') AS adjusted,
             to_char(CASE WHEN bi.plan_set THEN bi.planned_amount + line_adjust(bi.id) ELSE 0 END, 'FM999999999999990.00') AS revised,
             to_char(CASE WHEN bi.plan_set THEN line_hold(bi.id, ARRAY['paid']) ELSE 0 END, 'FM999999999999990.00') AS funded,
             to_char(
               CASE WHEN bi.plan_set THEN
                 bi.planned_amount + line_adjust(bi.id)
                   - line_hold(bi.id, ARRAY['submitted', 'tech_approved', 'approved', 'paid'])
               ELSE 0 END,
               'FM999999999999990.00'
             ) AS remaining,
             to_char(bi.retainage_percent, 'FM990.00') AS retainage_percent,
             to_char(line_retainage(bi.id), 'FM999999999999990.00') AS retainage_balance,
             COALESCE((
               SELECT to_char(dl.inspector_percent, 'FM990.00')
               FROM draw_lines dl
               JOIN funding_requests fr ON fr.id = dl.request_id
               WHERE dl.budget_item_id = bi.id
                 AND dl.inspector_percent IS NOT NULL
               ORDER BY fr.updated_at DESC
               LIMIT 1
             ), '') AS percent_complete,
             COALESCE((
               SELECT dl.inspector_risk
               FROM draw_lines dl
               JOIN funding_requests fr ON fr.id = dl.request_id
               WHERE dl.budget_item_id = bi.id AND dl.inspector_risk <> ''
               ORDER BY fr.updated_at DESC
               LIMIT 1
             ), '') AS risk
      FROM budget_items bi
      WHERE bi.project_id = @id::uuid
      ORDER BY bi.budget_side, bi.title
    '''),
    parameters: {'id': id},
  );
  final draws = await db.pool.execute(
    Sql.named('''
      SELECT id::text, draw_name, status, final_draw,
             to_char(amount, 'FM999999999999990.00') AS amount,
             COALESCE(
               (
                 SELECT to_char(SUM(dl.requested), 'FM999999999999990.00')
                 FROM draw_lines dl
                 WHERE dl.request_id = funding_requests.id
               ),
               COALESCE(to_char(requested_amount, 'FM999999999999990.00'), '')
             ) AS requested,
             COALESCE(to_char(confirmed_amount, 'FM999999999999990.00'), '') AS confirmed,
             COALESCE((
               SELECT to_char(SUM(inspector_recommend), 'FM999999999999990.00')
               FROM draw_lines WHERE request_id = funding_requests.id
             ), '') AS recommended
      FROM funding_requests
      WHERE project_id = @id::uuid AND draw_name <> ''
      ORDER BY created_at DESC
    '''),
    parameters: {'id': id},
  );
  final inspections = await db.pool.execute(
    Sql.named('''
      SELECT id::text, status, COALESCE(scheduled_on::text, '') AS scheduled_on,
             gate_code, note, COALESCE(request_id::text, '') AS request_id
      FROM inspections WHERE project_id = @id::uuid ORDER BY created_at DESC
    '''),
    parameters: {'id': id},
  );
  final firms = await db.pool.execute(
    Sql.named('''
      SELECT id::text, name,
             COALESCE(insurance_until::text, '') AS insurance_until,
             COALESCE(license_until::text, '') AS license_until
      FROM contractor_firms
      WHERE owner_company_id = (SELECT company_id FROM projects WHERE id = @id::uuid)
      ORDER BY name
    '''),
    parameters: {'id': id},
  );
  if (lines.isEmpty && sources.isEmpty && checklist.isEmpty) {
    return jsonError(404, 'not_found', 'Объект не найден.');
  }
  return jsonResponse(200, {
    'sources': [for (final row in sources) row.toColumnMap()],
    'checklist': [for (final row in checklist) row.toColumnMap()],
    'lines': [for (final row in lines) row.toColumnMap()],
    'draws': [for (final row in draws) row.toColumnMap()],
    'inspections': [for (final row in inspections) row.toColumnMap()],
    'firms': [for (final row in firms) row.toColumnMap()],
  });
}

Future<void> _ensureChecklist(AppDatabase db, String projectId) async {
  const items = [
    ('act', 'Акт выполненных работ', true),
    ('invoice', 'Счёт', true),
    ('retainage_log', 'Ведомость удержания', false),
    ('stored_log', 'Материалы на площадке', false),
    ('waiver', 'Отказ от претензий', true),
  ];
  for (final item in items) {
    await db.pool.execute(
      Sql.named('''
        INSERT INTO checklist_items (project_id, code, title, required)
        VALUES (@project::uuid, @code, @title, @required)
        ON CONFLICT (project_id, code) DO NOTHING
      '''),
      parameters: {
        'project': projectId,
        'code': item.$1,
        'title': item.$2,
        'required': item.$3,
      },
    );
  }
}

Future<Response> _connectBank(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  if (!RegExp(_uuid).hasMatch(id)) return jsonError(404, 'not_found', 'Объект не найден.');
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final inn = (json['inn'] as String? ?? '').trim();
  if (!RegExp(r'^\d{9}$').hasMatch(inn)) {
    return jsonError(400, 'validation', 'Укажите ИНН банка из девяти цифр.');
  }
  final userId = opened as String;
  final allowed = await db.pool.execute(
    Sql.named('''
      SELECT c.name AS developer, c.is_demo AS demo
      FROM projects p
      JOIN companies c ON c.id = p.company_id
      JOIN project_members m ON m.project_id = p.id
      WHERE p.id = @id::uuid AND m.user_id = @user::uuid
        AND m.role IN ('director', 'developer')
    '''),
    parameters: {'id': id, 'user': userId},
  );
  if (allowed.isEmpty) return jsonError(403, 'forbidden', 'Подключить банк может застройщик этого объекта.');
  final gate = allowed.first.toColumnMap();
  final bank = await db.owner.execute(
    Sql.named('''
      SELECT c.id::text
      FROM companies c
      JOIN bank_profiles b ON b.company_id = c.id
      WHERE c.inn = @inn AND c.is_demo = @demo
    '''),
    parameters: {'inn': inn, 'demo': gate['demo'] == true},
  );
  if (bank.isEmpty) return jsonError(404, 'not_found', 'Такого банка в iBuild нет.');
  final linked = await db.owner.execute(
    Sql.named('''
      INSERT INTO project_facilities (project_id, bank_id, developer_name, credit_limit)
      VALUES (@project::uuid, @bank::uuid, @developer, 0)
      ON CONFLICT (project_id, bank_id) DO NOTHING
      RETURNING id::text
    '''),
    parameters: {
      'project': id,
      'bank': bank.first[0],
      'developer': gate['developer'],
    },
  );
  if (linked.isEmpty) return jsonError(409, 'conflict', 'Этот банк уже подключён к объекту.');
  return jsonResponse(201, {'id': linked.first[0], 'bankId': bank.first[0]});
}

Future<Response> _addSource(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final name = (json['name'] as String? ?? '').trim();
  final kind = (json['kind'] as String? ?? '').trim();
  final amount = normalizeMoney(json['amount'] as String? ?? '');
  if (name.isEmpty || !const {'loan', 'equity', 'escrow'}.contains(kind) || amount == null) {
    return jsonError(400, 'validation', 'Укажите источник, вид и сумму.');
  }
  final rows = await db.pool.execute(
    Sql.named('''
      INSERT INTO funding_sources (project_id, name, kind, amount)
      VALUES (@project::uuid, @name, @kind, @amount::numeric)
      RETURNING id::text
    '''),
    parameters: {'project': id, 'name': name, 'kind': kind, 'amount': amount},
  );
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Объект не найден.');
  return jsonResponse(201, {'id': rows.first[0]});
}

Future<Response> _import(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final csv = json['csv'] as String? ?? '';
  final firmId = (json['contractorFirmId'] as String? ?? '').trim();
  if (!RegExp(_uuid).hasMatch(firmId)) {
    return jsonError(400, 'validation', 'Выберите подрядчика для этой работы.');
  }
  final rows = _csv(csv);
  if (rows == null) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  if (await _locked(db, id)) {
    return jsonError(409, 'conflict', 'Бюджет больше нельзя менять: по объекту уже есть отправленный транш.');
  }
  await db.pool.runTx((session) async {
    for (final line in rows) {
      await session.execute(
        Sql.named('''
          INSERT INTO budget_items (
            project_id, title, planned_amount, contractor_company_id,
            cost_code, cost_kind, budget_side, plan_set
          ) VALUES (
            @project::uuid, @title, @amount::numeric, @firm::uuid,
            @code, @kind, @side, true
          )
        '''),
        parameters: {
          'project': id,
          'title': line.title,
          'amount': line.amount,
          'firm': firmId,
          'code': line.code,
          'kind': line.kind,
          'side': line.side,
        },
      );
    }
  });
  return jsonResponse(201, {'imported': rows.length});
}

Future<Response> _copyBudget(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final from = (json['fromProjectId'] as String? ?? '').trim();
  if (!RegExp(_uuid).hasMatch(from)) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  if (await _locked(db, id)) {
    return jsonError(409, 'conflict', 'Бюджет больше нельзя менять: по объекту уже есть отправленный транш.');
  }
  final rows = await db.pool.execute(
    Sql.named('''
      INSERT INTO budget_items (
        project_id, title, planned_amount, contractor_company_id,
        cost_code, cost_kind, budget_side, plan_set
      )
      SELECT @target::uuid, title, planned_amount, contractor_company_id,
             cost_code, cost_kind, budget_side, true
      FROM budget_items WHERE project_id = @from::uuid
      RETURNING id::text
    '''),
    parameters: {'target': id, 'from': from},
  );
  return jsonResponse(201, {'copied': rows.length});
}

Future<Response> _saveTemplate(Request request, AppDatabase db) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final projectId = (json['projectId'] as String? ?? '').trim();
  final name = (json['name'] as String? ?? '').trim();
  if (!RegExp(_uuid).hasMatch(projectId) || name.isEmpty) {
    return jsonError(400, 'validation', 'Напишите название и адрес.');
  }
  final id = await db.pool.runTx((session) async {
    final created = await session.execute(
      Sql.named('''
        INSERT INTO budget_templates (company_id, name)
        SELECT company_id, @name FROM projects WHERE id = @project::uuid
        RETURNING id::text
      '''),
      parameters: {'name': name, 'project': projectId},
    );
    if (created.isEmpty) return null;
    final templateId = created.first[0]! as String;
    await session.execute(
      Sql.named('''
        INSERT INTO budget_template_lines (template_id, cost_code, title, cost_kind, budget_side, amount)
        SELECT @template::uuid, cost_code, title, cost_kind, budget_side, planned_amount
        FROM budget_items WHERE project_id = @project::uuid
      '''),
      parameters: {'template': templateId, 'project': projectId},
    );
    return templateId;
  });
  if (id == null) return jsonError(404, 'not_found', 'Объект не найден.');
  return jsonResponse(201, {'id': id});
}

Future<Response> _applyTemplate(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final templateId = (json['templateId'] as String? ?? '').trim();
  final firmId = (json['contractorFirmId'] as String? ?? '').trim();
  if (!RegExp(_uuid).hasMatch(templateId) || !RegExp(_uuid).hasMatch(firmId)) {
    return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  }
  if (await _locked(db, id)) {
    return jsonError(409, 'conflict', 'Бюджет больше нельзя менять: по объекту уже есть отправленный транш.');
  }
  final rows = await db.pool.execute(
    Sql.named('''
      INSERT INTO budget_items (
        project_id, title, planned_amount, contractor_company_id,
        cost_code, cost_kind, budget_side, plan_set
      )
      SELECT @project::uuid, title, amount, @firm::uuid, cost_code, cost_kind, budget_side, true
      FROM budget_template_lines WHERE template_id = @template::uuid
      RETURNING id::text
    '''),
    parameters: {'project': id, 'firm': firmId, 'template': templateId},
  );
  return jsonResponse(201, {'imported': rows.length});
}

Future<Response> _createDraw(Request request, AppDatabase db) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final userId = opened as String;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final projectId = (json['projectId'] as String? ?? '').trim();
  final name = (json['name'] as String? ?? '').trim();
  if (!RegExp(_uuid).hasMatch(projectId) || name.isEmpty) {
    return jsonError(400, 'validation', 'Напишите название и адрес.');
  }
  await _ensureChecklist(db, projectId);
  final id = await db.pool.runTx((session) async {
    final line = await session.execute(
      Sql.named('''
        SELECT id::text FROM budget_items
        WHERE project_id = @project::uuid AND budget_side = 'use'
        ORDER BY title LIMIT 1
      '''),
      parameters: {'project': projectId},
    );
    if (line.isEmpty) return null;
    final created = await session.execute(
      Sql.named('''
        INSERT INTO funding_requests (
          project_id, budget_item_id, contractor_user_id, author_user_id,
          amount, description, status, draw_name
        ) VALUES (
          @project::uuid, @item::uuid, @user::uuid, @user::uuid,
          0.01, '', 'draft', @name
        )
        RETURNING id::text
      '''),
      parameters: {
        'project': projectId,
        'item': line.first[0],
        'user': userId,
        'name': name,
      },
    );
    final requestId = created.first[0]! as String;
    await session.execute(
      Sql.named('''
        INSERT INTO draw_requirements (request_id, item_id)
        SELECT @request::uuid, id FROM checklist_items WHERE project_id = @project::uuid
      '''),
      parameters: {'request': requestId, 'project': projectId},
    );
    return requestId;
  });
  if (id == null) return jsonError(404, 'not_found', 'Объект не найден.');
  return jsonResponse(201, {'id': id, 'status': 'draft'});
}

Future<Response> _draw(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  return _drawJson(db, id);
}

Future<Response> _drawJson(AppDatabase db, String id) async {
  final head = await db.pool.execute(
    Sql.named('''
      SELECT id::text, project_id::text, draw_name, status, final_draw, version,
             to_char(amount, 'FM999999999999990.00') AS amount,
             COALESCE(to_char(requested_amount, 'FM999999999999990.00'), '') AS requested,
             COALESCE(to_char(confirmed_amount, 'FM999999999999990.00'), '') AS confirmed,
             signed_name
      FROM funding_requests WHERE id = @id::uuid AND draw_name <> ''
    '''),
    parameters: {'id': id},
  );
  if (head.isEmpty) return jsonError(404, 'not_found', 'Транш не найден.');
  final lines = await db.pool.execute(
    Sql.named('''
      SELECT budget_item_id::text, to_char(requested, 'FM999999999999990.00') AS requested,
             to_char(adjustment, 'FM999999999999990.00') AS adjustment,
             to_char(retainage_withheld, 'FM999999999999990.00') AS retainage_withheld,
             to_char(retainage_released, 'FM999999999999990.00') AS retainage_released,
             to_char(stored_materials, 'FM999999999999990.00') AS stored_materials,
             COALESCE(to_char(inspector_percent, 'FM990.00'), '') AS inspector_percent,
             COALESCE(to_char(inspector_recommend, 'FM999999999999990.00'), '') AS inspector_recommend,
             COALESCE(to_char(approved_amount, 'FM999999999999990.00'), '') AS approved_amount,
             comment
      FROM draw_lines WHERE request_id = @id::uuid
    '''),
    parameters: {'id': id},
  );
  final sources = await db.pool.execute(
    Sql.named('''
      SELECT source_id::text, to_char(amount, 'FM999999999999990.00') AS amount
      FROM draw_source_uses WHERE request_id = @id::uuid
    '''),
    parameters: {'id': id},
  );
  final requirements = await db.pool.execute(
    Sql.named('''
      SELECT r.item_id::text, c.code, c.title, c.required, r.status, r.note
      FROM draw_requirements r
      JOIN checklist_items c ON c.id = r.item_id
      WHERE r.request_id = @id::uuid
      ORDER BY c.code
    '''),
    parameters: {'id': id},
  );
  final comments = await db.pool.execute(
    Sql.named('''
      SELECT body, created_at::text AS at FROM draw_comments
      WHERE request_id = @id::uuid ORDER BY created_at
    '''),
    parameters: {'id': id},
  );
  return jsonResponse(200, {
    ...head.first.toColumnMap(),
    'lines': [for (final row in lines) row.toColumnMap()],
    'sources': [for (final row in sources) row.toColumnMap()],
    'requirements': [for (final row in requirements) row.toColumnMap()],
    'comments': [for (final row in comments) row.toColumnMap()],
  });
}

Future<Response> _patchDraw(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final name = (json['name'] as String? ?? '').trim();
  final signed = (json['signedName'] as String? ?? '').trim();
  final finalDraw = json['finalDraw'] == true;
  await db.pool.runTx((session) async {
    await session.execute(
      Sql.named('''
        UPDATE funding_requests
        SET draw_name = CASE WHEN @name = '' THEN draw_name ELSE @name END,
            final_draw = @finalDraw,
            signed_name = CASE WHEN @signed = '' THEN signed_name ELSE @signed END,
            signed_at = CASE WHEN @signed = '' THEN signed_at ELSE now() END,
            version = version + 1,
            updated_at = now()
        WHERE id = @id::uuid AND status = 'draft'
      '''),
      parameters: {'id': id, 'name': name, 'finalDraw': finalDraw, 'signed': signed},
    );
    final lines = json['lines'];
    if (lines is List) {
      for (final raw in lines) {
        final line = raw as Map<String, dynamic>;
        final item = (line['budgetItemId'] as String? ?? '').trim();
        if (!RegExp(_uuid).hasMatch(item)) continue;
        await session.execute(
          Sql.named('''
            INSERT INTO draw_lines (
              request_id, budget_item_id, requested, adjustment,
              retainage_withheld, retainage_released, stored_materials, comment
            ) VALUES (
              @request::uuid, @item::uuid, @requested::numeric, @adjustment::numeric,
              @withheld::numeric, @released::numeric, @stored::numeric, @comment
            )
            ON CONFLICT (request_id, budget_item_id) DO UPDATE SET
              requested = EXCLUDED.requested,
              adjustment = EXCLUDED.adjustment,
              retainage_withheld = EXCLUDED.retainage_withheld,
              retainage_released = EXCLUDED.retainage_released,
              stored_materials = EXCLUDED.stored_materials,
              comment = EXCLUDED.comment
          '''),
          parameters: {
            'request': id,
            'item': item,
            'requested': _nonNegative(line['requested']),
            'adjustment': _signed(line['adjustment']),
            'withheld': _nonNegative(line['retainageWithheld']),
            'released': _nonNegative(line['retainageReleased']),
            'stored': _nonNegative(line['storedMaterials']),
            'comment': (line['comment'] as String? ?? '').trim(),
          },
        );
      }
    }
    final sources = json['sources'];
    if (sources is List) {
      for (final raw in sources) {
        final source = raw as Map<String, dynamic>;
        final sourceId = (source['sourceId'] as String? ?? '').trim();
        if (!RegExp(_uuid).hasMatch(sourceId)) continue;
        await session.execute(
          Sql.named('''
            INSERT INTO draw_source_uses (request_id, source_id, amount)
            VALUES (@request::uuid, @source::uuid, @amount::numeric)
            ON CONFLICT (request_id, source_id) DO UPDATE SET amount = EXCLUDED.amount
          '''),
          parameters: {
            'request': id,
            'source': sourceId,
            'amount': _nonNegative(source['amount']),
          },
        );
      }
    }
    final requirements = json['requirements'];
    if (requirements is List) {
      for (final raw in requirements) {
        final item = raw as Map<String, dynamic>;
        final itemId = (item['itemId'] as String? ?? '').trim();
        final status = (item['status'] as String? ?? '').trim();
        if (!RegExp(_uuid).hasMatch(itemId)) continue;
        if (!const {'missing', 'attached', 'na', 'resolved'}.contains(status)) continue;
        await session.execute(
          Sql.named('''
            UPDATE draw_requirements
            SET status = @status, note = @note
            WHERE request_id = @request::uuid AND item_id = @item::uuid
          '''),
          parameters: {
            'request': id,
            'item': itemId,
            'status': status,
            'note': (item['note'] as String? ?? '').trim(),
          },
        );
      }
    }
  });
  return _drawJson(db, id);
}

Future<Response> _submitDraw(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final userId = opened as String;
  final balanced = await db.pool.execute(
    Sql.named('''
      SELECT
        COALESCE((SELECT SUM(amount) FROM draw_source_uses WHERE request_id = @id::uuid), 0)
          = COALESCE((
            SELECT SUM(requested - retainage_withheld + retainage_released)
            FROM draw_lines WHERE request_id = @id::uuid
          ), 0) AS fits,
        COALESCE((
          SELECT SUM(requested - retainage_withheld + retainage_released)
          FROM draw_lines WHERE request_id = @id::uuid
        ), 0) > 0 AS positive,
        COALESCE((
          SELECT signed_name <> '' FROM funding_requests WHERE id = @id::uuid
        ), false) AS signed,
        NOT EXISTS (
          SELECT 1 FROM draw_requirements r
          JOIN checklist_items c ON c.id = r.item_id
          WHERE r.request_id = @id::uuid AND c.required AND r.status = 'missing'
        ) AS ready
    '''),
    parameters: {'id': id},
  );
  if (balanced.isEmpty) return jsonError(404, 'not_found', 'Транш не найден.');
  final map = balanced.first.toColumnMap();
  if (map['signed'] != true) return jsonError(400, 'validation', 'Подпишите транш перед отправкой.');
  if (map['ready'] != true) return jsonError(400, 'validation', 'Добавьте обязательные документы.');
  if (map['positive'] != true || map['fits'] != true) {
    if (map['positive'] == true && map['fits'] != true) {
      final sources = await db.pool.execute(
        Sql.named('''
          SELECT 1 FROM funding_sources
          WHERE project_id = (SELECT project_id FROM funding_requests WHERE id = @id::uuid)
          LIMIT 1
        '''),
        parameters: {'id': id},
      );
      if (sources.isEmpty) {
        final roles = await db.pool.execute(
          Sql.named('''
            SELECT m.role FROM project_members m
            JOIN funding_requests fr ON fr.project_id = m.project_id
            WHERE fr.id = @id::uuid AND m.user_id = @user::uuid
          '''),
          parameters: {'id': id, 'user': userId},
        );
        final role = roles.isEmpty ? '' : roles.first[0]! as String;
        if (role == 'director' || role == 'developer') {
          return jsonError(
            409,
            'no_sources',
            'На объекте ещё нет источников денег. Добавьте источник в бюджете объекта, затем отправьте транш.',
          );
        }
        return jsonError(
          409,
          'no_sources',
          'Источники денег задаёт застройщик в бюджете объекта. Попросите добавить источник, затем отправьте транш.',
        );
      }
    }
    return jsonError(409, 'over_limit', 'Сумма источников не совпадает с суммой транша.');
  }
  final outcome = await db.pool.runTx((session) async {
    await session.execute(
      Sql.named('''
        SELECT bi.id
        FROM budget_items bi
        JOIN draw_lines dl ON dl.budget_item_id = bi.id
        WHERE dl.request_id = @id::uuid
        FOR UPDATE OF bi
      '''),
      parameters: {'id': id},
    );
    final over = await session.execute(
      Sql.named('''
        SELECT 1
        FROM draw_lines dl
        JOIN budget_items bi ON bi.id = dl.budget_item_id
        WHERE dl.request_id = @id::uuid
          AND (dl.requested - dl.retainage_withheld + dl.retainage_released)
              + line_hold(bi.id, ARRAY['submitted', 'tech_approved', 'approved', 'paid'])
              > bi.planned_amount
      '''),
      parameters: {'id': id},
    );
    if (over.isNotEmpty) return 'over';
    final updated = await session.execute(
      Sql.named('''
        UPDATE funding_requests
        SET requested_amount = (
              SELECT COALESCE(SUM(requested), 0) FROM draw_lines WHERE request_id = funding_requests.id
            ),
            amount = (
              SELECT COALESCE(SUM(requested - retainage_withheld + retainage_released), 0)
              FROM draw_lines WHERE request_id = funding_requests.id
            ),
            status = 'submitted',
            version = version + 1,
            updated_at = now(),
            tranche_no = COALESCE(tranche_no, next_tranche_no(project_id))
        WHERE id = @id::uuid AND status = 'draft' AND author_user_id = @user::uuid
        RETURNING id::text
      '''),
      parameters: {'id': id, 'user': userId},
    );
    if (updated.isEmpty) return 'conflict';
    await session.execute(
      Sql.named('''
        INSERT INTO audit_events (project_id, request_id, action, old_status, new_status, author_user_id, amount)
        SELECT project_id, id, 'submitted', 'draft', 'submitted', @user::uuid, amount
        FROM funding_requests WHERE id = @id::uuid
      '''),
      parameters: {'id': id, 'user': userId},
    );
    return 'ok';
  });
  if (outcome == 'over') {
    return jsonError(409, 'over_limit', 'Сумма больше, чем можно запросить.');
  }
  if (outcome != 'ok') return jsonError(409, 'conflict', 'Транш уже изменили. Обновите страницу.');
  return _drawJson(db, id);
}

Future<Response> _decide(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final lines = json['lines'];
  if (lines is! List) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  await db.pool.runTx((session) async {
    for (final raw in lines) {
      final line = raw as Map<String, dynamic>;
      final item = (line['budgetItemId'] as String? ?? '').trim();
      final approved = normalizeMoney(line['approved'] as String? ?? '');
      if (!RegExp(_uuid).hasMatch(item) || approved == null) continue;
      await session.execute(
        Sql.named('''
          UPDATE draw_lines SET approved_amount = @approved::numeric
          WHERE request_id = @request::uuid AND budget_item_id = @item::uuid
        '''),
        parameters: {'request': id, 'item': item, 'approved': approved},
      );
    }
    await session.execute(
      Sql.named('''
        UPDATE funding_requests
        SET confirmed_amount = (
          SELECT COALESCE(SUM(approved_amount), 0) FROM draw_lines
          WHERE request_id = funding_requests.id AND approved_amount IS NOT NULL
        ),
        version = version + 1,
        updated_at = now()
        WHERE id = @id::uuid AND status = 'tech_approved'
      '''),
      parameters: {'id': id},
    );
  });
  return _drawJson(db, id);
}

Future<Response> _inspect(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final userId = opened as String;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final requestId = (json['requestId'] as String? ?? '').trim();
  final gate = (json['gateCode'] as String? ?? '').trim();
  final note = (json['note'] as String? ?? '').trim();
  final when = (json['scheduledOn'] as String? ?? '').trim();
  final lines = json['lines'];
  if (lines is! List) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final inspectionId = await db.pool.runTx((session) async {
    final created = await session.execute(
      Sql.named('''
        INSERT INTO inspections (
          project_id, request_id, scheduled_on, gate_code, note, status, author_user_id
        ) VALUES (
          @project::uuid, NULLIF(@request, '')::uuid, NULLIF(@when, '')::date,
          @gate, @note, 'reported', @user::uuid
        )
        RETURNING id::text
      '''),
      parameters: {
        'project': id,
        'request': requestId,
        'when': when,
        'gate': gate,
        'note': note,
        'user': userId,
      },
    );
    if (created.isEmpty) return null;
    final inspection = created.first[0]! as String;
    for (final raw in lines) {
      final line = raw as Map<String, dynamic>;
      final item = (line['budgetItemId'] as String? ?? '').trim();
      final percent = _nonNegative(line['percent']);
      final recommend = _nonNegative(line['recommend']);
      if (!RegExp(_uuid).hasMatch(item)) continue;
      await session.execute(
        Sql.named('''
          INSERT INTO inspection_lines (
            inspection_id, budget_item_id, percent, recommend, comment, risk
          ) VALUES (
            @inspection::uuid, @item::uuid, @percent::numeric, @recommend::numeric, @comment, @risk
          )
        '''),
        parameters: {
          'inspection': inspection,
          'item': item,
          'percent': percent,
          'recommend': recommend,
          'comment': (line['comment'] as String? ?? '').trim(),
          'risk': _risk(line['risk']),
        },
      );
      if (RegExp(_uuid).hasMatch(requestId)) {
        await session.execute(
          Sql.named('''
            UPDATE draw_lines
            SET inspector_percent = @percent::numeric,
                inspector_recommend = @recommend::numeric,
                inspector_comment = @comment,
                inspector_risk = @risk
            WHERE request_id = @request::uuid AND budget_item_id = @item::uuid
          '''),
          parameters: {
            'percent': percent,
            'recommend': recommend,
            'comment': (line['comment'] as String? ?? '').trim(),
            'risk': _risk(line['risk']),
            'request': requestId,
            'item': item,
          },
        );
      }
    }
    return inspection;
  });
  if (inspectionId == null) return jsonError(404, 'not_found', 'Объект не найден.');
  return jsonResponse(201, {'id': inspectionId, 'status': 'reported'});
}

Future<Response> _comment(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final userId = opened as String;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final body = (json['body'] as String? ?? '').trim();
  if (body.isEmpty) return jsonError(400, 'validation', 'Напишите причину.');
  final rows = await db.pool.execute(
    Sql.named('''
      INSERT INTO draw_comments (request_id, author_user_id, body)
      VALUES (@request::uuid, @user::uuid, @body)
      RETURNING id::text
    '''),
    parameters: {'request': id, 'user': userId, 'body': body},
  );
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Транш не найден.');
  return jsonResponse(201, {'id': rows.first[0]});
}

Future<Response> _payable(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final item = (json['budgetItemId'] as String? ?? '').trim();
  final firm = (json['firmId'] as String? ?? '').trim();
  final number = (json['number'] as String? ?? '').trim();
  final amount = normalizeMoney(json['amount'] as String? ?? '');
  final waiver = (json['waiver'] as String? ?? 'missing').trim();
  if (!RegExp(_uuid).hasMatch(item) || !RegExp(_uuid).hasMatch(firm) || number.isEmpty || amount == null) {
    return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  }
  if (!const {'missing', 'signed'}.contains(waiver)) {
    return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  }
  final rows = await db.pool.execute(
    Sql.named('''
      INSERT INTO payables (request_id, budget_item_id, firm_id, number, amount, waiver)
      VALUES (@request::uuid, @item::uuid, @firm::uuid, @number, @amount::numeric, @waiver)
      RETURNING id::text
    '''),
    parameters: {
      'request': id,
      'item': item,
      'firm': firm,
      'number': number,
      'amount': amount,
      'waiver': waiver,
    },
  );
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Транш не найден.');
  return jsonResponse(201, {'id': rows.first[0]});
}

Future<Response> _package(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final card = await _drawJson(db, id);
  if (card.statusCode != 200) return card;
  final body = jsonDecode(await card.readAsString()) as Map<String, dynamic>;
  final buffer = StringBuffer()
    ..writeln('Транш «${body['draw_name']}»')
    ..writeln('Статус: ${body['status']}')
    ..writeln('Запрошено, сум: ${body['requested']}')
    ..writeln('К выплате, сум: ${body['amount']}')
    ..writeln('Одобрено банком, сум: ${body['confirmed']}')
    ..writeln('Подписал: ${body['signed_name']}')
    ..writeln('--- Вид работ по строкам ---');
  for (final line in body['lines'] as List) {
    final row = line as Map<String, dynamic>;
    buffer.writeln(
      '${row['budget_item_id']}: запрошено ${row['requested']}, '
      'удержано ${row['retainage_withheld']}, возвращено ${row['retainage_released']}, '
      'материалы на складе ${row['stored_materials']}, '
      'рекомендация проверяющего ${row['inspector_recommend']}, '
      'решение банка ${row['approved_amount']}',
    );
  }
  buffer.writeln('--- Комментарии ---');
  for (final comment in body['comments'] as List) {
    buffer.writeln((comment as Map<String, dynamic>)['body']);
  }
  return Response.ok(
    buffer.toString(),
    headers: {
      'content-type': 'text/plain; charset=utf-8',
      'content-disposition': 'attachment; filename="draw-package.txt"',
    },
  );
}

Future<Response> _compliance(Request request, AppDatabase db, String id) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final parsed = await _body(request);
  if (parsed is Response) return parsed;
  final json = parsed as Map<String, dynamic>;
  final insurance = (json['insuranceUntil'] as String? ?? '').trim();
  final license = (json['licenseUntil'] as String? ?? '').trim();
  final rows = await db.pool.execute(
    Sql.named('''
      UPDATE contractor_firms
      SET insurance_until = NULLIF(@insurance, '')::date,
          license_until = NULLIF(@license, '')::date
      WHERE id = @id::uuid
      RETURNING id::text
    '''),
    parameters: {'id': id, 'insurance': insurance, 'license': license},
  );
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Подрядчик не найден.');
  return jsonResponse(200, {'id': rows.first[0]});
}

Future<Response> _notices(Request request, AppDatabase db) async {
  final opened = await _user(request, db);
  if (opened is Response) return opened;
  final userId = opened as String;
  final waiting = await db.pool.execute(
    Sql.named('''
      SELECT fr.id::text AS id,
             p.name AS project,
             bi.title AS line,
             to_char(fr.amount, 'FM999999999999990.00') AS amount,
             fr.status AS status
      FROM funding_requests fr
      JOIN projects p ON p.id = fr.project_id
      JOIN budget_items bi ON bi.id = fr.budget_item_id
      LEFT JOIN project_members m
        ON m.project_id = p.id AND m.user_id = @user::uuid
      WHERE (
          EXISTS (
            SELECT 1 FROM users u
            WHERE u.id = @user::uuid AND u.platform_admin
          )
          AND fr.status IN ('draft', 'submitted', 'approved', 'rejected')
        )
        OR (
          m.user_id IS NOT NULL
          AND (
            (
              m.role IN ('director', 'contractor', 'developer')
              AND fr.status IN ('draft', 'rejected')
              AND fr.contractor_user_id = @user::uuid
            )
            OR (m.role = 'observer' AND fr.status IN ('submitted', 'approved'))
            OR (m.role = 'tech' AND fr.status = 'submitted')
          )
        )
      ORDER BY fr.updated_at DESC
    '''),
    parameters: {'user': userId},
  );
  final expiring = await db.pool.execute(
    Sql.named('''
      SELECT name,
             COALESCE(insurance_until::text, '') AS insurance_until,
             COALESCE(license_until::text, '') AS license_until
      FROM contractor_firms
      WHERE owner_company_id = (SELECT company_id FROM users WHERE id = @user::uuid)
        AND (
          (insurance_until IS NOT NULL AND insurance_until < now() + interval '30 days')
          OR (license_until IS NOT NULL AND license_until < now() + interval '30 days')
        )
    '''),
    parameters: {'user': userId},
  );
  return jsonResponse(200, {
    'queue': [for (final row in waiting) row.toColumnMap()],
    'compliance': [for (final row in expiring) row.toColumnMap()],
  });
}

Future<bool> _locked(AppDatabase db, String projectId) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT 1 FROM funding_requests
      WHERE project_id = @id::uuid AND status <> 'draft'
      LIMIT 1
    '''),
    parameters: {'id': projectId},
  );
  return rows.isNotEmpty;
}

Future<Object> _body(Request request) async {
  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  return body as Map<String, dynamic>;
}

String _risk(Object? raw) {
  final value = (raw as String? ?? '').trim();
  if (const {'ok', 'watch', 'high'}.contains(value)) return value;
  return '';
}

String _nonNegative(Object? raw) {
  final text = (raw as String? ?? '').trim();
  if (text.isEmpty || text == '0' || text == '0.00') return moneyZero;
  return normalizeMoney(text) ?? moneyZero;
}

String _signed(Object? raw) {
  final text = (raw as String? ?? '').trim();
  if (text.isEmpty || text == '0' || text == '0.00') return moneyZero;
  if (text.startsWith('-')) {
    final value = normalizeMoney(text.substring(1));
    if (value == null) return moneyZero;
    return '-$value';
  }
  return normalizeMoney(text) ?? moneyZero;
}

class _CsvLine {
  _CsvLine(this.code, this.title, this.kind, this.side, this.amount);
  final String code;
  final String title;
  final String kind;
  final String side;
  final String amount;
}

List<_CsvLine>? _csv(String raw) {
  final rows = <_CsvLine>[];
  for (final line in const LineSplitter().convert(raw)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('code')) continue;
    final parts = trimmed.split(',');
    if (parts.length < 5) return null;
    final amount = normalizeMoney(parts[4]);
    final kind = parts[2].trim();
    final side = parts[3].trim();
    if (amount == null) return null;
    if (!const {'hard', 'soft', 'contingency'}.contains(kind)) return null;
    if (!const {'use', 'source'}.contains(side)) return null;
    rows.add(_CsvLine(parts[0].trim(), parts[1].trim(), kind, side, amount));
  }
  if (rows.isEmpty) return null;
  return rows;
}
