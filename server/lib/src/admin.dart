import 'dart:io';
import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'bank_common.dart';
import 'bank_data.dart';
import 'bank_rules_api.dart' show ensureBankDefaults;
import 'db.dart';
import 'http_util.dart';
import 'mail.dart';
import 'vault.dart';
import 'passwords.dart';

/// The panel of the platform administrator: the platform as a whole. Everything
/// here runs as the database owner after the session has been checked to belong
/// to a platform administrator. Every change made under /api/admin is written to
/// `admin_events` by [adminRecord], so nothing needs to remember to log itself.

final _started = DateTime.now().toUtc();
final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

void mountAdmin(Router router, AppDatabase db) {
  router
    ..get('/api/admin/overview', (Request r) => _overview(r, db))
    ..get('/api/admin/companies', (Request r) => _companies(r, db))
    ..get('/api/admin/users', (Request r) => _users(r, db))
    ..post('/api/admin/users', (Request r) => _createUser(r, db))
    ..post('/api/admin/users/<id>/active', (Request r, String id) => _setActive(r, db, id))
    ..post('/api/admin/users/<id>/reset-password', (Request r, String id) => _reset(r, db, id))
    ..get('/api/admin/events', (Request r) => _events(r, db))
    ..get('/api/admin/system', (Request r) => _system(r, db))
    ..get('/api/admin/mail', (Request r) => _mail(r, db))
    ..post('/api/admin/mail/test', (Request r) => _mailTest(r, db))
    ..post('/api/admin/mail/<id>/retry', (Request r, String id) => _mailRetry(r, db, id));
}

Future<Object> _open(Request request, AppDatabase db, {bool mutating = false}) async {
  final opened = mutating ? await bankMutating(request, db) : await bankSession(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!session.user!.platformAdmin) {
    return jsonError(403, 'forbidden', 'Раздел только для администратора iBuild.');
  }
  return session;
}

/// Writes a mutation under /api/admin to the platform journal.
Future<void> adminRecord(Request request, Response response, AppDatabase db) async {
  if (request.method != 'POST' && request.method != 'PATCH' && request.method != 'DELETE') return;
  final path = request.url.path;
  if (!path.startsWith('api/admin/')) return;
  if (response.statusCode < 200 || response.statusCode >= 300) return;
  final token = readCookies(request)[sessionCookieName];
  if (token == null || token.isEmpty) return;
  try {
    final lookup = await db.lookupSession(sha256Hex(token));
    final user = lookup.user;
    if (lookup.state != SessionState.ok || user == null || !user.platformAdmin) return;
    final parts = path.split('/').skip(2).toList();
    final target = parts.firstWhere(_uuid.hasMatch, orElse: () => '');
    final action = parts.where((part) => !_uuid.hasMatch(part)).join('.');
    await db.owner.execute(
      Sql.named('''
        INSERT INTO admin_events (user_id, actor_label, action, target)
        VALUES (@user::uuid, @name, @action, @target)
      '''),
      parameters: {'user': user.id, 'name': user.name, 'action': action, 'target': target},
    );
  } catch (_) {
    // The journal must never turn a finished action into an error.
  }
}

