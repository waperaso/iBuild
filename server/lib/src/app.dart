import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import 'db.dart';
import 'env.dart';
import 'http_util.dart';
import 'money.dart';
import 'passwords.dart';
import 'admin.dart';
import 'bank.dart';
import 'bank_bridge.dart';
import 'demo.dart';
import 'mailbox.dart';
import 'vault.dart';
import 'loan.dart';
import 'moderation.dart';
import 'registration.dart';
import 'requests.dart';

const _uuidPattern = r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

Handler buildHandler({required AppDatabase db, required AppEnv env}) {
  Vault.configure(env.mailKey);
  final router = Router()
    ..get('/api/health', (_) => jsonResponse(200, {'ok': true}))
    ..get('/api/ready', (Request request) async {
      try {
        await db.owner.execute('SELECT 1').timeout(const Duration(seconds: 3));
        return jsonResponse(200, {'ok': true});
      } catch (_) {
        return jsonResponse(503, {'ok': false});
      }
    })
    ..get('/api/auth/csrf', (Request request) => _csrf(env))
    ..post('/api/auth/login', (Request request) => _login(request, db, env))
    ..post('/api/auth/password', (Request request) => _changePassword(request, db))
    ..post('/api/auth/logout', (Request request) => _logout(request, db, env))
    ..get('/api/auth/me', (Request request) => _me(request, db))
    ..get('/api/projects', (Request request) => _listProjects(request, db))
    ..get('/api/projects/<id>/budget', (Request request, String id) => _budget(request, db, id))
    ..post('/api/projects/<id>/budget', (Request request, String id) => _createLine(request, db, id))
    ..patch('/api/projects/<id>/budget/<itemId>', (Request request, String id, String itemId) => _updateLine(request, db, id, itemId))
    ..delete('/api/projects/<id>/budget/<itemId>', (Request request, String id, String itemId) => _deleteLine(request, db, id, itemId))
    ..get('/api/projects/<id>/members', (Request request, String id) => _members(request, db, id))
    ..post('/api/projects/<id>/members', (Request request, String id) => _addMember(request, db, id))
    ..delete('/api/projects/<id>/members/<memberId>', (Request request, String id, String memberId) => _removeMember(request, db, id, memberId))
    ..get('/api/projects/<id>/documents', (Request request, String id) => _documents(request, db, id))
    ..get('/api/projects/<id>', (Request request, String id) => _getProject(request, db, id))
    ..post('/api/projects', (Request request) => _createProject(request, db))
    ..get('/api/contractor-firms', (Request request) => _firms(request, db))
    ..post('/api/contractor-firms', (Request request) => _createFirm(request, db))
    ..get('/api/company/users', (Request request) => _companyUsers(request, db));
  mountRequests(router, db, env);
  mountLoan(router, db);
  mountModeration(router, db, env);
  mountBank(router, db);
  mountAdmin(router, db);
  mountMailbox(router, db);
  mountRegistration(router, db, env);
  mountDemo(router, db, env, (user, sessionToken, csrf) async {
    final memberships = await db.membershipsOf(user.id);
    final bank = await bankProfile(db, user.id);
    return jsonResponse(
      200,
      _userJson(user, memberships, csrfToken: csrf, bank: bank, demoSession: true),
      setCookie: sessionCookie(sessionToken, secure: env.cookieSecure, maxAge: env.demoSessionTtl),
    );
  });

  Handler? files;
  final webRoot = env.webRoot;
  if (webRoot != null && Directory(webRoot).existsSync()) {
    files = createStaticHandler(webRoot, defaultDocument: 'index.html');
  }

  return Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_safety(env))
      .addHandler((Request request) async {
    if (request.url.path == 'api' || request.url.path.startsWith('api/')) {
      final refused = await demoGuard(request, db);
      if (refused != null) return refused;
      final response = await _asCurrentUser(request, db, () => router.call(request));
      await _syncBank(request, response, db);
      await adminRecord(request, response, db);
      if (response.statusCode == 404) {
        await response.read().drain<void>();
        return jsonError(404, 'not_found', 'Ничего не найдено.');
      }
      return response;
    }
    if (files == null) {
      return Response.ok(
        'iBuild API is up. Build the web client so this origin can serve the screens.',
        headers: {'content-type': 'text/plain; charset=utf-8'},
      );
    }
    final response = await files(request);
    if (response.statusCode == 404 && request.method == 'GET') {
      await response.read().drain<void>();
      final index = File('${webRoot!}/index.html');
      if (await index.exists()) {
        return Response.ok(index.openRead(), headers: {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'no-cache',
        });
      }
    }
    return response.change(headers: {'cache-control': 'no-cache'});
  });
}

