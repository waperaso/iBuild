import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'db.dart';
import 'env.dart';
import 'http_util.dart';
import 'passwords.dart';
import 'requests.dart';

const _uuid =
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

void mountModeration(Router router, AppDatabase db, AppEnv env) {
  router
    ..get('/api/admin/changes', (Request request) => _queue(request, db))
    ..post('/api/admin/changes/<id>/approve', (Request request, String id) => _approve(request, db, id))
    ..post('/api/admin/changes/<id>/reject', (Request request, String id) => _reject(request, db, id))
    ..get('/api/project-changes/<id>/photo', (Request request, String id) => _changePhoto(request, db, id))
    ..get('/api/projects/<id>/changes', (Request request, String id) => _list(request, db, id))
    ..post('/api/projects/<id>/changes', (Request request, String id) => _propose(request, db, env, id))
    ..get('/api/projects/<id>/photo', (Request request, String id) => _projectPhoto(request, db, id));
}

Future<Object> _session(Request request, AppDatabase db, {bool csrf = false}) async {
  final token = readCookies(request)[sessionCookieName];
  if (token == null || token.isEmpty) {
    return jsonError(401, 'unauthenticated', 'Войдите, чтобы продолжить.');
  }
  final lookup = await db.lookupSession(sha256Hex(token));
  if (lookup.state != SessionState.ok || lookup.user == null) {
    return jsonError(401, 'unauthenticated', 'Войдите, чтобы продолжить.');
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

Future<Response> _propose(Request request, AppDatabase db, AppEnv env, String id) async {
  final opened = await _session(request, db, csrf: true);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!RegExp(_uuid).hasMatch(id)) return jsonError(404, 'not_found', 'Объект не найден.');
  final project = await db.projectForUser(session.user!.id, id);
  if (project == null) return jsonError(404, 'not_found', 'Объект не найден.');
  if (project.myRole != 'director') {
    return jsonError(403, 'forbidden', 'Менять карточку объекта может только застройщик.');
  }

  final parsed = await _readProposal(request);
  if (parsed is Response) return parsed;
  final proposal = parsed as _Proposal;
  if (proposal.name.isEmpty || proposal.name.length > 200) {
    return jsonError(400, 'validation', 'Напишите название объекта.');
  }
  if (proposal.address.isEmpty || proposal.address.length > 500) {
    return jsonError(400, 'validation', 'Напишите адрес объекта.');
  }

  final root = '${env.fileRoot.replaceAll(RegExp(r'/+$'), '')}/changes';
  String changeId;
  String? photoPath;
  try {
    final inserted = await db.pool.execute(
      Sql.named('''
        WITH chosen AS (SELECT gen_random_uuid() AS id)
        INSERT INTO project_changes (
          id, project_id, author_user_id, name, address, photo_path, status
        )
        SELECT id,
               @project::uuid,
               @user::uuid,
               @name,
               @address,
               CASE WHEN @hasPhoto THEN @root || '/' || id::text ELSE NULL END,
               'pending'
        FROM chosen
        RETURNING id::text, photo_path
      '''),
      parameters: {
        'project': id,
        'user': session.user!.id,
        'name': proposal.name,
        'address': proposal.address,
        'hasPhoto': proposal.photo != null,
        'root': root,
      },
    );
    changeId = inserted.first[0]! as String;
    photoPath = inserted.first[1] as String?;
  } on ServerException catch (error) {
    if (error.code == '23505') {
      return jsonError(409, 'conflict', 'Правки по этому объекту уже ждут проверки.');
    }
    rethrow;
  }

  if (proposal.photo != null && photoPath != null) {
    final file = File(photoPath);
    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(proposal.photo!, flush: true);
    } catch (_) {
      await db.owner.execute(
        Sql.named('DELETE FROM project_changes WHERE id = @id::uuid'),
        parameters: {'id': changeId},
      );
      return jsonError(500, 'storage', 'Не удалось сохранить фото.');
    }
  }

  final row = await _one(db, changeId);
  if (row == null) return jsonError(500, 'storage', 'Не удалось сохранить правку.');
  return jsonResponse(201, row);
}

Future<Response> _list(Request request, AppDatabase db, String id) async {
  final opened = await _session(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!RegExp(_uuid).hasMatch(id)) return jsonError(404, 'not_found', 'Объект не найден.');
  final project = await db.projectForUser(session.user!.id, id);
  if (project == null) return jsonError(404, 'not_found', 'Объект не найден.');
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT $_changeColumns
      FROM project_changes c
      JOIN projects p ON p.id = c.project_id
      WHERE c.project_id = @project::uuid
      ORDER BY c.created_at DESC
    '''),
    parameters: {'project': id},
  );
  return jsonResponse(200, {
    'changes': [for (final row in rows) _changeJson(row.toColumnMap())],
  });
}

Future<Response> _queue(Request request, AppDatabase db) async {
  final opened = await _session(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!session.user!.platformAdmin) {
    return jsonError(403, 'forbidden', 'Правки видит только администратор iBuild.');
  }
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT $_changeColumns
      FROM project_changes c
      JOIN projects p ON p.id = c.project_id
      WHERE c.status = 'pending'
      ORDER BY c.created_at
    '''),
  );
  return jsonResponse(200, {
    'changes': [for (final row in rows) _changeJson(row.toColumnMap())],
  });
}