Future<Response> _overview(Request request, AppDatabase db) async {
  final opened = await _open(request, db);
  if (opened is Response) return opened;
  final demo = {'demo': (opened as SessionLookup).user!.isDemo};
  final applications = await bankRows(
    db,
    'SELECT status, count(*)::int AS n FROM applications WHERE is_demo = @demo GROUP BY status',
    demo,
  );
  final counts = await bankRows(db, '''
    SELECT
      (SELECT count(*) FROM companies c WHERE c.is_demo = @demo AND EXISTS (SELECT 1 FROM bank_staff s WHERE s.bank_id = c.id))::int AS banks,
      (SELECT count(*) FROM companies c WHERE c.is_demo = @demo AND NOT EXISTS (SELECT 1 FROM bank_staff s WHERE s.bank_id = c.id))::int AS developers,
      (SELECT count(*) FROM users WHERE is_demo = @demo AND active)::int AS users_active,
      (SELECT count(*) FROM users WHERE is_demo = @demo AND NOT active)::int AS users_disabled,
      (SELECT count(*) FROM projects p JOIN companies c ON c.id = p.company_id WHERE c.is_demo = @demo AND p.active)::int AS projects,
      (SELECT count(*) FROM project_changes x JOIN projects p ON p.id = x.project_id JOIN companies c ON c.id = p.company_id
        WHERE c.is_demo = @demo AND x.status = 'pending')::int AS changes_pending,
      (SELECT count(*) FROM bank_tranches t JOIN companies c ON c.id = t.bank_id WHERE c.is_demo = @demo)::int AS tranches,
      (SELECT count(*) FROM bank_tranches t JOIN companies c ON c.id = t.bank_id WHERE c.is_demo = @demo AND t.signal = 'block')::int AS tranches_blocked,
      (SELECT count(*) FROM login_attempts WHERE NOT @demo AND NOT success AND created_at > now() - interval '24 hours')::int AS failed_logins,
      (SELECT count(*) FROM sessions s JOIN users u ON u.id = s.user_id WHERE u.is_demo = @demo AND s.expires_at > now())::int AS sessions
  ''', demo);
  final oldest = await bankRows(db, '''
    SELECT min(created_at) AS at FROM applications
    WHERE is_demo = @demo AND status IN ('new', 'calling', 'docs_requested', 'in_review')
  ''', demo);
  final recent = await bankRows(db, '''
    SELECT e.action AS action, e.actor_label AS actor, e.target AS target, e.created_at AS at
    FROM admin_events e LEFT JOIN users u ON u.id = e.user_id
    WHERE COALESCE(u.is_demo, false) = @demo
    ORDER BY e.created_at DESC LIMIT 8
  ''', demo);
  return bankOk({
    'applications': {for (final row in applications) row['status'] as String: row['n']},
    'counts': counts.first,
    'oldestOpenApplication': oldest.first['at'],
    'recent': recent,
  });
}

Future<Response> _companies(Request request, AppDatabase db) async {
  final opened = await _open(request, db);
  if (opened is Response) return opened;
  final query = (request.url.queryParameters['q'] ?? '').trim();
  final kind = request.url.queryParameters['kind'] ?? '';
  final demo = (opened as SessionLookup).user!.isDemo;
  final rows = await bankRows(
    db,
    '''
      SELECT c.id::text AS id, c.name AS name, c.inn AS inn, c.contact AS contact, c.created_at AS created_at,
             CASE WHEN EXISTS (SELECT 1 FROM bank_staff s WHERE s.bank_id = c.id) THEN 'bank' ELSE 'developer' END AS kind,
             (SELECT count(*) FROM users u WHERE u.company_id = c.id)::int AS users,
             (SELECT count(*) FROM users u WHERE u.company_id = c.id AND u.active)::int AS users_active,
             (SELECT count(*) FROM projects p WHERE p.company_id = c.id AND p.active)::int AS projects
      FROM companies c
      WHERE c.is_demo = @demo
        AND (@q = '' OR c.name ILIKE '%' || @q || '%' OR c.inn ILIKE '%' || @q || '%')
      ORDER BY c.created_at DESC LIMIT 500
    ''',
    {'q': query, 'demo': demo},
  );
  final projects = await bankRows(
    db,
    '''
      SELECT p.company_id::text AS company_id, p.id::text AS id, p.name AS name
      FROM projects p
      JOIN companies c ON c.id = p.company_id
      WHERE c.is_demo = @demo AND p.active
      ORDER BY p.name
    ''',
    {'demo': demo},
  );
  final firms = await bankRows(
    db,
    '''
      SELECT f.owner_company_id::text AS company_id, f.id::text AS id, f.name AS name
      FROM contractor_firms f
      JOIN companies c ON c.id = f.owner_company_id
      WHERE c.is_demo = @demo
      ORDER BY f.name
    ''',
    {'demo': demo},
  );
  final filtered = kind == 'bank' || kind == 'developer' ? rows.where((row) => row['kind'] == kind) : rows;
  return bankOk({
    'items': [
      for (final row in filtered)
        {
          ...row,
          'projects': [
            for (final project in projects)
              if (project['company_id'] == row['id']) {'id': project['id'], 'name': project['name']},
          ],
          'firms': [
            for (final firm in firms)
              if (firm['company_id'] == row['id']) {'id': firm['id'], 'name': firm['name']},
          ],
        },
    ],
  });
}