/// Serves the API without the Shelf "X-Powered-By" advertisement.
Future<HttpServer> serveApi(Handler handler, Object address, int port) {
  return shelf_io.serve(handler, address, port, poweredByHeader: null);
}

Response _csrf(AppEnv env) {
  final token = randomToken();
  return jsonResponse(200, {'csrfToken': token}, setCookie: csrfCookie(token, secure: env.cookieSecure));
}

Future<Response> _login(Request request, AppDatabase db, AppEnv env) async {
  final body = await readJsonObject(request);
  if (body is String) {
    return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  }
  final json = body as Map<String, dynamic>;
  final login = (json['login'] as String?)?.trim() ?? '';
  final password = json['password'] as String? ?? '';
  if (login.isEmpty || password.isEmpty) {
    return jsonError(400, 'validation', 'Введите логин и пароль.');
  }
  if (login.length > 64 || password.length > 200) {
    return jsonError(400, 'validation', 'Слишком длинный логин или пароль.');
  }

  final cookies = readCookies(request);
  final header = request.headers['x-csrf-token'] ?? '';
  final cookieToken = cookies[csrfCookieName] ?? '';
  if (header.isEmpty || cookieToken.isEmpty || !tokensEqual(header, cookieToken)) {
    return jsonError(403, 'csrf', 'Сессия устарела. Обновите страницу и войдите снова.');
  }

  final since = DateTime.now().toUtc().subtract(env.loginWindow);
  final failures = await db.recentFailures(login, since);
  if (failures >= env.loginFailureLimit) {
    return jsonError(429, 'rate_limited', 'Слишком много попыток. Подождите и попробуйте снова.');
  }

  final user = await db.userByLogin(login);
  final hash = user?.passwordHash ?? dummyPasswordHash;
  final passwordOk = verifyPassword(password, hash);
  if (user == null || !passwordOk) {
    await db.recordAttempt(login: login, success: false);
    return jsonError(401, 'invalid_credentials', 'Неверный логин или пароль.');
  }
  if (!user.active) {
    await db.recordAttempt(login: login, success: false);
    return jsonError(403, 'inactive', 'Эта учётная запись отключена.');
  }

  final sessionToken = randomToken();
  final csrf = randomToken();
  await db.insertSession(
    userId: user.id,
    tokenHash: sha256Hex(sessionToken),
    csrfToken: csrf,
    expiresAt: DateTime.now().toUtc().add(env.sessionTtl),
  );
  await db.recordAttempt(login: login, success: true);
  final memberships = await db.membershipsOf(user.id);
  final bank = await bankProfile(db, user.id);
  return jsonResponse(
    200,
    _userJson(user, memberships, csrfToken: csrf, bank: bank),
    setCookie: sessionCookie(sessionToken, secure: env.cookieSecure, maxAge: env.sessionTtl),
  );
}

Future<Response> _logout(Request request, AppDatabase db, AppEnv env) async {
  final token = readCookies(request)[sessionCookieName];
  if (token == null || token.isEmpty) {
    return jsonError(401, 'unauthenticated', 'Вы уже вышли из аккаунта.');
  }
  final lookup = await db.lookupSession(sha256Hex(token));
  if (lookup.state == SessionState.ok) {
    final csrf = _requireCsrf(request, lookup);
    if (csrf != null) return csrf;
  }
  await db.deleteSessionByHash(sha256Hex(token));
  return Response(
    204,
    headers: {
      'cache-control': 'no-store',
      'set-cookie': clearSessionCookie(secure: env.cookieSecure),
    },
  );
}