Future<Response> _approve(Request request, AppDatabase db, String id) async {
  final opened = await _gate(request, db, id);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  final applied = await db.pool.runTx((tx) async {
    final updated = await tx.execute(
      Sql.named('''
        UPDATE project_changes
        SET status = 'approved',
            reviewer_user_id = @user::uuid,
            reviewed_at = now()
        WHERE id = @id::uuid AND status = 'pending'
        RETURNING project_id::text, name, address, photo_path
      '''),
      parameters: {'user': session.user!.id, 'id': id},
    );
    if (updated.isEmpty) return false;
    final map = updated.first.toColumnMap();
    await tx.execute(
      Sql.named('''
        UPDATE projects
        SET name = @name,
            address = @address,
            photo_path = CASE
              WHEN @photo::text IS NULL OR @photo = '' THEN photo_path
              ELSE @photo
            END
        WHERE id = @project::uuid
      '''),
      parameters: {
        'name': map['name'],
        'address': map['address'],
        'photo': map['photo_path'],
        'project': map['project_id'],
      },
    );
    return true;
  });
  if (applied != true) return jsonError(404, 'not_found', 'Правка не найдена.');
  final row = await _one(db, id);
  return jsonResponse(200, row ?? {'id': id, 'status': 'approved'});
}

Future<Response> _reject(Request request, AppDatabase db, String id) async {
  final opened = await _gate(request, db, id);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final note = ((body as Map<String, dynamic>)['note'] as String?)?.trim() ?? '';
  if (note.isEmpty || note.length > 500) {
    return jsonError(400, 'validation', 'Напишите причину.');
  }
  final rows = await db.pool.execute(
    Sql.named('''
      UPDATE project_changes
      SET status = 'rejected',
          review_note = @note,
          reviewer_user_id = @user::uuid,
          reviewed_at = now()
      WHERE id = @id::uuid AND status = 'pending'
      RETURNING id::text
    '''),
    parameters: {'id': id, 'user': session.user!.id, 'note': note},
  );
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Правка не найдена.');
  final row = await _one(db, id);
  return jsonResponse(200, row ?? {'id': id, 'status': 'rejected'});
}

Future<Object> _gate(Request request, AppDatabase db, String id) async {
  final opened = await _session(request, db, csrf: true);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!session.user!.platformAdmin) {
    return jsonError(403, 'forbidden', 'Решение принимает администратор iBuild.');
  }
  if (!RegExp(_uuid).hasMatch(id)) return jsonError(404, 'not_found', 'Правка не найдена.');
  return session;
}

Future<Response> _projectPhoto(Request request, AppDatabase db, String id) async {
  final opened = await _session(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!RegExp(_uuid).hasMatch(id)) return jsonError(404, 'not_found', 'Объект не найден.');
  final project = await db.projectForUser(session.user!.id, id);
  if (project == null) return jsonError(404, 'not_found', 'Объект не найден.');
  final rows = await db.pool.execute(
    Sql.named('SELECT photo_path FROM projects WHERE id = @id::uuid'),
    parameters: {'id': id},
  );
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Фото не найдено.');
  return _file(rows.first[0] as String?);
}

Future<Response> _changePhoto(Request request, AppDatabase db, String id) async {
  final opened = await _session(request, db);
  if (opened is Response) return opened;
  if (!RegExp(_uuid).hasMatch(id)) return jsonError(404, 'not_found', 'Фото не найдено.');
  final rows = await db.pool.execute(
    Sql.named('SELECT photo_path FROM project_changes WHERE id = @id::uuid'),
    parameters: {'id': id},
  );
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Фото не найдено.');
  return _file(rows.first[0] as String?);
}

Response _file(String? path) {
  if (path == null || path.isEmpty) return jsonError(404, 'not_found', 'Фото не найдено.');
  final file = File(path);
  if (!file.existsSync()) return jsonError(404, 'not_found', 'Фото не найдено.');
  final bytes = file.readAsBytesSync();
  final detected = sniff(bytes);
  return Response.ok(
    bytes,
    headers: {
      'content-type': detected?.type ?? 'application/octet-stream',
      'content-length': '${bytes.length}',
      'cache-control': 'private, no-store',
      'x-content-type-options': 'nosniff',
    },
  );
}

