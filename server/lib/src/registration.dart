import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'db.dart';
import 'env.dart';
import 'http_util.dart';
import 'passwords.dart';
import 'bank_rules_api.dart' show ensureBankDefaults;
import 'registration_spec.dart';
import 'requests.dart' show sniff, photoMaxBytes, pdfMaxBytes;

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

const _openStatuses = ['new', 'calling', 'docs_requested', 'in_review'];
const _settableStatuses = ['calling', 'docs_requested', 'in_review', 'rejected'];
const _callOutcomes = ['reached', 'no_answer', 'busy', 'call_later', 'wrong_number'];
const _maxFilesPerType = 5;
const _maxFilesTotal = 40;

/// Public sign-up and the platform admin's CRM for it.
///
/// Everything here talks to the database as its owner: the tables hold passport
/// and tax numbers and the app role has no grant on them. The admin routes
/// check `platform_admin` before doing anything.
void mountRegistration(Router router, AppDatabase db, AppEnv env) {
  final limiter = _Limiter(env.registrationPerHour);
  router
    ..post('/api/applications', (Request r) => _submit(r, db, env, limiter))
    ..get('/api/applications/status', (Request r) => _publicStatus(r, db))
    ..post('/api/applications/<id>/documents', (Request r, String id) => _upload(r, db, env, id))
    ..get('/api/admin/applications', (Request r) => _list(r, db))
    ..get('/api/admin/applications/<id>', (Request r, String id) => _detail(r, db, id))
    ..post('/api/admin/applications/<id>/status', (Request r, String id) => _setStatus(r, db, id))
    ..post('/api/admin/applications/<id>/calls', (Request r, String id) => _logCall(r, db, id))
    ..post('/api/admin/applications/<id>/notes', (Request r, String id) => _addNote(r, db, id))
    ..post('/api/admin/applications/<id>/checks', (Request r, String id) => _setCheck(r, db, id))
    ..post('/api/admin/applications/<id>/approve', (Request r, String id) => _approve(r, db, id))
    ..get('/api/admin/applications/<id>/documents/<docId>', (Request r, String id, String docId) => _document(r, db, id, docId));
}

class _Limiter {
  _Limiter(this.perHour);

  final int perHour;
  final _hits = <String, List<DateTime>>{};

  bool allow(String key) {
    final now = DateTime.now();
    final recent = (_hits[key] ?? const <DateTime>[])
        .where((time) => now.difference(time) < const Duration(hours: 1))
        .toList();
    if (recent.length >= perHour) {
      _hits[key] = recent;
      return false;
    }
    recent.add(now);
    _hits[key] = recent;
    if (_hits.length > 5000) _hits.removeWhere((_, value) => value.isEmpty);
    return true;
  }
}

String _code(int seq) => 'IB-${seq.toString().padLeft(5, '0')}';

bool _isUuid(String value) => _uuidPattern.hasMatch(value);

Future<Object> _readBody(Request request, {int limit = 100000}) async {
  final limited = await readAtMost(request.read(), limit);
  if (limited.overflow) return 'too_large';
  final raw = utf8.decode(limited.bytes);
  if (raw.length > limit) return 'too_large';
  if (raw.trim().isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return decoded.map((key, value) => MapEntry(key.toString(), value));
  } catch (_) {
    return 'invalid';
  }
  return 'invalid';
}

Response _badBody() => jsonError(
  400,
  'validation',
  'Не получилось обработать запрос. Проверьте данные и попробуйте снова.',
);

String _clientKey(Request request, AppEnv env) => clientAddress(request, trustProxy: env.trustProxy);

// ── Public side ──────────────────────────────────────────────────────────