Future<Response> _changePassword(Request request, AppDatabase db) async {
  final lookup = await _requireSession(request, db);
  if (lookup is Response) return lookup;
  final session = lookup as SessionLookup;
  final csrf = _requireCsrf(request, session);
  if (csrf != null) return csrf;
  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final json = body as Map<String, dynamic>;
  final current = json['current'] as String? ?? '';
  final next = json['next'] as String? ?? '';
  final user = await db.userByLogin(session.user!.login);
  if (user == null || !verifyPassword(current, user.passwordHash)) {
    return jsonError(400, 'wrong_password', 'Текущий пароль указан неверно.');
  }
  if (next.length < 10 || next.length > 200) {
    return jsonError(400, 'validation', 'Новый пароль: не короче 10 символов.');
  }
  if (next == current) {
    return jsonError(400, 'validation', 'Новый пароль должен отличаться от текущего.');
  }
  final token = readCookies(request)[sessionCookieName] ?? '';
  await db.owner.execute(
    Sql.named('UPDATE users SET password_hash = @hash, must_change_password = false WHERE id = @id::uuid'),
    parameters: {'hash': hashPassword(next), 'id': user.id},
  );
  await db.owner.execute(
    Sql.named('DELETE FROM sessions WHERE user_id = @id::uuid AND token_hash <> @token'),
    parameters: {'id': user.id, 'token': sha256Hex(token)},
  );
  return jsonResponse(200, {'ok': true});
}

Future<Response> _me(Request request, AppDatabase db) async {
  final lookup = await _requireSession(request, db);
  if (lookup is Response) return lookup;
  final session = lookup as SessionLookup;
  final bank = await bankProfile(db, session.user!.id);
  return jsonResponse(
    200,
    _userJson(
      session.user!,
      session.memberships,
      csrfToken: session.csrfToken,
      bank: bank,
      demoSession: session.demoSession,
    ),
  );
}

Future<Response> _listProjects(Request request, AppDatabase db) async {
  final lookup = await _requireSession(request, db);
  if (lookup is Response) return lookup;
  final session = lookup as SessionLookup;
  final projects = await db.projectsForUser(session.user!.id);
  return jsonResponse(200, {
    'projects': [for (final project in projects) project.toJson()],
  });
}

Future<Response> _getProject(Request request, AppDatabase db, String id) async {
  final lookup = await _requireSession(request, db);
  if (lookup is Response) return lookup;
  if (!RegExp(_uuidPattern).hasMatch(id)) {
    return jsonError(404, 'not_found', 'Объект не найден.');
  }
  final session = lookup as SessionLookup;
  final project = await db.projectForUser(session.user!.id, id);
  if (project == null) return jsonError(404, 'not_found', 'Объект не найден.');
  return jsonResponse(200, project.toJson());
}