Future<Response> _users(Request request, AppDatabase db) async {
  final opened = await _open(request, db);
  if (opened is Response) return opened;
  final query = (request.url.queryParameters['q'] ?? '').trim();
  final company = request.url.queryParameters['company'] ?? '';
  if (company.isNotEmpty && !_uuid.hasMatch(company)) return jsonError(400, 'validation', 'Компания указана неверно');
  final rows = await bankRows(
    db,
    '''
      SELECT u.id::text AS id, u.name AS name, u.login AS login, u.active AS active,
             u.platform_admin AS platform_admin, u.created_at AS created_at,
             c.id::text AS company_id, c.name AS company,
             (SELECT s.role FROM bank_staff s WHERE s.user_id = u.id) AS bank_role,
             (SELECT max(created_at) FROM sessions s WHERE s.user_id = u.id) AS last_seen
      FROM users u JOIN companies c ON c.id = u.company_id
      WHERE u.is_demo = @demo
        AND (@q = '' OR u.name ILIKE '%' || @q || '%' OR u.login ILIKE '%' || @q || '%' OR c.name ILIKE '%' || @q || '%')
        AND (@company = '' OR c.id = @company::uuid)
      ORDER BY c.name, u.name LIMIT 500
    ''',
    {'q': query, 'company': company, 'demo': (opened as SessionLookup).user!.isDemo},
  );
  return bankOk({'items': rows});
}

const _bankRoles = {'specialist', 'expert', 'head', 'committee', 'risk', 'audit', 'admin'};
const _projectRoles = {'director', 'developer', 'tech', 'observer', 'contractor'};

class _Assignment {
  const _Assignment(this.projectId, this.role, this.firmId);
  final String projectId;
  final String role;
  final String firmId;
}