Future<Response> _submit(Request request, AppDatabase db, AppEnv env, _Limiter limiter) async {
  final header = request.headers['x-csrf-token'] ?? '';
  final cookieToken = readCookies(request)[csrfCookieName] ?? '';
  if (header.isEmpty || cookieToken.isEmpty || !tokensEqual(header, cookieToken)) {
    return jsonError(403, 'csrf', 'Сессия устарела. Обновите страницу и попробуйте снова.');
  }
  final body = await _readBody(request);
  if (body is String) return _badBody();
  final json = body as Map<String, dynamic>;

  final kind = json['kind'];
  if (kind != 'developer' && kind != 'bank') return _badBody();

  // A real person never fills the hidden field. Pretend it worked.
  final trap = json['website_url'];
  if (trap is String && trap.trim().isNotEmpty) {
    return jsonResponse(201, {'id': '', 'code': _code(0), 'token': randomToken()});
  }

  if (!limiter.allow(_clientKey(request, env))) {
    return jsonError(429, 'rate_limited', 'Слишком много заявок с этого адреса. Попробуйте позже.');
  }

  final consents = json['consents'];
  if (consents is! List ||
      !consents.contains('personal_data') ||
      !consents.contains('truth')) {
    return jsonResponse(400, {
      'error': 'validation',
      'message': 'Нужно согласие на обработку данных и подтверждение, что сведения верны.',
      'field': 'consents',
    });
  }

  final form = readForm(kind as String, json['data']);
  if (form.error != null) {
    return jsonResponse(400, {
      'error': 'validation',
      'message': 'Проверьте заполнение формы.',
      'field': form.error,
    });
  }
  final data = form.data;
  final inn = data['inn']! as String;

  final taken = await db.owner.execute(
    Sql.named('SELECT 1 FROM companies WHERE inn = @inn'),
    parameters: {'inn': inn},
  );
  if (taken.isNotEmpty && kind == 'developer') {
    return jsonError(409, 'conflict', 'Организация с таким ИНН уже работает в iBuild.');
  }

  final token = randomToken();
  try {
    final inserted = await db.owner.runTx((session) async {
      final rows = await session.execute(
        Sql.named('''
          INSERT INTO applications (
            kind, org_name, inn, contact_name, phone, email, region, data,
            token_hash, consent_at, consent_version
          )
          VALUES (
            @kind, @org, @inn, @contact, @phone, @email, @region, @data::text::jsonb,
            @hash, now(), @version
          )
          RETURNING id::text, seq
        '''),
        parameters: {
          'kind': kind,
          'org': data['org_full_name'],
          'inn': inn,
          'contact': data['contact_name'],
          'phone': data['contact_phone'],
          'email': data['contact_email'],
          'region': data['region'] ?? '',
          'data': jsonEncode(data),
          'hash': sha256Hex(token),
          'version': consentVersion,
        },
      );
      await session.execute(
        Sql.named('''
          INSERT INTO application_events (application_id, kind)
          VALUES (@id::uuid, 'created')
        '''),
        parameters: {'id': rows.first[0]},
      );
      return rows.first;
    });
    return jsonResponse(201, {
      'id': inserted[0]! as String,
      'code': _code(inserted[1]! as int),
      'token': token,
    });
  } on ServerException catch (error) {
    if (error.code == '23505') {
      return jsonError(409, 'conflict', 'Заявка от этой организации уже на проверке.');
    }
    rethrow;
  }
}

Future<Map<String, Object?>?> _byToken(Request request, AppDatabase db, {String? id}) async {
  final token = request.headers['x-application-token'] ?? '';
  if (token.isEmpty || token.length > 200) return null;
  final rows = await db.owner.execute(
    Sql.named('''
      SELECT id::text, kind, status, seq, org_name, docs_request_note, decision_note, created_at
      FROM applications
      WHERE token_hash = @hash AND (@id = '' OR id::text = @id)
    '''),
    parameters: {'hash': sha256Hex(token), 'id': id ?? ''},
  );
  if (rows.isEmpty) return null;
  final row = rows.first;
  return {
    'id': row[0],
    'kind': row[1],
    'status': row[2],
    'seq': row[3],
    'orgName': row[4],
    'docsNote': row[5],
    'decisionNote': row[6],
    'createdAt': (row[7]! as DateTime).toUtc().toIso8601String(),
  };
}

Future<List<Map<String, Object?>>> _documentsOf(AppDatabase db, String id) async {
  final rows = await db.owner.execute(
    Sql.named('''
      SELECT id::text, doc_type, file_name, size_bytes, created_at
      FROM application_documents
      WHERE application_id = @id::uuid
      ORDER BY created_at
    '''),
    parameters: {'id': id},
  );
  return [
    for (final row in rows)
      {
        'id': row[0],
        'type': row[1],
        'name': row[2],
        'size': row[3],
        'createdAt': (row[4]! as DateTime).toUtc().toIso8601String(),
      },
  ];
}

List<String> _missingDocs(String kind, List<Map<String, Object?>> documents) {
  final have = {for (final doc in documents) doc['type']! as String};
  return [
    for (final rule in docsFor(kind))
      if (rule.required && !have.contains(rule.type)) rule.type,
  ];
}

Future<Response> _publicStatus(Request request, AppDatabase db) async {
  final found = await _byToken(request, db);
  if (found == null) return jsonError(404, 'not_found', 'Заявка не найдена. Проверьте ссылку.');
  final documents = await _documentsOf(db, found['id']! as String);
  final status = found['status']! as String;
  return jsonResponse(200, {
    'id': found['id'],
    'code': _code(found['seq']! as int),
    'kind': found['kind'],
    'status': status,
    'orgName': found['orgName'],
    'createdAt': found['createdAt'],
    'requestNote': status == 'docs_requested' ? found['docsNote'] : '',
    'decisionNote': status == 'rejected' ? found['decisionNote'] : '',
    'documents': [
      for (final doc in documents) {'id': doc['id'], 'type': doc['type'], 'name': doc['name']},
    ],
    'missing': _missingDocs(found['kind']! as String, documents),
    'canUpload': _openStatuses.contains(status),
  });
}

String _cleanFileName(String raw) {
  var name = raw.replaceAll(RegExp(r'[\\/\x00-\x1f]'), '_').trim();
  if (name.isEmpty) name = 'document';
  if (name.length > 120) name = name.substring(name.length - 120);
  return name;
}

