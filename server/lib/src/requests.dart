import 'dart:io';
import 'dart:typed_data';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'db.dart';
import 'env.dart';
import 'http_util.dart';
import 'lifecycle.dart';
import 'money.dart';
import 'passwords.dart';

const _uuidPattern =
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

const photoMaxBytes = 5 * 1024 * 1024;
const pdfMaxBytes = 10 * 1024 * 1024;

void mountRequests(Router router, AppDatabase db, AppEnv env) {
  router
    ..get('/api/requests', (Request request) => _list(request, db))
    ..get('/api/requests.csv', (Request request) => _registry(request, db))
    ..post('/api/requests', (Request request) => _create(request, db))
    ..get('/api/requests/<id>', (Request request, String id) => _get(request, db, id))
    ..patch('/api/requests/<id>', (Request request, String id) => _update(request, db, id))
    ..post('/api/requests/<id>/submit', (Request request, String id) => _submit(request, db, id))
    ..post('/api/requests/<id>/deliver', (Request request, String id) => _deliver(request, db, id))
    ..post('/api/requests/<id>/cancel', (Request request, String id) => _cancel(request, db, id))
    ..post('/api/requests/<id>/tech', (Request request, String id) => _tech(request, db, id))
    ..post('/api/requests/<id>/contact', (Request request, String id) => _contact(request, db, id))
    ..post('/api/requests/<id>/approve', (Request request, String id) => _approve(request, db, id))
    ..post('/api/requests/<id>/reject', (Request request, String id) => _reject(request, db, id))
    ..post('/api/requests/<id>/pay', (Request request, String id) => _pay(request, db, id))
    ..post('/api/requests/<id>/withdraw', (Request request, String id) => _withdraw(request, db, id))
    ..post('/api/requests/<id>/copy', (Request request, String id) => _copy(request, db, id))
    ..post(
      '/api/requests/<id>/payment-file',
      (Request request, String id) => _paymentFile(request, db, env, id),
    )
    ..delete(
      '/api/requests/<id>/payment-file/<fileId>',
      (Request request, String id, String fileId) => _removePaymentFile(request, db, id, fileId),
    )
    ..post('/api/requests/<id>/files', (Request request, String id) => _upload(request, db, env, id))
    ..get(
      '/api/requests/<id>/files/<fileId>',
      (Request request, String id, String fileId) => _download(request, db, id, fileId),
    )
    ..delete(
      '/api/requests/<id>/files/<fileId>',
      (Request request, String id, String fileId) => _removeFile(request, db, id, fileId),
    );
}

Future<Response> _list(Request request, AppDatabase db) async {
  final session = await _session(request, db);
  if (session is Response) return session;
  final requests = await db.requestsForUser((session as SessionLookup).user!.id);
  return jsonResponse(200, {
    'requests': [for (final item in requests) item.toJson()],
  });
}

const _registryStatuses = {
  'draft',
  'submitted',
  'tech_approved',
  'approved',
  'paid',
  'rejected',
  'cancelled',
};

const _registryStatusName = {
  'draft': 'Черновик',
  'submitted': 'Ждёт решения банка',
  'tech_approved': 'Работу проверили, ждёт банк',
  'approved': 'Одобрен, ждёт выплаты',
  'paid': 'Выплачен',
  'rejected': 'Отклонён',
  'cancelled': 'Отозван',
};

Future<Response> _registry(Request request, AppDatabase db) async {
  final session = await _session(request, db);
  if (session is Response) return session;
  final params = request.url.queryParameters;
  final status = (params['status'] ?? '').trim();
  final projectId = (params['project'] ?? '').trim();
  if (status.isNotEmpty && !_registryStatuses.contains(status)) {
    return jsonError(400, 'validation', 'Такого статуса нет.');
  }
  if (projectId.isNotEmpty && !RegExp(_uuidPattern).hasMatch(projectId)) {
    return jsonError(400, 'validation', 'Объект не найден.');
  }
  final rows = await db.requestRegistry(
    userId: (session as SessionLookup).user!.id,
    status: status,
    projectId: projectId,
  );
  final lines = <String>[
    [
      'Объект',
      'Вид работ',
      'Подрядчик',
      'ID транша',
      'Сумма, сум',
      'Статус',
      'Дата подачи',
      'Дата оплаты',
      'Номер платёжки',
    ].map(_csvCell).join(';'),
    for (final row in rows)
      [
        row.projectName,
        row.lineTitle,
        row.firmName,
        row.id,
        row.amount,
        _registryStatusName[row.status] ?? row.status,
        row.submittedOn,
        row.paidOn,
        row.paymentNumber,
      ].map(_csvCell).join(';'),
  ];
  final body = '\uFEFF${lines.join('\r\n')}\r\n';
  return Response.ok(
    body,
    headers: {
      'content-type': 'text/csv; charset=utf-8',
      'content-disposition': 'attachment; filename="ibuild-reestr.csv"',
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
    },
  );
}