/// Creates an account by hand: in an existing company, or together with a new
/// one (`company`: name, inn, kind developer|bank). The temporary password is
/// shown once; the person has to replace it on first sign-in.
Future<Response> _createUser(Request request, AppDatabase db) async {
  final opened = await _open(request, db, mutating: true);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  final body = await bankBody(request);
  if (body == null) return jsonError(400, 'validation', 'Не удалось прочитать данные');
  final name = (body['name'] as String? ?? '').trim();
  final login = (body['login'] as String? ?? '').trim().toLowerCase();
  final role = (body['role'] as String? ?? '').trim();
  var companyId = (body['companyId'] as String? ?? '').trim();
  final newCompany = body['company'];
  if (name.length < 2 || name.length > 120) return jsonError(400, 'validation', 'Укажите имя человека');
  if (login.length < 3 || login.length > 120 || login.contains(' ')) {
    return jsonError(400, 'validation', 'Логин: от 3 знаков, без пробелов');
  }
  if (companyId.isEmpty && newCompany is! Map) return jsonError(400, 'validation', 'Выберите организацию');
  if (companyId.isNotEmpty && !_uuid.hasMatch(companyId)) return jsonError(400, 'validation', 'Организация указана неверно');

  final parsed = _readAssignments(body['assignments']);
  if (parsed is String) return jsonError(400, 'validation', parsed);
  final assignments = parsed as List<_Assignment>;
  final password = _temporaryPassword();
  try {
    final result = await db.owner.runTx((tx) async {
      var bank = false;
      if (newCompany is Map) {
        final companyName = (newCompany['name'] as String? ?? '').trim();
        final inn = (newCompany['inn'] as String? ?? '').trim();
        bank = newCompany['kind'] == 'bank';
        if (companyName.length < 2 || inn.length < 5) {
          throw _Invalid('Для новой организации укажите название и ИНН');
        }
        final created = await tx.execute(
          Sql.named('INSERT INTO companies (name, inn, contact, is_demo) VALUES (@name, @inn, @contact, @demo) RETURNING id::text'),
          parameters: {'name': companyName, 'inn': inn, 'contact': name, 'demo': session.user!.isDemo},
        );
        companyId = created.first[0]! as String;
        if (bank) {
          await tx.execute(
            Sql.named("INSERT INTO bank_profiles (company_id, department) VALUES (@id::uuid, '')"),
            parameters: {'id': companyId},
          );
        }
      } else {
        final found = await tx.execute(
          Sql.named(
            'SELECT EXISTS (SELECT 1 FROM bank_profiles b WHERE b.company_id = c.id) FROM companies c WHERE c.id = @id::uuid AND c.is_demo = @demo',
          ),
          parameters: {'id': companyId, 'demo': session.user!.isDemo},
        );
        if (found.isEmpty) throw _Invalid('Организация не найдена');
        bank = found.first[0] == true;
      }
      if (bank && assignments.isNotEmpty) {
        throw _Invalid('Сотруднику банка роль задаётся в банке, а не на объекте застройщика.');
      }
      if (bank && !_bankRoles.contains(role)) throw _Invalid('Выберите роль сотрудника банка');
      if (!bank && role.isNotEmpty && !_projectRoles.contains(role)) throw _Invalid('Выберите роль на объекте');
      final user = await tx.execute(
        Sql.named('''
          INSERT INTO users (company_id, name, login, password_hash, active, must_change_password, is_demo)
          VALUES (@company::uuid, @name, @login, @hash, true, true, @demo)
          RETURNING id::text
        '''),
        parameters: {
          'company': companyId,
          'name': name,
          'login': login,
          'hash': hashPassword(password),
          'demo': session.user!.isDemo,
        },
      );
      final userId = user.first[0]! as String;
      if (bank) {
        await ensureBankDefaults(tx, companyId);
        await tx.execute(
          Sql.named('''
            INSERT INTO bank_staff (bank_id, user_id, role, title, branch)
            VALUES (@bank::uuid, @user::uuid, @role, @title, '')
          '''),
          parameters: {'bank': companyId, 'user': userId, 'role': role, 'title': (body['title'] as String? ?? '').trim()},
        );
        if (role == 'head' || role == 'committee') {
          await tx.execute(
            Sql.named('''
              INSERT INTO bank_group_members (group_id, user_id, title, branch)
              SELECT g.id, @user::uuid, @title, ''
              FROM bank_groups g
              WHERE g.bank_id = @bank::uuid AND g.code = @code
              ON CONFLICT (group_id, user_id) DO NOTHING
            '''),
            parameters: {
              'user': userId,
              'bank': companyId,
              'title': (body['title'] as String? ?? '').trim(),
              'code': role == 'head' ? 'heads' : 'committee',
            },
          );
        }
      } else {
        final firstProject = body['firstProject'];
        if (firstProject is Map && role == 'director' && assignments.isEmpty) {
          final projectName = '${firstProject['name'] ?? ''}'.trim();
          final projectAddress = '${firstProject['address'] ?? ''}'.trim();
          if (projectName.length < 2 || projectAddress.length < 2) {
            throw _Invalid('Напишите название и адрес первого объекта.');
          }
          final existing = await tx.execute(
            Sql.named('SELECT count(*) FROM projects WHERE company_id = @company::uuid'),
            parameters: {'company': companyId},
          );
          if ((existing.first[0]! as int) > 0) {
            throw _Invalid('У организации уже есть объекты. Отметьте их в списке.');
          }
          final project = await tx.execute(
            Sql.named('''
              INSERT INTO projects (company_id, name, address)
              VALUES (@company::uuid, @name, @address)
              RETURNING id::text
            '''),
            parameters: {'company': companyId, 'name': projectName, 'address': projectAddress},
          );
          await tx.execute(
            Sql.named('''
              INSERT INTO project_members (project_id, user_id, role)
              VALUES (@project::uuid, @user::uuid, 'director')
            '''),
            parameters: {'project': project.first[0], 'user': userId},
          );
        }
        for (final item in assignments) {
          if (item.role == 'contractor') {
            final firm = await tx.execute(
              Sql.named('''
                SELECT 1 FROM contractor_firms
                WHERE id = @firm::uuid AND owner_company_id = @company::uuid
              '''),
              parameters: {'firm': item.firmId, 'company': companyId},
            );
            if (firm.isEmpty) throw _Invalid('Подрядчик не найден.');
          }
          final placed = await tx.execute(
            Sql.named('''
              INSERT INTO project_members (project_id, user_id, role, contractor_company_id)
              SELECT p.id, @user::uuid, @role, @firm::uuid
              FROM projects p
              WHERE p.id = @project::uuid AND p.company_id = @company::uuid AND p.active
              RETURNING project_id::text
            '''),
            parameters: {
              'user': userId,
              'company': companyId,
              'project': item.projectId,
              'role': item.role,
              'firm': item.role == 'contractor' ? item.firmId : null,
            },
          );
          if (placed.isEmpty) throw _Invalid('Этот объект не принадлежит выбранной организации.');
        }
      }
      return userId;
    });
    return bankOk({'ok': true, 'id': result, 'login': login, 'password': password});
  } on _Invalid catch (error) {
    return jsonError(400, 'validation', error.message);
  } on ServerException catch (error) {
    if (error.code == '23505') return jsonError(409, 'conflict', 'Такой логин или ИНН уже есть в системе');
    rethrow;
  }
}