Future<Response> _upload(Request request, AppDatabase db, AppEnv env, String id) async {
  if (!_isUuid(id)) return jsonError(404, 'not_found', 'Заявка не найдена. Проверьте ссылку.');
  final header = request.headers['x-csrf-token'] ?? '';
  final cookieToken = readCookies(request)[csrfCookieName] ?? '';
  if (header.isEmpty || cookieToken.isEmpty || !tokensEqual(header, cookieToken)) {
    return jsonError(403, 'csrf', 'Сессия устарела. Обновите страницу и попробуйте снова.');
  }
  final found = await _byToken(request, db, id: id);
  if (found == null) return jsonError(404, 'not_found', 'Заявка не найдена. Проверьте ссылку.');
  final status = found['status']! as String;
  if (!_openStatuses.contains(status)) {
    return jsonError(409, 'conflict', 'Заявка закрыта, документы больше не принимаются.');
  }
  final kind = found['kind']! as String;
  final type = request.url.queryParameters['type'] ?? '';
  if (!docsFor(kind).any((rule) => rule.type == type)) {
    return jsonError(400, 'validation', 'Такого документа нет в списке.');
  }

  final counts = await db.owner.execute(
    Sql.named('''
      SELECT count(*)::int, count(*) FILTER (WHERE doc_type = @type)::int
      FROM application_documents WHERE application_id = @id::uuid
    '''),
    parameters: {'id': id, 'type': type},
  );
  if ((counts.first[0]! as int) >= _maxFilesTotal || (counts.first[1]! as int) >= _maxFilesPerType) {
    return jsonError(400, 'validation', 'Слишком много файлов. Удалите лишние или объедините их в один PDF.');
  }

  final limited = await readAtMost(request.read(), pdfMaxBytes);
  if (limited.overflow) return jsonError(400, 'validation', 'Файл больше 10 МБ.');
  final bytes = limited.bytes;
  if (bytes.isEmpty) return jsonError(400, 'validation', 'Добавьте файл.');
  final detected = sniff(bytes);
  if (detected == null) {
    return jsonError(400, 'validation', 'Подойдёт фото (JPEG, PNG, WebP) или PDF.');
  }
  if (detected.kind == 'photo' && bytes.length > photoMaxBytes) {
    return jsonError(400, 'validation', 'Фото больше 5 МБ.');
  }

  final name = _cleanFileName(request.url.queryParameters['name'] ?? '');
  final root = env.fileRoot.replaceAll(RegExp(r'/+$'), '');
  final idRow = await db.owner.execute('SELECT gen_random_uuid()::text');
  final docId = idRow.first[0]! as String;
  final path = '$root/applications/$id/$docId';
  try {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  } catch (_) {
    return jsonError(500, 'storage', 'Не удалось сохранить файл.');
  }
  await db.owner.runTx((session) async {
    await session.execute(
      Sql.named('''
        INSERT INTO application_documents (
          id, application_id, doc_type, file_name, content_type, size_bytes, storage_path
        )
        VALUES (@doc::uuid, @id::uuid, @type, @name, @mime, @size, @path)
      '''),
      parameters: {
        'doc': docId,
        'id': id,
        'type': type,
        'name': name,
        'mime': detected.type,
        'size': bytes.length,
        'path': path,
      },
    );
    if (status != 'new') {
      await session.execute(
        Sql.named('''
          INSERT INTO application_events (application_id, kind, body)
          VALUES (@id::uuid, 'document', @type)
        '''),
        parameters: {'id': id, 'type': type},
      );
    }
    if (status == 'docs_requested') {
      await session.execute(
        Sql.named('''
          UPDATE applications SET status = 'in_review', updated_at = now()
          WHERE id = @id::uuid
        '''),
        parameters: {'id': id},
      );
    }
  });
  return jsonResponse(201, {'id': docId, 'type': type, 'name': name});
}

// ── Admin side ───────────────────────────────────────────────────────────

Future<Object> _admin(Request request, AppDatabase db, {bool csrf = false}) async {
  final token = readCookies(request)[sessionCookieName];
  if (token == null || token.isEmpty) {
    return jsonError(401, 'unauthenticated', 'Войдите, чтобы продолжить.');
  }
  final lookup = await db.lookupSession(sha256Hex(token));
  if (lookup.state != SessionState.ok || lookup.user == null) {
    return jsonError(401, 'unauthenticated', 'Войдите, чтобы продолжить.');
  }
  if (!lookup.user!.platformAdmin) {
    return jsonError(403, 'forbidden', 'Заявки видит только администратор iBuild.');
  }
  if (csrf) {
    final header = request.headers['x-csrf-token'] ?? '';
    final expected = lookup.csrfToken ?? '';
    if (header.isEmpty || expected.isEmpty || !tokensEqual(header, expected)) {
      return jsonError(403, 'csrf', 'Сессия устарела. Обновите страницу и войдите снова.');
    }
  }
  return lookup;
}