String _csvCell(String value) {
  var text = value.replaceAll('\r\n', ' ').replaceAll('\n', ' ').replaceAll('\r', ' ');
  if (text.startsWith('=') ||
      text.startsWith('+') ||
      text.startsWith('-') ||
      text.startsWith('@') ||
      text.startsWith('\t')) {
    text = "'$text";
  }
  if (text.contains(';') || text.contains('"')) {
    text = '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

Future<Response> _get(Request request, AppDatabase db, String id) async {
  final session = await _session(request, db);
  if (session is Response) return session;
  if (!RegExp(_uuidPattern).hasMatch(id)) {
    return jsonError(404, 'not_found', 'Транш не найден.');
  }
  final item = await db.requestForUser((session as SessionLookup).user!.id, id);
  if (item == null) return jsonError(404, 'not_found', 'Транш не найден.');
  return jsonResponse(200, item.toJson());
}

Future<Response> _create(Request request, AppDatabase db) async {
  final opened = await _mutating(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final json = body as Map<String, dynamic>;
  final projectId = json['projectId'] as String? ?? '';
  var itemId = (json['budgetItemId'] as String? ?? '').trim();
  final customTitle = (json['customTitle'] as String? ?? '').trim();
  final amountRaw = '${json['amount'] ?? ''}';
  final description = (json['description'] as String? ?? '').trim();
  if (projectId.isEmpty || amountRaw.trim().isEmpty || (itemId.isEmpty && customTitle.isEmpty)) {
    return jsonError(400, 'validation', 'Выберите вид работ и укажите сумму.');
  }
  if (customTitle.length > 80 || customTitle.contains(RegExp(r'''[\x00-\x1F<>]'''))) {
    return jsonError(400, 'validation', 'Название вида работ — не больше 80 символов.');
  }
  if (description.length > 2000) {
    return jsonError(400, 'validation', 'Описание слишком длинное.');
  }
  if (!_uuid(projectId) || (customTitle.isEmpty && !_uuid(itemId))) {
    return jsonError(404, 'not_found', 'Объект не найден.');
  }
  final project = await db.projectForUser(session.user!.id, projectId);
  if (project == null) return jsonError(404, 'not_found', 'Объект не найден.');
  if (customTitle.isNotEmpty && project.myRole != 'director') {
    return jsonError(403, 'forbidden', 'Свой вид работ может добавить только застройщик.');
  }
  if (project.myRole != 'contractor' &&
      project.myRole != 'director' &&
      project.myRole != 'developer') {
    return jsonError(403, 'forbidden', 'У вас нет прав на это действие.');
  }
  if (customTitle.isNotEmpty) {
    final createdLine = await db.insertUnsetPlanLine(
      projectId: project.id,
      companyId: project.companyId,
      title: customTitle,
    );
    if (createdLine == null) {
      return jsonError(400, 'validation', 'Для этого вида работ ещё не выбран подрядчик.');
    }
    itemId = createdLine;
  }
  final amount = normalizeMoney(amountRaw);
  if (amount == null) {
    return jsonError(
      400,
      'validation',
      'Сумма должна быть больше нуля, не больше двух знаков после запятой.',
    );
  }
  final ownsLine = await db.lineBelongsToContractor(
    userId: session.user!.id,
    projectId: projectId,
    itemId: itemId,
  );
  if (!ownsLine) return jsonError(404, 'not_found', 'Вид работ не найден.');
  final created = await db.insertDraft(
    userId: session.user!.id,
    projectId: projectId,
    itemId: itemId,
    amount: amount,
    description: description,
  );
  return jsonResponse(201, created.toJson());
}

Future<Response> _update(Request request, AppDatabase db, String id) async {
  final opened = await _mutating(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!_uuid(id)) return jsonError(404, 'not_found', 'Транш не найден.');
  final current = await db.requestForUser(session.user!.id, id);
  if (current == null) return jsonError(404, 'not_found', 'Транш не найден.');
  final isDev = session.memberships.any(
    (m) => m.projectId == current.projectId && m.role == 'developer',
  );
  if (current.status != 'draft' || (!current.mine && !isDev)) {
    return jsonError(409, 'not_draft', 'Транш уже отправлен, его нельзя править.');
  }
  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final json = body as Map<String, dynamic>;
  final itemId = (json['budgetItemId'] as String?) ?? current.budgetItemId;
  final description = json.containsKey('description')
      ? (json['description'] as String? ?? '').trim()
      : current.description;
  if (description.length > 2000) {
    return jsonError(400, 'validation', 'Описание слишком длинное.');
  }
  final amount = json.containsKey('amount')
      ? normalizeMoney('${json['amount'] ?? ''}')
      : current.amount;
  if (amount == null) {
    return jsonError(
      400,
      'validation',
      'Сумма должна быть больше нуля, не больше двух знаков после запятой.',
    );
  }
  if (!_uuid(itemId)) return jsonError(404, 'not_found', 'Вид работ не найден.');
  final ownsLine = await db.lineBelongsToContractor(
    userId: session.user!.id,
    projectId: current.projectId,
    itemId: itemId,
  );
  if (!ownsLine) return jsonError(404, 'not_found', 'Вид работ не найден.');
  final updated = await db.updateDraft(
    userId: session.user!.id,
    requestId: id,
    itemId: itemId,
    amount: amount,
    description: description,
  );
  if (updated == null) return jsonError(404, 'not_found', 'Транш не найден.');
  return jsonResponse(200, updated.toJson());
}

Future<Response> _upload(Request request, AppDatabase db, AppEnv env, String id) async {
  final opened = await _mutating(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!_uuid(id)) return jsonError(404, 'not_found', 'Транш не найден.');
  final body = await readAtMost(request.read(), pdfMaxBytes);
  if (body.overflow) {
    final kind = sniff(body.bytes)?.kind;
    if (kind == 'photo') return jsonError(400, 'validation', 'Фото больше 5 МБ.');
    return jsonError(400, 'validation', 'PDF больше 10 МБ.');
  }
  if (body.bytes.isEmpty) return jsonError(400, 'validation', 'Добавьте файл.');
  final detected = sniff(body.bytes);
  if (detected == null) {
    return jsonError(
      400,
      'validation',
      'Подойдёт фото (JPEG, PNG, WebP) или PDF.',
    );
  }
  if (detected.kind == 'photo' && body.bytes.length > photoMaxBytes) {
    return jsonError(400, 'validation', 'Фото больше 5 МБ.');
  }
  final purpose = (request.headers['x-file-purpose'] ?? 'material').trim();
  if (purpose != 'material') {
    return jsonError(400, 'validation', 'Можно добавить фото и один PDF.');
  }
  final root = env.fileRoot.replaceAll(RegExp(r'/+$'), '');
  RequestFileRecord stored;
  try {
    stored = await db.addRequestFile(
      userId: session.user!.id,
      requestId: id,
      contentType: detected.type,
      kind: detected.kind,
      sizeBytes: body.bytes.length,
      fileRoot: root,
      purpose: purpose,
    );
  } on RequestRule catch (error) {
    final missing = error.message == 'Транш не найден.';
    return jsonError(missing ? 404 : 400, missing ? 'not_found' : 'validation', error.message);
  }
  final file = File(stored.storagePath);
  try {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(body.bytes, flush: true);
  } catch (_) {
    await db.removeRequestFile(
      userId: session.user!.id,
      requestId: id,
      fileId: stored.id,
    );
    return jsonError(500, 'storage', 'Не удалось сохранить файл.');
  }
  return jsonResponse(201, stored.toJson());
}

Future<Response> _download(Request request, AppDatabase db, String id, String fileId) async {
  final session = await _session(request, db);
  if (session is Response) return session;
  if (!_uuid(id) || !_uuid(fileId)) {
    return jsonError(404, 'not_found', 'Транш не найден.');
  }
  final stored = await db.fileForUser((session as SessionLookup).user!.id, id, fileId);
  if (stored == null || stored.storagePath.isEmpty) {
    return jsonError(404, 'not_found', 'Транш не найден.');
  }
  final file = File(stored.storagePath);
  if (!await file.exists()) return jsonError(404, 'not_found', 'Транш не найден.');
  return Response.ok(
    file.openRead(),
    headers: {
      'content-type': stored.contentType,
      'content-length': '${stored.sizeBytes}',
      'cache-control': 'private, no-store',
      'x-content-type-options': 'nosniff',
      'content-disposition': 'inline; filename="${_downloadName(stored.contentType)}"',
    },
  );
}

Future<Response> _removeFile(Request request, AppDatabase db, String id, String fileId) async {
  final opened = await _mutating(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!_uuid(id) || !_uuid(fileId)) {
    return jsonError(404, 'not_found', 'Транш не найден.');
  }
  final current = await db.requestForUser(session.user!.id, id);
  if (current == null) return jsonError(404, 'not_found', 'Транш не найден.');
  if (current.status != 'draft') {
    return jsonError(409, 'not_draft', 'Файлы можно убирать только из черновика.');
  }
  final path = await db.removeRequestFile(
    userId: session.user!.id,
    requestId: id,
    fileId: fileId,
  );
  if (path == null) return jsonError(404, 'not_found', 'Транш не найден.');
  final file = File(path);
  if (await file.exists()) await file.delete();
  return Response(204, headers: {'cache-control': 'no-store'});
}

bool _uuid(String value) => RegExp(_uuidPattern).hasMatch(value);

Future<Response> _submit(Request request, AppDatabase db, String id) {
  return _transition(request, db, id, (userId, version, key, json) {
    final addressee = (json['addresseeUserId'] as String? ?? '').trim();
    final tail = addressee.isEmpty ? '' : '|$addressee';
    return submitRequest(
      db,
      userId: userId,
      requestId: id,
      version: version,
      key: key,
      fingerprint: 'submit|$id|$version$tail',
      addresseeUserId: addressee,
    );
  });
}

Future<Response> _deliver(Request request, AppDatabase db, String id) {
  return _transition(request, db, id, (userId, version, key, json) {
    final addressee = (json['addresseeUserId'] as String? ?? '').trim();
    if (addressee.isEmpty) {
      return Future.value(LifeReply(400, '{"error":"validation","message":"Выберите, кому отправить транш."}'));
    }
    return deliverRequest(
      db,
      userId: userId,
      requestId: id,
      version: version,
      key: key,
      fingerprint: 'deliver|$id|$version|$addressee',
      addresseeUserId: addressee,
    );
  });
}

Future<Response> _cancel(Request request, AppDatabase db, String id) {
  return _transition(request, db, id, (userId, version, key, _) {
    return cancelRequest(
      db,
      userId: userId,
      requestId: id,
      version: version,
      key: key,
      fingerprint: 'cancel|$id|$version',
    );
  });
}

Future<Response> _tech(Request request, AppDatabase db, String id) {
  return _transition(request, db, id, (userId, version, key, json) {
    final decision = json['decision'] as String? ?? '';
    if (decision != 'approve' && decision != 'reject') {
      return Future.value(LifeReply(400, '{"error":"validation","message":"Выберите решение."}'));
    }
    final reason = (json['reason'] as String? ?? '').trim();
    return techDecision(
      db,
      userId: userId,
      requestId: id,
      version: version,
      decision: decision,
      reason: reason,
      key: key,
      fingerprint: 'tech|$id|$version|$decision|$reason',
    );
  });
}

Future<Response> _approve(Request request, AppDatabase db, String id) {
  return _transition(request, db, id, (userId, version, key, _) {
    return directorApprove(
      db,
      userId: userId,
      requestId: id,
      version: version,
      key: key,
      fingerprint: 'approve|$id|$version',
    );
  });
}

Future<Response> _reject(Request request, AppDatabase db, String id) {
  return _transition(request, db, id, (userId, version, key, json) {
    final reason = (json['reason'] as String? ?? '').trim();
    return directorReject(
      db,
      userId: userId,
      requestId: id,
      version: version,
      reason: reason,
      key: key,
      fingerprint: 'reject|$id|$version|$reason',
    );
  });
}

Future<Response> _pay(Request request, AppDatabase db, String id) {
  return _transition(request, db, id, (userId, version, key, json) {
    final paidOn = (json['paidOn'] as String? ?? '').trim();
    final paymentNumber = (json['paymentNumber'] as String? ?? '').trim();
    return recordPayment(
      db,
      userId: userId,
      requestId: id,
      version: version,
      paidOn: paidOn,
      paymentNumber: paymentNumber,
      key: key,
      fingerprint: 'pay|$id|$version|$paidOn|$paymentNumber',
    );
  });
}

Future<Response> _withdraw(Request request, AppDatabase db, String id) {
  return _transition(request, db, id, (userId, version, key, json) {
    final reason = (json['reason'] as String? ?? '').trim();
    final confirmed = json['unpaidConfirmed'] == true;
    return withdrawApproval(
      db,
      userId: userId,
      requestId: id,
      version: version,
      reason: reason,
      unpaidConfirmed: confirmed,
      key: key,
      fingerprint: 'withdraw|$id|$version|$reason|$confirmed',
    );
  });
}

Future<Response> _copy(Request request, AppDatabase db, String id) {
  return _transition(request, db, id, (userId, version, key, _) {
    return copyRejected(
      db,
      userId: userId,
      requestId: id,
      version: version,
      key: key,
      fingerprint: 'copy|$id|$version',
    );
  });
}

Future<Response> _paymentFile(Request request, AppDatabase db, AppEnv env, String id) async {
  final opened = await _mutating(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!_uuid(id)) return jsonError(404, 'not_found', 'Транш не найден.');
  final body = await readAtMost(request.read(), pdfMaxBytes);
  if (body.overflow) {
    final kind = sniff(body.bytes)?.kind;
    if (kind == 'photo') return jsonError(400, 'validation', 'Фото больше 5 МБ.');
    return jsonError(400, 'validation', 'PDF больше 10 МБ.');
  }
  if (body.bytes.isEmpty) return jsonError(400, 'validation', 'Добавьте файл.');
  final detected = sniff(body.bytes);
  if (detected == null) {
    return jsonError(400, 'validation', 'Подойдёт фото (JPEG, PNG, WebP) или PDF.');
  }
  if (detected.kind == 'photo' && body.bytes.length > photoMaxBytes) {
    return jsonError(400, 'validation', 'Фото больше 5 МБ.');
  }
  final root = env.fileRoot.replaceAll(RegExp(r'/+$'), '');
  RequestFileRecord stored;
  try {
    stored = await db.addPaymentFile(
      userId: session.user!.id,
      requestId: id,
      contentType: detected.type,
      kind: detected.kind,
      sizeBytes: body.bytes.length,
      fileRoot: root,
    );
  } on RequestRule catch (error) {
    final missing = error.message == 'Транш не найден.';
    return jsonError(missing ? 404 : 400, missing ? 'not_found' : 'validation', error.message);
  }
  final file = File(stored.storagePath);
  try {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(body.bytes, flush: true);
  } catch (_) {
    await db.removePaymentFile(
      userId: session.user!.id,
      requestId: id,
      fileId: stored.id,
    );
    return jsonError(500, 'storage', 'Не удалось сохранить файл.');
  }
  return jsonResponse(201, stored.toJson());
}

Future<Response> _removePaymentFile(
  Request request,
  AppDatabase db,
  String id,
  String fileId,
) async {
  final opened = await _mutating(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!_uuid(id) || !_uuid(fileId)) return jsonError(404, 'not_found', 'Транш не найден.');
  final path = await db.removePaymentFile(
    userId: session.user!.id,
    requestId: id,
    fileId: fileId,
  );
  if (path == null) return jsonError(404, 'not_found', 'Транш не найден.');
  final file = File(path);
  if (file.existsSync()) await file.delete();
  return Response(204);
}

Future<Response> _contact(Request request, AppDatabase db, String id) async {
  final opened = await _mutating(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!_uuid(id)) return jsonError(404, 'not_found', 'Транш не найден.');
  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final message = ((body as Map<String, dynamic>)['message'] as String? ?? '').trim();
  if (message.isEmpty || message.length > 2000) {
    return jsonError(400, 'validation', 'Напишите сообщение.');
  }
  final rows = await db.pool.execute(
    Sql.named('''
      INSERT INTO audit_events (project_id, request_id, action, author_user_id, reason)
      SELECT fr.project_id, fr.id, 'contact', @user::uuid, @message
      FROM funding_requests fr
      JOIN project_members m ON m.project_id = fr.project_id AND m.user_id = @user::uuid
      WHERE fr.id = @id::uuid
        AND fr.status <> 'draft'
        AND m.role = 'observer'
      RETURNING id::text
    '''),
    parameters: {'id': id, 'user': session.user!.id, 'message': message},
  );
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Транш не найден.');
  return jsonResponse(201, {'id': rows.first[0]});
}

Future<Response> _transition(
  Request request,
  AppDatabase db,
  String id,
  Future<LifeReply> Function(String userId, int version, String key, Map<String, dynamic> json) run,
) async {
  final opened = await _mutating(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!_uuid(id)) return jsonError(404, 'not_found', 'Транш не найден.');
  final key = request.headers['idempotency-key'] ?? '';
  if (!RegExp(r'^[A-Za-z0-9_-]{8,80}$').hasMatch(key)) {
    return jsonError(400, 'validation', 'Попробуйте отправить ещё раз.');
  }
  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final json = body as Map<String, dynamic>;
  final version = json['version'];
  if (version is! int) return jsonError(400, 'validation', 'Обновите страницу и попробуйте снова.');
  try {
    final reply = await run(session.user!.id, version, key, json);
    return Response(
      reply.status,
      body: reply.body,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
        'x-content-type-options': 'nosniff',
      },
    );
  } on KeyReused {
    return jsonError(409, 'idempotency', 'Не получилось отправить. Попробуйте ещё раз.');
  }
}

Future<Object> _session(Request request, AppDatabase db) async {
  final token = readCookies(request)[sessionCookieName];
  if (token == null || token.isEmpty) {
    return jsonError(401, 'unauthenticated', 'Войдите, чтобы продолжить.');
  }
  final lookup = await db.lookupSession(sha256Hex(token));
  switch (lookup.state) {
    case SessionState.ok:
      return lookup;
    case SessionState.inactive:
      return jsonError(403, 'inactive', 'Эта учётная запись отключена.');
    case SessionState.missing:
    case SessionState.expired:
      return jsonError(401, 'unauthenticated', 'Войдите, чтобы продолжить.');
  }
}

Future<Object> _mutating(Request request, AppDatabase db) async {
  final lookup = await _session(request, db);
  if (lookup is Response) return lookup;
  final session = lookup as SessionLookup;
  final header = request.headers['x-csrf-token'] ?? '';
  final expected = session.csrfToken ?? '';
  if (header.isEmpty || expected.isEmpty || !tokensEqual(header, expected)) {
    return jsonError(403, 'csrf', 'Сессия устарела. Обновите страницу и войдите снова.');
  }
  return session;
}

({String type, String kind})? sniff(Uint8List bytes) {
  if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return (type: 'image/jpeg', kind: 'photo');
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return (type: 'image/png', kind: 'photo');
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return (type: 'image/webp', kind: 'photo');
  }
  if (bytes.length >= 5 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46 &&
      bytes[4] == 0x2D) {
    return (type: 'application/pdf', kind: 'pdf');
  }
  return null;
}

String _downloadName(String contentType) {
  return switch (contentType) {
    'image/png' => 'photo.png',
    'image/webp' => 'photo.webp',
    'application/pdf' => 'document.pdf',
    _ => 'photo.jpg',
  };
}