class _Invalid implements Exception {
  _Invalid(this.message);
  final String message;
}

/// Project access is whatever the administrator marked. A role by itself does
/// not put the person on every project of the company.
Object _readAssignments(Object? raw) {
  if (raw == null) return const <_Assignment>[];
  if (raw is! List) return 'Укажите объект и роль на нём.';
  final seen = <String>{};
  final items = <_Assignment>[];
  for (final entry in raw) {
    if (entry is! Map) return 'Укажите объект и роль на нём.';
    final projectId = '${entry['projectId'] ?? ''}'.trim();
    final role = '${entry['role'] ?? ''}'.trim();
    final firmId = '${entry['contractorFirmId'] ?? ''}'.trim();
    if (!_uuid.hasMatch(projectId) || !_projectRoles.contains(role)) {
      return 'Укажите объект и роль на нём.';
    }
    if (!seen.add(projectId)) {
      return 'Один человек не может получить две роли на одном объекте.';
    }
    if (role == 'contractor' && !_uuid.hasMatch(firmId)) {
      return 'Для подрядчика выберите его компанию.';
    }
    items.add(_Assignment(projectId, role, firmId));
  }
  return items;
}

Future<Response> _setActive(Request request, AppDatabase db, String id) async {
  final opened = await _open(request, db, mutating: true);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  if (!_uuid.hasMatch(id)) return jsonError(404, 'not_found', 'Пользователь не найден');
  final body = await bankBody(request);
  final active = body?['active'];
  if (active is! bool) return jsonError(400, 'validation', 'Укажите, включить или отключить');
  if (id == session.user!.id && !active) {
    return jsonError(409, 'self', 'Нельзя отключить самого себя');
  }
  final updated = await bankRows(
    db,
    'UPDATE users SET active = @active WHERE id = @id::uuid AND is_demo = @demo RETURNING id::text AS id',
    {'active': active, 'id': id, 'demo': session.user!.isDemo},
  );
  if (updated.isEmpty) return jsonError(404, 'not_found', 'Пользователь не найден');
  if (!active) {
    await db.owner.execute(Sql.named('DELETE FROM sessions WHERE user_id = @id::uuid'), parameters: {'id': id});
  }
  return bankOk({'ok': true, 'active': active});
}

String _temporaryPassword() {
  const letters = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random.secure();
  return List.generate(14, (_) => letters[random.nextInt(letters.length)]).join();
}