const _listColumns = '''
  a.id::text, a.seq, a.kind, a.status, a.org_name, a.inn, a.contact_name, a.phone,
  a.created_at, a.updated_at, a.next_call_on::text,
  count(d.id)::int AS docs,
  coalesce(array_agg(DISTINCT d.doc_type) FILTER (WHERE d.doc_type IS NOT NULL), '{}') AS types
''';

Future<Response> _list(Request request, AppDatabase db) async {
  final opened = await _admin(request, db);
  if (opened is Response) return opened;
  final demo = (opened as SessionLookup).user!.isDemo;
  final query = request.url.queryParameters;
  final kind = query['kind'] ?? '';
  final status = query['status'] ?? '';
  final search = (query['q'] ?? '').trim();
  if (search.length > 100) return _badBody();

  final seqSearch = RegExp(r'^(?:IB-?)?0*(\d{1,9})$', caseSensitive: false).firstMatch(search);
  final escaped = search.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
  final rows = await db.owner.execute(
    Sql.named('''
      SELECT $_listColumns
      FROM applications a
      LEFT JOIN application_documents d ON d.application_id = a.id
      WHERE a.is_demo = @demo
        AND (@kind = '' OR a.kind = @kind)
        AND (@status = '' OR a.status = @status)
        AND (@q = '' OR a.org_name ILIKE '%' || @q || '%'
             OR a.inn LIKE @q || '%'
             OR a.contact_name ILIKE '%' || @q || '%'
             OR a.phone LIKE '%' || @q || '%'
             OR a.email ILIKE '%' || @q || '%'
             OR (@seq <> '' AND a.seq::text = @seq))
      GROUP BY a.id
      ORDER BY (a.status IN ('approved', 'rejected')), a.created_at DESC
      LIMIT 300
    '''),
    parameters: {
      'kind': kind,
      'status': status,
      'q': escaped,
      'seq': seqSearch?.group(1) ?? '',
      'demo': demo,
    },
  );
  final counted = await db.owner.execute(
    Sql.named('SELECT status, count(*)::int FROM applications WHERE is_demo = @demo GROUP BY status'),
    parameters: {'demo': demo},
  );
  final counts = {
    for (final name in ['new', 'calling', 'docs_requested', 'in_review', 'approved', 'rejected'])
      name: 0,
  };
  for (final row in counted) {
    counts[row[0]! as String] = row[1]! as int;
  }
  return jsonResponse(200, {
    'counts': counts,
    'items': [for (final row in rows) _listItem(row)],
  });
}

Map<String, Object?> _listItem(ResultRow row) {
  final kind = row[2]! as String;
  final types = (row[12] as List).map((item) => item.toString()).toSet();
  final missing = [
    for (final rule in docsFor(kind))
      if (rule.required && !types.contains(rule.type)) rule.type,
  ];
  return {
    'id': row[0],
    'code': _code(row[1]! as int),
    'kind': kind,
    'status': row[3],
    'orgName': row[4],
    'inn': row[5],
    'contactName': row[6],
    'phone': row[7],
    'createdAt': (row[8]! as DateTime).toUtc().toIso8601String(),
    'updatedAt': (row[9]! as DateTime).toUtc().toIso8601String(),
    'nextCallOn': row[10],
    'documents': row[11],
    'missingDocs': missing.length,
  };
}

Future<Map<String, Object?>?> _detailJson(AppDatabase db, String id) async {
  final rows = await db.owner.execute(
    Sql.named('''
      SELECT a.id::text, a.seq, a.kind, a.status, a.org_name, a.inn, a.contact_name, a.phone,
             a.email, a.region, a.data::text, a.checks::text, a.docs_request_note,
             a.decision_note, a.next_call_on::text, a.created_at, a.updated_at,
             a.consent_at, a.consent_version, a.decided_at, u.name
      FROM applications a
      LEFT JOIN users u ON u.id = a.decided_by
      WHERE a.id = @id::uuid
    '''),
    parameters: {'id': id},
  );
  if (rows.isEmpty) return null;
  final row = rows.first;
  final kind = row[2]! as String;
  final documents = await _documentsOf(db, id);
  final events = await db.owner.execute(
    Sql.named('''
      SELECT e.id, e.kind, e.outcome, e.body, e.created_at, coalesce(u.name, '')
      FROM application_events e
      LEFT JOIN users u ON u.id = e.author_user_id
      WHERE e.application_id = @id::uuid
      ORDER BY e.created_at DESC, e.id DESC
    '''),
    parameters: {'id': id},
  );
  return {
    'id': row[0],
    'code': _code(row[1]! as int),
    'kind': kind,
    'status': row[3],
    'orgName': row[4],
    'inn': row[5],
    'contactName': row[6],
    'phone': row[7],
    'email': row[8],
    'region': row[9],
    'data': jsonDecode(row[10]! as String),
    'checks': jsonDecode(row[11]! as String),
    'checkKeys': checksFor(kind),
    'requestNote': row[12],
    'decisionNote': row[13],
    'nextCallOn': row[14],
    'createdAt': (row[15]! as DateTime).toUtc().toIso8601String(),
    'updatedAt': (row[16]! as DateTime).toUtc().toIso8601String(),
    'consentAt': (row[17]! as DateTime).toUtc().toIso8601String(),
    'consentVersion': row[18],
    'decidedAt': (row[19] as DateTime?)?.toUtc().toIso8601String(),
    'decidedBy': row[20],
    'documents': documents,
    'docRules': [
      for (final rule in docsFor(kind)) {'type': rule.type, 'required': rule.required},
    ],
    'missing': _missingDocs(kind, documents),
    'events': [
      for (final event in events)
        {
          'id': event[0],
          'kind': event[1],
          'outcome': event[2],
          'body': event[3],
          'createdAt': (event[4]! as DateTime).toUtc().toIso8601String(),
          'author': event[5],
        },
    ],
  };
}