Future<Response> _documents(Request request, AppDatabase db, String id) async {
  final opened = await _openProject(request, db, id);
  if (opened is Response) return opened;
  final project = (opened as ({SessionLookup session, ProjectRecord project})).project;
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT id::text AS id,
             title,
             doc_number,
             to_char(issued_on, 'YYYY-MM-DD') AS issued_on,
             note
      FROM project_documents
      WHERE project_id = @project::uuid
      ORDER BY issued_on NULLS LAST, title
    '''),
    parameters: {'project': project.id},
  );
  return jsonResponse(200, {
    'documents': [
      for (final row in rows)
        {
          'id': row.toColumnMap()['id'],
          'title': row.toColumnMap()['title'],
          'number': row.toColumnMap()['doc_number'] ?? '',
          'issuedOn': row.toColumnMap()['issued_on'] ?? '',
          'note': row.toColumnMap()['note'] ?? '',
        },
    ],
  });
}

Future<Response> _createProject(Request request, AppDatabase db) async {
  final lookup = await _requireSession(request, db);
  if (lookup is Response) return lookup;
  final session = lookup as SessionLookup;
  final csrf = _requireCsrf(request, session);
  if (csrf != null) return csrf;
  final isDirector = session.memberships.any(
    (member) => member.role == 'director' || member.role == 'developer',
  );
  if (!isDirector) return jsonError(403, 'forbidden', 'У вас нет прав на это действие.');

  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final json = body as Map<String, dynamic>;
  final name = (json['name'] as String?)?.trim() ?? '';
  final address = (json['address'] as String?)?.trim() ?? '';
  if (name.isEmpty || address.isEmpty) {
    return jsonError(400, 'validation', 'Напишите название и адрес.');
  }
  if (name.length > 200) return jsonError(400, 'validation', 'Название слишком длинное.');
  if (address.length > 500) return jsonError(400, 'validation', 'Адрес слишком длинный.');

  // companyId from the client is ignored. The project belongs to the session company.
  final project = await db.createProjectForDirector(
    director: session.user!,
    name: name,
    address: address,
  );
  return jsonResponse(201, project.toJson());
}

Future<Response> _asCurrentUser(
  Request request,
  AppDatabase db,
  Future<Response> Function() handle,
) async {
  final token = readCookies(request)[sessionCookieName];
  if (token == null || token.isEmpty) return handle();
  final lookup = await db.lookupSession(sha256Hex(token));
  if (lookup.state != SessionState.ok || lookup.user == null) return handle();
  return db.asUser(lookup.user!.id, handle);
}

Future<Object> _requireSession(Request request, AppDatabase db) async {
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

Response? _requireCsrf(Request request, SessionLookup session) {
  final header = request.headers['x-csrf-token'] ?? '';
  final expected = session.csrfToken ?? '';
  if (header.isEmpty || expected.isEmpty || !tokensEqual(header, expected)) {
    return jsonError(403, 'csrf', 'Сессия устарела. Обновите страницу и войдите снова.');
  }
  return null;
}

const _roles = {'director', 'contractor', 'tech', 'observer', 'developer'};

Future<Object> _openProject(Request request, AppDatabase db, String id) async {
  if (!RegExp(_uuidPattern).hasMatch(id)) {
    return jsonError(404, 'not_found', 'Объект не найден.');
  }
  final lookup = await _requireSession(request, db);
  if (lookup is Response) return lookup;
  final session = lookup as SessionLookup;
  final project = await db.projectForUser(session.user!.id, id);
  if (project == null) return jsonError(404, 'not_found', 'Объект не найден.');
  return (session: session, project: project);
}

Response? _directorOnly(ProjectRecord project) {
  if (project.myRole != 'director' && project.myRole != 'developer') {
    return jsonError(403, 'forbidden', 'У вас нет прав на это действие.');
  }
  return null;
}

Response? _planWriter(ProjectRecord project) {
  if (project.myRole != 'director' &&
      project.myRole != 'developer' &&
      project.myRole != 'observer') {
    return jsonError(403, 'forbidden', 'У вас нет прав на это действие.');
  }
  return null;
}

bool _companyDirector(SessionLookup session) {
  return session.memberships.any(
    (member) => member.role == 'director' || member.role == 'developer',
  );
}

Future<Response> _budget(Request request, AppDatabase db, String id) async {
  final opened = await _openProject(request, db, id);
  if (opened is Response) return opened;
  final gate = opened as ({SessionLookup session, ProjectRecord project});
  final project = gate.project;
  final session = gate.session;
  final firmId = await db.viewerFirmId(session.user!.id, project.id);
  final lines = await db.budgetLinesFor(
    projectId: project.id,
    role: project.myRole,
    contractorFirmId: firmId,
  );
  return jsonResponse(200, {
    'locked': project.budgetLocked,
    'plan': project.plan,
    'reserved': project.reserved,
    'paid': project.paid,
    'available': project.available,
    'items': [for (final line in lines) line.toJson()],
  });
}

Future<Response> _createLine(Request request, AppDatabase db, String id) async {
  final opened = await _openProject(request, db, id);
  if (opened is Response) return opened;
  final gate = opened as ({SessionLookup session, ProjectRecord project});
  final csrf = _requireCsrf(request, gate.session);
  if (csrf != null) return csrf;
  final denied = _planWriter(gate.project);
  if (denied != null) return denied;
  if (gate.project.budgetLocked) {
    return jsonError(409, 'budget_locked', 'Бюджет больше нельзя менять: по объекту уже есть отправленный транш.');
  }
  final parsed = await _lineBody(request, db, gate.project.companyId);
  if (parsed is Response) return parsed;
  final line = parsed as ({String title, String amount, String firmId});
  final itemId = await db.insertBudgetLine(
    projectId: gate.project.id,
    title: line.title,
    amount: line.amount,
    contractorFirmId: line.firmId,
  );
  final firm = await db.firmInCompany(line.firmId, gate.project.companyId);
  return jsonResponse(201, {
    'id': itemId,
    'title': line.title,
    'amount': line.amount,
    'contractorFirmId': line.firmId,
    'contractorFirmName': firm?.name,
  });
}

Future<Response> _updateLine(Request request, AppDatabase db, String id, String itemId) async {
  final opened = await _openProject(request, db, id);
  if (opened is Response) return opened;
  final gate = opened as ({SessionLookup session, ProjectRecord project});
  if (!RegExp(_uuidPattern).hasMatch(itemId)) {
    return jsonError(404, 'not_found', 'Вид работ не найден.');
  }
  final csrf = _requireCsrf(request, gate.session);
  if (csrf != null) return csrf;
  final denied = _planWriter(gate.project);
  if (denied != null) return denied;
  if (gate.project.budgetLocked) {
    return jsonError(409, 'budget_locked', 'Бюджет больше нельзя менять: по объекту уже есть отправленный транш.');
  }
  final parsed = await _lineBody(request, db, gate.project.companyId);
  if (parsed is Response) return parsed;
  final line = parsed as ({String title, String amount, String firmId});
  final updated = await db.updateBudgetLine(
    projectId: gate.project.id,
    itemId: itemId,
    title: line.title,
    amount: line.amount,
    contractorFirmId: line.firmId,
  );
  if (!updated) return jsonError(404, 'not_found', 'Вид работ не найден.');
  return jsonResponse(200, {
    'id': itemId,
    'title': line.title,
    'amount': line.amount,
    'contractorFirmId': line.firmId,
  });
}

Future<Response> _deleteLine(Request request, AppDatabase db, String id, String itemId) async {
  final opened = await _openProject(request, db, id);
  if (opened is Response) return opened;
  final gate = opened as ({SessionLookup session, ProjectRecord project});
  if (!RegExp(_uuidPattern).hasMatch(itemId)) {
    return jsonError(404, 'not_found', 'Вид работ не найден.');
  }
  final csrf = _requireCsrf(request, gate.session);
  if (csrf != null) return csrf;
  final denied = _directorOnly(gate.project);
  if (denied != null) return denied;
  if (gate.project.budgetLocked) {
    return jsonError(409, 'budget_locked', 'Бюджет больше нельзя менять: по объекту уже есть отправленный транш.');
  }
  final removed = await db.deleteBudgetLine(gate.project.id, itemId);
  if (!removed) return jsonError(404, 'not_found', 'Вид работ не найден.');
  return Response(204, headers: {'cache-control': 'no-store'});
}

Future<Object> _lineBody(Request request, AppDatabase db, String companyId) async {
  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final json = body as Map<String, dynamic>;
  final title = (json['title'] as String?)?.trim() ?? '';
  final amount = normalizeMoney(json['amount'] as String? ?? '');
  final firmId = (json['contractorFirmId'] as String?)?.trim() ?? '';
  if (title.isEmpty || title.length > 200) {
    return jsonError(400, 'validation', 'Напишите, что за работа.');
  }
  if (amount == null) {
    return jsonError(
      400,
      'validation',
      'Сумма должна быть больше нуля, не больше двух знаков после запятой.',
    );
  }
  if (!RegExp(_uuidPattern).hasMatch(firmId)) {
    return jsonError(400, 'validation', 'Выберите подрядчика для этой работы.');
  }
  final firm = await db.firmInCompany(firmId, companyId);
  if (firm == null) return jsonError(404, 'not_found', 'Подрядчик не найден.');
  return (title: title, amount: amount, firmId: firmId);
}

Future<Response> _members(Request request, AppDatabase db, String id) async {
  final opened = await _openProject(request, db, id);
  if (opened is Response) return opened;
  final project = (opened as ({SessionLookup session, ProjectRecord project})).project;
  final members = await db.membersOf(project.id);
  return jsonResponse(200, {
    'members': [for (final member in members) member.toJson()],
  });
}

Future<Response> _addMember(Request request, AppDatabase db, String id) async {
  final opened = await _openProject(request, db, id);
  if (opened is Response) return opened;
  final gate = opened as ({SessionLookup session, ProjectRecord project});
  final csrf = _requireCsrf(request, gate.session);
  if (csrf != null) return csrf;
  final denied = _directorOnly(gate.project);
  if (denied != null) return denied;
  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final json = body as Map<String, dynamic>;
  final userId = (json['userId'] as String?)?.trim() ?? '';
  final role = (json['role'] as String?)?.trim() ?? '';
  final firmId = (json['contractorFirmId'] as String?)?.trim() ?? '';
  if (!RegExp(_uuidPattern).hasMatch(userId) || !_roles.contains(role)) {
    return jsonError(400, 'validation', 'Выберите сотрудника и роль.');
  }
  final user = await db.userInCompany(userId, gate.project.companyId);
  if (user == null) return jsonError(404, 'not_found', 'Сотрудник не найден.');
  if (!user.active) return jsonError(403, 'inactive', 'Эта учётная запись отключена.');
  if (await db.memberExists(gate.project.id, userId)) {
    return jsonError(409, 'conflict', 'Этот человек уже добавлен на объект.');
  }
  String? storedFirm;
  if (role == 'contractor') {
    if (!RegExp(_uuidPattern).hasMatch(firmId)) {
      return jsonError(400, 'validation', 'Для подрядчика выберите его компанию.');
    }
    final firm = await db.firmInCompany(firmId, gate.project.companyId);
    if (firm == null) return jsonError(404, 'not_found', 'Подрядчик не найден.');
    storedFirm = firmId;
  }
  await db.insertMember(
    projectId: gate.project.id,
    userId: userId,
    role: role,
    contractorFirmId: storedFirm,
  );
  return jsonResponse(201, {'userId': userId, 'role': role, 'contractorFirmId': storedFirm});
}

Future<Response> _removeMember(Request request, AppDatabase db, String id, String memberId) async {
  final opened = await _openProject(request, db, id);
  if (opened is Response) return opened;
  final gate = opened as ({SessionLookup session, ProjectRecord project});
  if (!RegExp(_uuidPattern).hasMatch(memberId)) {
    return jsonError(404, 'not_found', 'Участник не найден.');
  }
  final csrf = _requireCsrf(request, gate.session);
  if (csrf != null) return csrf;
  final denied = _directorOnly(gate.project);
  if (denied != null) return denied;
  final member = await db.memberById(gate.project.id, memberId);
  if (member == null) return jsonError(404, 'not_found', 'Участник не найден.');
  if (member.role == 'director' && await db.directorCount(gate.project.id) <= 1) {
    return jsonError(409, 'conflict', 'На объекте должен остаться застройщик.');
  }
  await db.deleteMember(gate.project.id, memberId);
  return Response(204, headers: {'cache-control': 'no-store'});
}

Future<Response> _firms(Request request, AppDatabase db) async {
  final lookup = await _requireSession(request, db);
  if (lookup is Response) return lookup;
  final session = lookup as SessionLookup;
  if (!_companyDirector(session)) return jsonError(403, 'forbidden', 'У вас нет прав на это действие.');
  final firms = await db.firmsOf(session.user!.companyId);
  return jsonResponse(200, {'firms': [for (final firm in firms) firm.toJson()]});
}

Future<Response> _createFirm(Request request, AppDatabase db) async {
  final lookup = await _requireSession(request, db);
  if (lookup is Response) return lookup;
  final session = lookup as SessionLookup;
  final csrf = _requireCsrf(request, session);
  if (csrf != null) return csrf;
  if (!_companyDirector(session)) return jsonError(403, 'forbidden', 'У вас нет прав на это действие.');
  final body = await readJsonObject(request);
  if (body is String) return jsonError(400, 'validation', 'Не получилось обработать запрос. Проверьте данные и попробуйте снова.');
  final json = body as Map<String, dynamic>;
  final name = (json['name'] as String?)?.trim() ?? '';
  final inn = (json['inn'] as String?)?.trim() ?? '';
  final contact = (json['contact'] as String?)?.trim() ?? '';
  if (name.isEmpty || name.length > 200 || contact.isEmpty || contact.length > 200) {
    return jsonError(400, 'validation', 'Напишите название и контакт подрядчика.');
  }
  if (!RegExp(r'^\d{9}$').hasMatch(inn)) {
    return jsonError(400, 'validation', 'ИНН состоит из 9 цифр.');
  }
  if (await db.firmInnTaken(session.user!.companyId, inn)) {
    return jsonError(409, 'conflict', 'Подрядчик с таким ИНН уже есть.');
  }
  final id = await db.insertFirm(
    companyId: session.user!.companyId,
    name: name,
    inn: inn,
    contact: contact,
  );
  return jsonResponse(201, {'id': id, 'name': name, 'inn': inn, 'contact': contact});
}

Future<Response> _companyUsers(Request request, AppDatabase db) async {
  final lookup = await _requireSession(request, db);
  if (lookup is Response) return lookup;
  final session = lookup as SessionLookup;
  if (!_companyDirector(session)) return jsonError(403, 'forbidden', 'У вас нет прав на это действие.');
  final users = await db.companyUsers(session.user!.companyId);
  return jsonResponse(200, {'users': [for (final user in users) user.toJson()]});
}

Map<String, Object?> _userJson(
  UserRecord user,
  List<Membership> memberships, {
  String? csrfToken,
  Map<String, Object?>? bank,
  bool demoSession = false,
}) {
  return {
    'id': user.id,
    'name': user.name,
    'login': user.login,
    'companyId': user.companyId,
    'companyName': user.companyName,
    'active': user.active,
    'platformAdmin': user.platformAdmin,
    'mustChangePassword': user.mustChangePassword,
    'demo': demoSession,
    if (csrfToken != null) 'csrfToken': csrfToken,
    if (bank != null) 'bank': bank,
    'memberships': [
      for (final member in memberships)
        {'projectId': member.projectId, 'role': member.role},
    ],
  };
}

/// A change of the developer in a draw reaches the bank at once: the tranche of
/// the bank is created or refreshed after the developer's change has committed.
const _bankSyncPaths = ['/draws', '/inspections', '/payables', '/requests', '/requirements'];

Future<void> _syncBank(Request request, Response response, AppDatabase db) async {
  if (request.method == 'GET' || request.method == 'HEAD') return;
  if (response.statusCode >= 300) return;
  final path = '/${request.url.path}';
  if (path.startsWith('/api/bank') || !_bankSyncPaths.any(path.contains)) return;
  await bankReconcile(db);
}

/// Limits of a public service: the size of a request, a fixed answer for an
/// unexpected failure (no stack to the client), and the headers a browser needs.
Middleware _safety(AppEnv env) {
  return (Handler inner) {
    return (Request request) async {
      try {
        final response = await applyBodyLimit(env.maxBodyBytes, inner)(request);
        return _withHeaders(response, env);
      } on BodyTooLarge {
        return _withHeaders(jsonError(413, 'too_large', 'Файл слишком большой.'), env);
      } catch (error, stack) {
        if (error is HijackException) rethrow;
        stderr.writeln('[ERROR] ${request.method} ${request.requestedUri.path}: $error\n$stack');
        return _withHeaders(jsonError(500, 'internal', 'Что-то пошло не так. Попробуйте ещё раз.'), env);
      }
    };
  };
}

/// Release build: `flutter build web --release --no-web-resources-cdn`.
/// index.html loads flutter_bootstrap.js and flutter_boot.css, so script-src
/// and style-src stay on 'self'. CanvasKit compiles canvaskit.wasm through
/// WebAssembly.instantiate, which needs 'wasm-unsafe-eval', and the loader
/// starts a blob worker. CanvasKit and the app fonts are on this origin.
const _csp = "default-src 'self'; "
    "script-src 'self' 'wasm-unsafe-eval' blob:; "
    "style-src 'self'; "
    "img-src 'self' data: blob:; "
    "font-src 'self' data:; "
    "connect-src 'self' blob: data:; "
    "worker-src 'self' blob:; "
    "frame-src https://www.openstreetmap.org; "
    "frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'";

Response _withHeaders(Response response, AppEnv env) {
  return response.change(headers: {
    'x-content-type-options': 'nosniff',
    'x-frame-options': 'DENY',
    'referrer-policy': 'same-origin',
    'permissions-policy': 'camera=(), microphone=(), geolocation=()',
    'content-security-policy': _csp,
    if (env.cookieSecure) 'strict-transport-security': 'max-age=31536000; includeSubDomains',
  });
}