/// A new password is shown once, to the administrator, who hands it over. The
/// person's other sessions end at once.
Future<Response> _reset(Request request, AppDatabase db, String id) async {
  final opened = await _open(request, db, mutating: true);
  if (opened is Response) return opened;
  if (!_uuid.hasMatch(id)) return jsonError(404, 'not_found', 'Пользователь не найден');
  final password = _temporaryPassword();
  final updated = await bankRows(
    db,
    'UPDATE users SET password_hash = @hash, must_change_password = true WHERE id = @id::uuid AND is_demo = @demo RETURNING id::text AS id',
    {'hash': hashPassword(password), 'id': id, 'demo': (opened as SessionLookup).user!.isDemo},
  );
  if (updated.isEmpty) return jsonError(404, 'not_found', 'Пользователь не найден');
  await db.owner.execute(Sql.named('DELETE FROM sessions WHERE user_id = @id::uuid'), parameters: {'id': id});
  return bankOk({'password': password});
}

Future<Response> _events(Request request, AppDatabase db) async {
  final opened = await _open(request, db);
  if (opened is Response) return opened;
  final query = request.url.queryParameters;
  final action = (query['action'] ?? '').trim();
  final person = (query['q'] ?? '').trim();
  final limit = (int.tryParse(query['limit'] ?? '') ?? 100).clamp(1, 500);
  final rows = await bankRows(
    db,
    '''
      SELECT e.id::text AS id, e.action AS action, e.actor_label AS actor, e.target AS target,
             e.created_at AS at, COALESCE(t.name, c.name, a.org_name, '') AS target_name
      FROM admin_events e
      LEFT JOIN users t ON e.target ~ '^[0-9a-f-]{36}\$' AND t.id::text = e.target
      LEFT JOIN companies c ON e.target ~ '^[0-9a-f-]{36}\$' AND c.id::text = e.target
      LEFT JOIN applications a ON e.target ~ '^[0-9a-f-]{36}\$' AND a.id::text = e.target
      LEFT JOIN users au ON au.id = e.user_id
      WHERE COALESCE(au.is_demo, false) = @demo
        AND (@action = '' OR e.action = @action)
        AND (@q = '' OR e.actor_label ILIKE '%' || @q || '%')
      ORDER BY e.created_at DESC LIMIT @limit
    ''',
    {'action': action, 'q': person, 'limit': limit, 'demo': (opened as SessionLookup).user!.isDemo},
  );
  final actions = await bankRows(
    db,
    'SELECT DISTINCT e.action AS action FROM admin_events e LEFT JOIN users au ON au.id = e.user_id WHERE COALESCE(au.is_demo, false) = @demo ORDER BY action',
    {'demo': opened.user!.isDemo},
  );
  return bankOk({'items': rows, 'actions': [for (final row in actions) row['action']]});
}

Future<Response> _system(Request request, AppDatabase db) async {
  final opened = await _open(request, db);
  if (opened is Response) return opened;
  if ((opened as SessionLookup).user!.isDemo) {
    // The demo never shows the real server, database size or backups.
    return bankOk({
      'database': {'ok': true, 'latencyMs': 4, 'version': 'PostgreSQL', 'sizeBytes': 0},
      'migrations': {'n': 0, 'last': null},
      'tables': <Object?>[],
      'server': {
        'startedAt': _started.toIso8601String(),
        'uptimeSeconds': DateTime.now().toUtc().difference(_started).inSeconds,
        'environment': 'demo',
        'version': 'demo',
      },
      'backup': null,
    });
  }
  final started = DateTime.now();
  final probe = await bankRows(db, 'SELECT now() AS at, version() AS version, pg_database_size(current_database()) AS size');
  final latency = DateTime.now().difference(started).inMilliseconds;
  final migrations = await bankRows(
    db,
    'SELECT count(*)::int AS n, max(version) AS last FROM schema_migrations',
  );
  final tables = await bankRows(db, '''
    SELECT relname AS name, n_live_tup::bigint AS rows FROM pg_stat_user_tables
    ORDER BY n_live_tup DESC LIMIT 12
  ''');
  final backups = _latestBackup();
  return bankOk({
    'database': {
      'ok': true,
      'latencyMs': latency,
      'version': (probe.first['version'] as String).split(' ').take(2).join(' '),
      'sizeBytes': bankInt(probe.first['size']),
    },
    'migrations': migrations.first,
    'tables': tables,
    'server': {
      'startedAt': _started.toIso8601String(),
      'uptimeSeconds': DateTime.now().toUtc().difference(_started).inSeconds,
      'environment': Platform.environment['APP_ENV'] ?? 'development',
      'version': Platform.environment['APP_VERSION'] ?? 'dev',
    },
    'backup': backups,
  });
}