Future<Response> _detail(Request request, AppDatabase db, String id) async {
  final opened = await _admin(request, db);
  if (opened is Response) return opened;
  if (!_isUuid(id)) return jsonError(404, 'not_found', 'Заявка не найдена.');
  final world = await db.owner.execute(
    Sql.named('SELECT is_demo FROM applications WHERE id = @id::uuid'),
    parameters: {'id': id},
  );
  if (world.isEmpty || world.first[0] != (opened as SessionLookup).user!.isDemo) {
    return jsonError(404, 'not_found', 'Заявка не найдена.');
  }
  final detail = await _detailJson(db, id);
  if (detail == null) return jsonError(404, 'not_found', 'Заявка не найдена.');
  return jsonResponse(200, detail);
}

/// Loads the application row an admin action works on.
Future<({String kind, String status})?> _target(AppDatabase db, String id) async {
  if (!_isUuid(id)) return null;
  final rows = await db.owner.execute(
    Sql.named('SELECT kind, status FROM applications WHERE id = @id::uuid'),
    parameters: {'id': id},
  );
  if (rows.isEmpty) return null;
  return (kind: rows.first[0]! as String, status: rows.first[1]! as String);
}

Response _closed() => jsonError(409, 'conflict', 'Заявка уже закрыта.');

Future<Response> _setStatus(Request request, AppDatabase db, String id) async {
  final opened = await _admin(request, db, csrf: true);
  if (opened is Response) return opened;
  final admin = (opened as SessionLookup).user!;
  final target = await _target(db, id);
  if (target == null) return jsonError(404, 'not_found', 'Заявка не найдена.');
  if (!_openStatuses.contains(target.status)) return _closed();
  final body = await _readBody(request, limit: 5000);
  if (body is String) return _badBody();
  final json = body as Map<String, dynamic>;
  final status = json['status'];
  final note = (json['note'] as String? ?? '').trim();
  if (status is! String || !_settableStatuses.contains(status)) return _badBody();
  if (note.length > 1000) return _badBody();
  if (status == 'docs_requested' && note.isEmpty) {
    return jsonError(400, 'validation', 'Напишите, какие документы нужны.');
  }
  if (status == 'rejected' && note.isEmpty) {
    return jsonError(400, 'validation', 'Напишите причину отказа.');
  }
  await db.owner.runTx((session) async {
    await session.execute(
      Sql.named('''
        UPDATE applications
        SET status = @status,
            docs_request_note = CASE WHEN @status = 'docs_requested' THEN @note ELSE docs_request_note END,
            decision_note = CASE WHEN @status = 'rejected' THEN @note ELSE decision_note END,
            decided_by = CASE WHEN @status = 'rejected' THEN @admin::uuid ELSE decided_by END,
            decided_at = CASE WHEN @status = 'rejected' THEN now() ELSE decided_at END,
            updated_at = now()
        WHERE id = @id::uuid
      '''),
      parameters: {'id': id, 'status': status, 'note': note, 'admin': admin.id},
    );
    await session.execute(
      Sql.named('''
        INSERT INTO application_events (application_id, author_user_id, kind, outcome, body)
        VALUES (@id::uuid, @admin::uuid, 'status', @status, @note)
      '''),
      parameters: {'id': id, 'admin': admin.id, 'status': status, 'note': note},
    );
  });
  return jsonResponse(200, (await _detailJson(db, id))!);
}