Future<Map<String, Object?>?> _one(AppDatabase db, String id) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT $_changeColumns
      FROM project_changes c
      JOIN projects p ON p.id = c.project_id
      WHERE c.id = @id::uuid
    '''),
    parameters: {'id': id},
  );
  if (rows.isEmpty) return null;
  return _changeJson(rows.first.toColumnMap());
}

const _changeColumns = '''
  c.id::text AS id,
  c.project_id::text AS project_id,
  p.name AS current_name,
  p.address AS current_address,
  (p.photo_path IS NOT NULL AND btrim(p.photo_path) <> '') AS current_has_photo,
  c.name AS name,
  c.address AS address,
  c.status AS status,
  (c.photo_path IS NOT NULL AND btrim(c.photo_path) <> '') AS has_photo,
  c.review_note AS review_note
''';

bool _flag(Object? value) {
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  return text == 'true' || text == 't';
}

Map<String, Object?> _changeJson(Map<String, dynamic> map) {
  return {
    'id': map['id'],
    'projectId': map['project_id'],
    'currentName': map['current_name'],
    'currentAddress': map['current_address'],
    'currentHasPhoto': _flag(map['current_has_photo']),
    'name': map['name'],
    'address': map['address'],
    'status': map['status'],
    'hasPhoto': _flag(map['has_photo']),
    'reviewNote': map['review_note'] ?? '',
  };
}

class _Proposal {
  const _Proposal(this.name, this.address, this.photo);

  final String name;
  final String address;
  final Uint8List? photo;
}

Future<Object> _readProposal(Request request) async {
  final type = request.headers['content-type'] ?? '';
  if (type.contains('multipart/form-data')) {
    final body = await readAtMost(request.read(), photoMaxBytes + 64 * 1024);
    if (body.overflow) return jsonError(400, 'validation', 'Фото больше 5 МБ.');
    final form = _parseForm(body.bytes, type);
    if (form == null) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
    if (form.photo != null) {
      if (form.photo!.length > photoMaxBytes) {
        return jsonError(400, 'validation', 'Фото больше 5 МБ.');
      }
      final detected = sniff(form.photo!);
      if (detected == null || detected.kind != 'photo') {
        return jsonError(400, 'validation', 'Подойдёт фото JPEG, PNG или WebP.');
      }
    }
    return _Proposal(form.name, form.address, form.photo);
  }
  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final json = body as Map<String, dynamic>;
  return _Proposal(
    (json['name'] as String?)?.trim() ?? '',
    (json['address'] as String?)?.trim() ?? '',
    null,
  );
}

class _Form {
  String name = '';
  String address = '';
  Uint8List? photo;
}

_Form? _parseForm(Uint8List body, String contentType) {
  final match = RegExp('boundary=(?:"([^"]+)"|([^;\\s]+))').firstMatch(contentType);
  if (match == null) return null;
  final boundary = (match.group(1) ?? match.group(2)!).trim();
  final separator = utf8.encode('--$boundary');
  final form = _Form();
  for (final raw in _split(body, separator)) {
    var part = raw;
    if (part.length >= 2 && part[0] == 13 && part[1] == 10) {
      part = part.sublist(2);
    }
    if (part.length >= 2 && part[part.length - 2] == 13 && part[part.length - 1] == 10) {
      part = part.sublist(0, part.length - 2);
    }
    if (part.isEmpty || (part.isNotEmpty && part[0] == 45)) continue;
    final headerEnd = _indexOf(part, utf8.encode('\r\n\r\n'));
    if (headerEnd < 0) continue;
    final header = utf8.decode(part.sublist(0, headerEnd), allowMalformed: true).toLowerCase();
    var content = part.sublist(headerEnd + 4);
    if (content.length >= 2 && content[content.length - 2] == 13 && content[content.length - 1] == 10) {
      content = content.sublist(0, content.length - 2);
    }
    final field = RegExp('name="([^"]+)"').firstMatch(header)?.group(1) ?? '';
    if (field == 'name') form.name = utf8.decode(content).trim();
    if (field == 'address') form.address = utf8.decode(content).trim();
    if (field == 'photo' && content.isNotEmpty) form.photo = Uint8List.fromList(content);
  }
  return form;
}

List<Uint8List> _split(Uint8List data, List<int> separator) {
  final parts = <Uint8List>[];
  var start = 0;
  var index = _indexOf(data, separator, 0);
  while (index >= 0) {
    parts.add(Uint8List.sublistView(data, start, index));
    start = index + separator.length;
    index = _indexOf(data, separator, start);
  }
  if (start <= data.length) parts.add(Uint8List.sublistView(data, start));
  return parts;
}

int _indexOf(List<int> data, List<int> pattern, [int from = 0]) {
  if (pattern.isEmpty || data.length < pattern.length) return -1;
  final last = data.length - pattern.length;
  for (var i = from; i <= last; i++) {
    var found = true;
    for (var j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) {
        found = false;
        break;
      }
    }
    if (found) return i;
  }
  return -1;
}