/// The newest backup file that is visible to the server, when a folder is mounted.
Map<String, Object?>? _latestBackup() {
  final path = Platform.environment['BACKUP_DIR'];
  if (path == null || path.isEmpty) return null;
  final directory = Directory(path);
  if (!directory.existsSync()) return null;
  File? newest;
  for (final entity in directory.listSync(recursive: true).whereType<File>()) {
    if (!entity.path.endsWith('.dump')) continue;
    if (newest == null || entity.lastModifiedSync().isAfter(newest.lastModifiedSync())) newest = entity;
  }
  if (newest == null) return null;
  return {
    'file': newest.uri.pathSegments.last,
    'at': newest.lastModifiedSync().toUtc().toIso8601String(),
    'sizeBytes': newest.lengthSync(),
  };
}

Future<Response> _mail(Request request, AppDatabase db) async {
  final opened = await _open(request, db);
  if (opened is Response) return opened;
  final rows = await bankRows(
    db,
    '''
      SELECT m.id::text AS id, m.kind AS kind, m.to_email AS "to", m.subject AS subject, m.status AS status,
             m.error AS error, m.attachment_name AS attachment, m.created_at AS at, m.sent_at AS sent_at,
             COALESCE(c.name, '') AS bank
      FROM mail_outbox m LEFT JOIN companies c ON c.id = m.bank_id
      WHERE COALESCE(c.is_demo, false) = @demo
      ORDER BY m.created_at DESC LIMIT 100
    ''',
    {'demo': (opened as SessionLookup).user!.isDemo},
  );
  final counts = await bankRows(
    db,
    'SELECT m.status AS status, count(*) AS n FROM mail_outbox m LEFT JOIN companies c ON c.id = m.bank_id WHERE COALESCE(c.is_demo, false) = @demo GROUP BY m.status',
    {'demo': opened.user!.isDemo},
  );
  // The body never leaves the database in clear text; the admin sees the subject only.
  final items = [
    for (final row in rows) {...row, 'subject': await Vault.open(row['subject']! as String)},
  ];
  return bankOk({
    'connected': mailConfig.ready,
    'from': mailConfig.ready ? mailConfig.from : '',
    'counts': {for (final row in counts) row['status']: bankInt(row['n'])},
    'items': items,
  });
}

Future<Response> _mailTest(Request request, AppDatabase db) async {
  final opened = await _open(request, db, mutating: true);
  if (opened is Response) return opened;
  final body = await bankBody(request);
  final to = (body?['to'] as String? ?? '').trim();
  if (!isMailAddress(to)) return jsonError(400, 'validation', 'Проверьте адрес почты');
  final status = await sendMail(
    db,
    to: to,
    subject: 'iBuild: проверка почты',
    body: 'Это тестовое письмо из панели администратора iBuild. Если вы его читаете, почта подключена.',
    kind: 'test',
  );
  return bankOk({'ok': true, 'mail': status});
}

Future<Response> _mailRetry(Request request, AppDatabase db, String id) async {
  final opened = await _open(request, db, mutating: true);
  if (opened is Response) return opened;
  if (!_uuid.hasMatch(id)) return jsonError(404, 'not_found', 'Письмо не найдено');
  if (!mailConfig.ready) return jsonError(409, 'mail_off', 'Почта не подключена');
  final rows = await bankRows(
    db,
    "SELECT to_email, subject, body FROM mail_outbox WHERE id = @id::uuid AND status <> 'sent' AND attachment_name = ''",
    {'id': id},
  );
  if (rows.isEmpty) return jsonError(404, 'not_found', 'Письмо не найдено или уже отправлено');
  final status = await deliver(db, id, rows.first['to_email']! as String, await Vault.open(rows.first['subject']! as String), await Vault.open(rows.first['body']! as String), null);
  return bankOk({'ok': true, 'mail': status});
}