Future<Response> _logCall(Request request, AppDatabase db, String id) async {
  final opened = await _admin(request, db, csrf: true);
  if (opened is Response) return opened;
  final admin = (opened as SessionLookup).user!;
  final target = await _target(db, id);
  if (target == null) return jsonError(404, 'not_found', 'Заявка не найдена.');
  if (!_openStatuses.contains(target.status)) return _closed();
  final body = await _readBody(request, limit: 5000);
  if (body is String) return _badBody();
  final json = body as Map<String, dynamic>;
  final outcome = json['outcome'];
  final note = (json['note'] as String? ?? '').trim();
  final next = (json['nextCallOn'] as String? ?? '').trim();
  if (outcome is! String || !_callOutcomes.contains(outcome)) return _badBody();
  if (note.length > 1000) return _badBody();
  if (next.isNotEmpty && parseDay(next) == null) return _badBody();
  await db.owner.runTx((session) async {
    await session.execute(
      Sql.named('''
        INSERT INTO application_events (application_id, author_user_id, kind, outcome, body)
        VALUES (@id::uuid, @admin::uuid, 'call', @outcome, @note)
      '''),
      parameters: {'id': id, 'admin': admin.id, 'outcome': outcome, 'note': note},
    );
    await session.execute(
      Sql.named('''
        UPDATE applications
        SET next_call_on = @next::text::date,
            status = CASE WHEN status = 'new' THEN 'calling' ELSE status END,
            updated_at = now()
        WHERE id = @id::uuid
      '''),
      parameters: {'id': id, 'next': next.isEmpty ? null : next},
    );
  });
  return jsonResponse(200, (await _detailJson(db, id))!);
}

Future<Response> _addNote(Request request, AppDatabase db, String id) async {
  final opened = await _admin(request, db, csrf: true);
  if (opened is Response) return opened;
  final admin = (opened as SessionLookup).user!;
  final target = await _target(db, id);
  if (target == null) return jsonError(404, 'not_found', 'Заявка не найдена.');
  final body = await _readBody(request, limit: 5000);
  if (body is String) return _badBody();
  final text = ((body as Map<String, dynamic>)['body'] as String? ?? '').trim();
  if (text.isEmpty || text.length > 2000) {
    return jsonError(400, 'validation', 'Напишите заметку, не длиннее 2000 знаков.');
  }
  await db.owner.execute(
    Sql.named('''
      INSERT INTO application_events (application_id, author_user_id, kind, body)
      VALUES (@id::uuid, @admin::uuid, 'note', @body)
    '''),
    parameters: {'id': id, 'admin': admin.id, 'body': text},
  );
  return jsonResponse(200, (await _detailJson(db, id))!);
}

Future<Response> _setCheck(Request request, AppDatabase db, String id) async {
  final opened = await _admin(request, db, csrf: true);
  if (opened is Response) return opened;
  final admin = (opened as SessionLookup).user!;
  final target = await _target(db, id);
  if (target == null) return jsonError(404, 'not_found', 'Заявка не найдена.');
  if (!_openStatuses.contains(target.status)) return _closed();
  final body = await _readBody(request, limit: 2000);
  if (body is String) return _badBody();
  final json = body as Map<String, dynamic>;
  final key = json['key'];
  final done = json['done'];
  if (key is! String || !checksFor(target.kind).contains(key) || done is! bool) {
    return _badBody();
  }
  await db.owner.runTx((session) async {
    await session.execute(
      Sql.named('''
        UPDATE applications
        SET checks = checks || jsonb_build_object(@key::text, @done::boolean),
            updated_at = now()
        WHERE id = @id::uuid
      '''),
      parameters: {'id': id, 'key': key, 'done': done},
    );
    await session.execute(
      Sql.named('''
        INSERT INTO application_events (application_id, author_user_id, kind, outcome, body)
        VALUES (@id::uuid, @admin::uuid, 'check', @outcome, @key)
      '''),
      parameters: {
        'id': id,
        'admin': admin.id,
        'outcome': done ? 'done' : 'undone',
        'key': key,
      },
    );
  });
  return jsonResponse(200, (await _detailJson(db, id))!);
}

const _passwordAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';

String _newPassword() {
  final random = Random.secure();
  return List.generate(10, (_) => _passwordAlphabet[random.nextInt(_passwordAlphabet.length)])
      .join();
}

