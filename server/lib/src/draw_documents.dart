import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'bank_data.dart';
import 'db.dart';
import 'env.dart';
import 'http_util.dart';
import 'passwords.dart';
import 'requests.dart' show sniff, photoMaxBytes, pdfMaxBytes;

/// The papers of a tranche: the act of work done, the invoice, the waiver and the
/// rest of the check list. Each one is a file the developer uploads while the
/// tranche is a draft; the bank opens the same file from its card.

const _uuid = r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
const maxFilesPerPaper = 5;
const maxFilesPerDraw = 30;

/// SQL that is true when a check list item of a draw is really there: a file was
/// uploaded, or the mark was made before files existed. [r] is the alias of
/// `draw_requirements`.
String drawPaperPresent(String r) => '''
  ($r.attached_before_files OR EXISTS (
    SELECT 1 FROM draw_requirement_files f
    WHERE f.request_id = $r.request_id AND f.item_id = $r.item_id
  ))
''';

void mountDrawDocuments(Router router, AppDatabase db, AppEnv env) {
  router
    ..post('/api/draws/<id>/documents/<itemId>',
        (Request r, String id, String itemId) => _upload(r, db, env, id, itemId))
    ..delete('/api/draws/<id>/documents/<itemId>/<fileId>',
        (Request r, String id, String itemId, String fileId) => _remove(r, db, id, itemId, fileId))
    ..get('/api/draws/<id>/documents/<itemId>/<fileId>',
        (Request r, String id, String itemId, String fileId) => _open(r, db, id, itemId, fileId))
    ..get('/api/bank/tranches/<id>/documents/<fileId>',
        (Request r, String id, String fileId) => _bankOpen(r, db, id, fileId));
}

bool _isUuid(String value) => RegExp(_uuid).hasMatch(value);

Future<Object> _person(Request request, AppDatabase db, {required bool mutating}) async {
  final token = readCookies(request)[sessionCookieName];
  if (token == null || token.isEmpty) return jsonError(401, 'unauthenticated', 'Войдите, чтобы продолжить.');
  final lookup = await db.lookupSession(sha256Hex(token));
  if (lookup.state != SessionState.ok || lookup.user == null) {
    return jsonError(401, 'unauthenticated', 'Войдите, чтобы продолжить.');
  }
  if (mutating) {
    final header = request.headers['x-csrf-token'] ?? '';
    final expected = lookup.csrfToken ?? '';
    if (header.isEmpty || expected.isEmpty || !tokensEqual(header, expected)) {
      return jsonError(403, 'csrf', 'Сессия устарела. Обновите страницу и войдите снова.');
    }
  }
  return lookup.user!.id;
}

/// The draft of [id] that [userId] may fill, with the check list item [itemId].
Future<Object> _editableDraft(AppDatabase db, String id, String itemId, String userId) async {
  final rows = await db.owner.execute(
    Sql.named('''
      SELECT fr.status, fr.author_user_id::text AS author, m.role,
             EXISTS (SELECT 1 FROM draw_requirements r WHERE r.request_id = fr.id AND r.item_id = @item::uuid) AS listed
      FROM funding_requests fr
      LEFT JOIN project_members m ON m.project_id = fr.project_id AND m.user_id = @user::uuid
      WHERE fr.id = @id::uuid AND fr.draw_name <> ''
    '''),
    parameters: {'id': id, 'item': itemId, 'user': userId},
  );
  if (rows.isEmpty || rows.first[2] == null) return jsonError(404, 'not_found', 'Транш не найден.');
  final map = rows.first.toColumnMap();
  if (map['listed'] != true) return jsonError(404, 'not_found', 'Такого документа нет в списке транша.');
  final role = map['role'] as String;
  if (!const {'director', 'developer', 'contractor'}.contains(role)) {
    return jsonError(403, 'forbidden', 'Документы к траншу прикладывает застройщик.');
  }
  if (map['status'] != 'draft') {
    return jsonError(409, 'conflict', 'Транш уже отправлен в банк, изменить его нельзя.');
  }
  if (map['author'] != userId && role != 'developer') {
    return jsonError(403, 'forbidden', 'Черновик транша меняет тот, кто его начал.');
  }
  return true;
}

String _cleanName(String raw) {
  var name = raw.replaceAll(RegExp(r'[\\/\x00-\x1f"]'), '_').trim();
  if (name.isEmpty) name = 'document';
  if (name.length > 120) name = name.substring(name.length - 120);
  return name;
}