Future<Response> _approve(Request request, AppDatabase db, String id) async {
  final opened = await _admin(request, db, csrf: true);
  if (opened is Response) return opened;
  final admin = (opened as SessionLookup).user!;
  final target = await _target(db, id);
  if (target == null) return jsonError(404, 'not_found', 'Заявка не найдена.');
  if (!_openStatuses.contains(target.status)) return _closed();

  final detail = (await _detailJson(db, id))!;
  final checks = detail['checks']! as Map;
  final undone = [
    for (final key in checksFor(target.kind))
      if (checks[key] != true) key,
  ];
  if (undone.isNotEmpty) {
    return jsonError(409, 'conflict', 'Отметьте все пункты проверки, прежде чем одобрять.');
  }
  if ((detail['missing']! as List).isNotEmpty) {
    return jsonError(409, 'conflict', 'Не хватает обязательных документов.');
  }

  final data = detail['data']! as Map<String, dynamic>;
  String? login;
  String? password;
  String? companyId;
  String? projectName;

  try {
    await db.owner.runTx((session) async {
      if (target.kind == 'developer') {
        final inn = detail['inn']! as String;
        final email = detail['email']! as String;
        final clash = await session.execute(
          Sql.named('SELECT 1 FROM companies WHERE inn = @inn'),
          parameters: {'inn': inn},
        );
        if (clash.isNotEmpty) throw _Clash('Организация с таким ИНН уже работает в iBuild.');
        final taken = await session.execute(
          Sql.named('SELECT 1 FROM users WHERE login = @login'),
          parameters: {'login': email},
        );
        if (taken.isNotEmpty) throw _Clash('Этот email уже используют как логин. Укажите другой.');

        final company = await session.execute(
          Sql.named('''
            INSERT INTO companies (name, inn, contact)
            VALUES (@name, @inn, @contact)
            RETURNING id::text
          '''),
          parameters: {
            'name': detail['orgName'],
            'inn': inn,
            'contact': '${detail['contactName']}, ${detail['phone']}',
          },
        );
        companyId = company.first[0]! as String;
        password = _newPassword();
        login = email;
        final user = await session.execute(
          Sql.named('''
            INSERT INTO users (company_id, name, login, password_hash, active, must_change_password)
            VALUES (@company::uuid, @name, @login, @hash, true, true)
            RETURNING id::text
          '''),
          parameters: {
            'company': companyId,
            'name': detail['contactName'],
            'login': email,
            'hash': hashPassword(password!),
          },
        );
        projectName = data['object_name']! as String;
        final project = await session.execute(
          Sql.named('''
            INSERT INTO projects (company_id, name, address)
            VALUES (@company::uuid, @name, @address)
            RETURNING id::text
          '''),
          parameters: {
            'company': companyId,
            'name': projectName,
            'address': data['object_address'],
          },
        );
        await session.execute(
          Sql.named('''
            INSERT INTO project_members (project_id, user_id, role)
            VALUES (@project::uuid, @user::uuid, 'director')
          '''),
          parameters: {'project': project.first[0], 'user': user.first[0]},
        );
      }
      if (target.kind == 'bank') {
        final inn = detail['inn']! as String;
        final email = detail['email']! as String;
        final clash = await session.execute(
          Sql.named('SELECT 1 FROM companies WHERE inn = @inn'),
          parameters: {'inn': inn},
        );
        if (clash.isNotEmpty) throw _Clash('Организация с таким ИНН уже работает в iBuild.');
        final taken = await session.execute(
          Sql.named('SELECT 1 FROM users WHERE login = @login'),
          parameters: {'login': email},
        );
        if (taken.isNotEmpty) throw _Clash('Этот email уже используют как логин. Укажите другой.');
        final bank = await session.execute(
          Sql.named('''
            INSERT INTO companies (name, inn, contact)
            VALUES (@name, @inn, @contact)
            RETURNING id::text
          '''),
          parameters: {
            'name': detail['orgName'],
            'inn': inn,
            'contact': '${detail['contactName']}, ${detail['phone']}',
          },
        );
        companyId = bank.first[0]! as String;
        await session.execute(
          Sql.named("INSERT INTO bank_profiles (company_id, department) VALUES (@bank::uuid, '')"),
          parameters: {'bank': companyId},
        );
        password = _newPassword();
        login = email;
        final user = await session.execute(
          Sql.named('''
            INSERT INTO users (company_id, name, login, password_hash, active, must_change_password)
            VALUES (@company::uuid, @name, @login, @hash, true, true)
            RETURNING id::text
          '''),
          parameters: {
            'company': companyId,
            'name': detail['contactName'],
            'login': email,
            'hash': hashPassword(password!),
          },
        );
        await session.execute(
          Sql.named('''
            INSERT INTO bank_staff (bank_id, user_id, role, title, branch)
            VALUES (@bank::uuid, @user::uuid, 'admin', 'Администратор банка', '')
          '''),
          parameters: {'bank': companyId, 'user': user.first[0]},
        );
        await ensureBankDefaults(session, companyId!);
      }
      await session.execute(
        Sql.named('''
          UPDATE applications
          SET status = 'approved', company_id = @company::uuid,
              decided_by = @admin::uuid, decided_at = now(), updated_at = now()
          WHERE id = @id::uuid
        '''),
        parameters: {'id': id, 'company': companyId, 'admin': admin.id},
      );
      await session.execute(
        Sql.named('''
          INSERT INTO application_events (application_id, author_user_id, kind, outcome)
          VALUES (@id::uuid, @admin::uuid, 'approved', @kind)
        '''),
        parameters: {'id': id, 'admin': admin.id, 'kind': target.kind},
      );
    });
  } on _Clash catch (clash) {
    return jsonError(409, 'conflict', clash.message);
  } on ServerException catch (error) {
    if (error.code == '23505') {
      return jsonError(409, 'conflict', 'Такая организация или логин уже есть в системе.');
    }
    rethrow;
  }

  return jsonResponse(200, {
    'application': (await _detailJson(db, id))!,
    'account': login == null
        ? null
        : {
            'login': login,
            'password': password,
            'company': detail['orgName'],
            'project': projectName,
          },
  });
}