Future<Response> _upload(Request request, AppDatabase db, AppEnv env, String id, String itemId) async {
  final opened = await _person(request, db, mutating: true);
  if (opened is Response) return opened;
  final userId = opened as String;
  if (!_isUuid(id) || !_isUuid(itemId)) return jsonError(404, 'not_found', 'Транш не найден.');
  final allowed = await _editableDraft(db, id, itemId, userId);
  if (allowed is Response) return allowed;

  final body = await readAtMost(request.read(), pdfMaxBytes);
  if (body.overflow) return jsonError(400, 'validation', 'Файл больше 10 МБ.');
  if (body.bytes.isEmpty) return jsonError(400, 'validation', 'Добавьте файл.');
  final detected = sniff(body.bytes);
  if (detected == null) return jsonError(400, 'validation', 'Подойдёт фото (JPEG, PNG, WebP) или PDF.');
  if (detected.kind == 'photo' && body.bytes.length > photoMaxBytes) {
    return jsonError(400, 'validation', 'Фото больше 5 МБ.');
  }
  final counts = await db.owner.execute(
    Sql.named('''
      SELECT count(*)::int, count(*) FILTER (WHERE item_id = @item::uuid)::int
      FROM draw_requirement_files WHERE request_id = @id::uuid
    '''),
    parameters: {'id': id, 'item': itemId},
  );
  if ((counts.first[0]! as int) >= maxFilesPerDraw || (counts.first[1]! as int) >= maxFilesPerPaper) {
    return jsonError(400, 'validation', 'Слишком много файлов. Удалите лишние или объедините их в один PDF.');
  }

  final name = _cleanName(request.url.queryParameters['name'] ?? '');
  final root = env.fileRoot.replaceAll(RegExp(r'/+$'), '');
  final fileId = (await db.owner.execute('SELECT gen_random_uuid()::text')).first[0]! as String;
  final path = '$root/draws/$id/$fileId';
  final file = File(path);
  try {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(body.bytes, flush: true);
  } catch (_) {
    return jsonError(500, 'storage', 'Не удалось сохранить файл.');
  }
  try {
    await db.owner.runTx((tx) async {
      await tx.execute(
        Sql.named('''
          INSERT INTO draw_requirement_files (
            id, request_id, item_id, storage_path, file_name, content_type, size_bytes, author_user_id
          ) VALUES (@file::uuid, @id::uuid, @item::uuid, @path, @name, @type, @size, @user::uuid)
        '''),
        parameters: {
          'file': fileId,
          'id': id,
          'item': itemId,
          'path': path,
          'name': name,
          'type': detected.type,
          'size': body.bytes.length,
          'user': userId,
        },
      );
      await tx.execute(
        Sql.named('''
          UPDATE draw_requirements SET status = 'attached'
          WHERE request_id = @id::uuid AND item_id = @item::uuid
        '''),
        parameters: {'id': id, 'item': itemId},
      );
    });
  } catch (_) {
    try {
      await file.delete();
    } catch (_) {}
    rethrow;
  }
  return jsonResponse(201, {
    'id': fileId,
    'name': name,
    'contentType': detected.type,
    'sizeBytes': body.bytes.length,
  });
}

Future<Response> _remove(Request request, AppDatabase db, String id, String itemId, String fileId) async {
  final opened = await _person(request, db, mutating: true);
  if (opened is Response) return opened;
  final userId = opened as String;
  if (!_isUuid(id) || !_isUuid(itemId) || !_isUuid(fileId)) return jsonError(404, 'not_found', 'Транш не найден.');
  final allowed = await _editableDraft(db, id, itemId, userId);
  if (allowed is Response) return allowed;
  final removed = await db.owner.runTx((tx) async {
    final rows = await tx.execute(
      Sql.named('''
        DELETE FROM draw_requirement_files
        WHERE id = @file::uuid AND request_id = @id::uuid AND item_id = @item::uuid
        RETURNING storage_path
      '''),
      parameters: {'file': fileId, 'id': id, 'item': itemId},
    );
    if (rows.isEmpty) return null;
    await tx.execute(
      Sql.named('''
        UPDATE draw_requirements r SET status = 'missing'
        WHERE r.request_id = @id::uuid AND r.item_id = @item::uuid
          AND NOT ${drawPaperPresent('r')}
      '''),
      parameters: {'id': id, 'item': itemId},
    );
    return rows.first[0]! as String;
  });
  if (removed == null) return jsonError(404, 'not_found', 'Файл не найден.');
  try {
    await File(removed).delete();
  } catch (_) {}
  return Response(204);
}

Response _send(Map<String, Object?> stored) {
  final file = File(stored['storage_path']! as String);
  final name = Uri.encodeComponent(stored['file_name']! as String);
  return Response.ok(
    file.openRead(),
    headers: {
      'content-type': stored['content_type']! as String,
      'content-length': '${stored['size_bytes']}',
      'cache-control': 'private, no-store',
      'x-content-type-options': 'nosniff',
      'content-disposition': "inline; filename*=UTF-8''$name",
    },
  );
}

/// The developer side opens a paper of a draw it can see.
Future<Response> _open(Request request, AppDatabase db, String id, String itemId, String fileId) async {
  final opened = await _person(request, db, mutating: false);
  if (opened is Response) return opened;
  if (!_isUuid(id) || !_isUuid(itemId) || !_isUuid(fileId)) return jsonError(404, 'not_found', 'Файл не найден.');
  // Row security decides who sees the draw; a draft is seen only by its author.
  final visible = await db.pool.execute(
    Sql.named('SELECT 1 FROM funding_requests WHERE id = @id::uuid'),
    parameters: {'id': id},
  );
  if (visible.isEmpty) return jsonError(404, 'not_found', 'Файл не найден.');
  final rows = await db.owner.execute(
    Sql.named('''
      SELECT storage_path, file_name, content_type, size_bytes FROM draw_requirement_files
      WHERE id = @file::uuid AND request_id = @id::uuid AND item_id = @item::uuid
    '''),
    parameters: {'file': fileId, 'id': id, 'item': itemId},
  );
  if (rows.isEmpty || !await File(rows.first[0]! as String).exists()) {
    return jsonError(404, 'not_found', 'Файл не найден.');
  }
  return _send(rows.first.toColumnMap());
}

/// A bank opens the papers of a tranche that came to it.
Future<Response> _bankOpen(Request request, AppDatabase db, String id, String fileId) async {
  final opened = await bankContext(request, db);
  if (opened is Response) return opened;
  final ctx = opened as BankCtx;
  if (!_isUuid(id) || !_isUuid(fileId)) return jsonError(404, 'not_found', 'Файл не найден.');
  final rows = await db.owner.execute(
    Sql.named('''
      SELECT f.storage_path, f.file_name, f.content_type, f.size_bytes
      FROM draw_requirement_files f
      JOIN bank_tranches t ON t.request_id = f.request_id
      WHERE f.id = @file::uuid AND t.id = @id::uuid AND t.bank_id = @bank::uuid
    '''),
    parameters: {'file': fileId, 'id': id, 'bank': ctx.bankId},
  );
  if (rows.isEmpty || !await File(rows.first[0]! as String).exists()) {
    return jsonError(404, 'not_found', 'Файл не найден.');
  }
  return _send(rows.first.toColumnMap());
}

/// The papers of a draw with their files, for the developer's draw and the bank card.
Future<List<Map<String, Object?>>> drawPapers(AppDatabase db, String requestId) async {
  final rows = await db.owner.execute(
    Sql.named('''
      SELECT r.item_id::text AS item_id, c.code, c.title, c.required, r.status, r.note,
             ${drawPaperPresent('r')} AS present,
             r.attached_before_files AS before_files,
             COALESCE((
               SELECT json_agg(json_build_object(
                        'id', f.id::text, 'name', f.file_name,
                        'contentType', f.content_type, 'sizeBytes', f.size_bytes)
                      ORDER BY f.created_at)
               FROM draw_requirement_files f
               WHERE f.request_id = r.request_id AND f.item_id = r.item_id
             ), '[]'::json) AS files
      FROM draw_requirements r
      JOIN checklist_items c ON c.id = r.item_id
      WHERE r.request_id = @id::uuid
      ORDER BY c.required DESC, c.code
    '''),
    parameters: {'id': requestId},
  );
  return [
    for (final row in rows)
      {
        'item_id': row[0],
        'code': row[1],
        'title': row[2],
        'required': row[3] == true,
        'status': row[4],
        'note': row[5] ?? '',
        'present': row[6] == true,
        'beforeFiles': row[7] == true,
        'files': row[8] ?? const [],
      },
  ];
}