class _Clash implements Exception {
  _Clash(this.message);

  final String message;
}

Future<Response> _document(Request request, AppDatabase db, String id, String docId) async {
  final opened = await _admin(request, db);
  if (opened is Response) return opened;
  if (!_isUuid(id) || !_isUuid(docId)) return jsonError(404, 'not_found', 'Файл не найден.');
  final rows = await db.owner.execute(
    Sql.named('''
      SELECT storage_path, content_type, file_name
      FROM application_documents
      WHERE id = @doc::uuid AND application_id = @id::uuid
    '''),
    parameters: {'doc': docId, 'id': id},
  );
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Файл не найден.');
  final file = File(rows.first[0]! as String);
  if (!await file.exists()) return jsonError(404, 'not_found', 'Файл не найден.');
  final encoded = Uri.encodeComponent(rows.first[2]! as String);
  return Response.ok(
    file.openRead(),
    headers: {
      'content-type': rows.first[1]! as String,
      'content-disposition': "inline; filename*=UTF-8''$encoded",
      'x-content-type-options': 'nosniff',
      'cache-control': 'private, no-store',
    },
  );
}

// ── Demo data ────────────────────────────────────────────────────────────

/// Three sample applications so the admin CRM is not empty on a fresh install.
Future<void> seedDemoApplications(AppDatabase db, {bool demo = false}) async {
  final existing = await db.owner.execute(
    Sql.named('SELECT count(*)::int FROM applications WHERE is_demo = @demo OR NOT @demo'),
    parameters: {'demo': demo},
  );
  if ((existing.first[0]! as int) > 0) return;
  final samples = <Map<String, Object?>>[
    {
      'kind': 'developer',
      'status': 'new',
      'org': 'ООО «Янги Уфқ Девелопмент»',
      'inn': '307412558',
      'contact': 'Азиз Каримов',
      'phone': '+998901112233',
      'email': 'aziz@yangi-ufq.example',
      'region': 'tashkent_city',
      'data': {
        'org_full_name': 'ООО «Янги Уфқ Девелопмент»',
        'legal_form': 'llc',
        'inn': '307412558',
        'object_name': 'ЖК «Янги Уфқ»',
        'object_address': 'г. Ташкент, Яшнабадский район',
        'owners': [
          {'kind': 'person', 'name': 'Азиз Каримов', 'tax_id': '31205880120045', 'share': '100'},
        ],
        'licenses': <Object?>[],
      },
    },
    {
      'kind': 'developer',
      'status': 'calling',
      'org': 'ООО «Самарқанд Қурилиш Инвест»',
      'inn': '305998114',
      'contact': 'Шахзод Рахимов',
      'phone': '+998935554433',
      'email': 'shakhzod@sqi.example',
      'region': 'samarkand',
      'data': {
        'org_full_name': 'ООО «Самарқанд Қурилиш Инвест»',
        'legal_form': 'llc',
        'inn': '305998114',
        'object_name': 'ЖК «Регистон Парк»',
        'object_address': 'г. Самарканд, ул. Университетский бульвар',
        'owners': [
          {'kind': 'person', 'name': 'Шахзод Рахимов', 'tax_id': '30908900120031', 'share': '60'},
          {'kind': 'company', 'name': 'ООО «Регистон Холдинг»', 'tax_id': '304112233', 'share': '40'},
        ],
        'licenses': <Object?>[],
      },
    },
    {
      'kind': 'bank',
      'status': 'new',
      'org': 'АКБ «Пример Банк»',
      'inn': '200950123',
      'contact': 'Динара Юсупова',
      'phone': '+998712223344',
      'email': 'd.yusupova@primerbank.example',
      'region': 'tashkent_city',
      'data': {
        'org_full_name': 'АКБ «Пример Банк»',
        'inn': '200950123',
        'interests': ['project_finance', 'tranche_control'],
      },
    },
  ];
  for (final sample in samples) {
    final inserted = await db.owner.execute(
      Sql.named('''
        INSERT INTO applications (
          kind, status, org_name, inn, contact_name, phone, email, region, data,
          token_hash, consent_at, consent_version, is_demo
        )
        VALUES (
          @kind, @status, @org, @inn, @contact, @phone, @email, @region, @data::text::jsonb,
          @hash, now(), @version, @demo
        )
        RETURNING id::text
      '''),
      parameters: {
        'kind': sample['kind'],
        'status': sample['status'],
        'org': sample['org'],
        'inn': sample['inn'],
        'contact': sample['contact'],
        'phone': sample['phone'],
        'email': sample['email'],
        'region': sample['region'],
        'data': jsonEncode(sample['data']),
        'hash': sha256Hex(randomToken()),
        'version': consentVersion,
        'demo': demo,
      },
    );
    await db.owner.execute(
      Sql.named('''
        INSERT INTO application_events (application_id, kind)
        VALUES (@id::uuid, 'created')
      '''),
      parameters: {'id': inserted.first[0]},
    );
  }
}
