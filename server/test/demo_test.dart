import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ibuild_server/ibuild_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const password = 'Pilot-2026-demo';
const testDatabaseUrl =
    'postgres://ibuild:ibuild@localhost:5433/ibuild_test?sslmode=disable';

AppEnv _env(String root, {required bool demo}) {
  return AppEnv(
    databaseUrl: testDatabaseUrl,
    host: 'localhost',
    port: 8080,
    seedOnStart: false,
    seedPassword: password,
    webRoot: null,
    cookieSecure: false,
    migrationsDir: 'migrations',
    sessionTtl: const Duration(hours: 12),
    loginFailureLimit: 5,
    loginWindow: const Duration(minutes: 15),
    fileRoot: root,
    registrationPerHour: 100,
    demoEnabled: demo,
  );
}

void main() {
  late AppDatabase db;
  late Handler on;
  late Handler off;
  late Connection lock;
  late Directory files;

  setUpAll(() async {
    final admin = Pool<void>.withUrl('postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable');
    try {
      final existing = await admin.execute("SELECT 1 FROM pg_database WHERE datname = 'ibuild_test'");
      if (existing.isEmpty) await admin.execute('CREATE DATABASE ibuild_test');
    } finally {
      await admin.close();
    }
    lock = await Connection.openFromUrl(testDatabaseUrl);
    await lock.execute('SELECT pg_advisory_lock(424242)');
    db = await AppDatabase.open(testDatabaseUrl);
    await db.migrate('migrations');
    await db.truncateAll();
    await db.owner.execute('TRUNCATE applications CASCADE');

    // A real platform with one admin and one open application.
    final company = await db.insertCompany(name: 'Реал Строй', inn: '309999999', contact: '+998 71 000 00 00');
    await db.insertUser(
      companyId: company,
      name: 'Реальный админ',
      login: 'real.admin',
      passwordHash: hashPassword(password),
    );
    await db.setPlatformAdmin('real.admin', true);
    await db.owner.execute(
      Sql.named('''
        INSERT INTO applications (kind, status, org_name, inn, contact_name, phone, email, region, data, token_hash, consent_at, consent_version)
        VALUES ('developer', 'new', 'Реальная заявка', '308888888', 'Имя', '+998901112233', 'real@example.uz', 'tashkent_city', '{}'::jsonb, 'h', now(), 'v1')
      '''),
    );

    await seedDemoWorld(db);
    files = await Directory.systemTemp.createTemp('ibuild-demo-');
    on = buildHandler(db: db, env: _env(files.path, demo: true));
    off = buildHandler(db: db, env: _env(files.path, demo: false));
  });

  tearDownAll(() async {
    await db.close();
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
    await files.delete(recursive: true);
  });

  test('the demo is off unless it is switched on', () async {
    final visitor = _Client(off);
    expect((await visitor.get('/api/config')).json['demoEnabled'], false);
    await visitor.csrf();
    expect((await visitor.post('/api/demo/login', {'role': 'developer'})).status, 404);
    expect((await _Client(on).get('/api/config')).json['demoEnabled'], true);
  });

  test('every role button opens a demo session that nobody can enter with a password', () async {
    for (final role in ['developer', 'contractor', 'tech', 'bank', 'admin']) {
      final visitor = _Client(on);
      await visitor.csrf();
      final reply = await visitor.post('/api/demo/login', {'role': role});
      expect(reply.status, 200, reason: role);
      expect(reply.json['demo'], true, reason: role);
      expect(reply.json['platformAdmin'], role == 'admin', reason: role);
      expect((await visitor.get('/api/auth/me')).json['demo'], true);
    }
    final visitor = _Client(on);
    await visitor.csrf();
    expect((await visitor.post('/api/demo/login', {'role': 'hacker'})).status, 400);
    expect((await visitor.post('/api/auth/login', {'login': 'a.director', 'password': password})).status, 401);
    expect((await visitor.post('/api/auth/login', {'login': 'a.admin', 'password': ''})).status, 400);
    final noToken = _Client(on);
    expect((await noToken.post('/api/demo/login', {'role': 'developer'})).status, 403);
  });

  test('a demo session can look but cannot change anything', () async {
    final visitor = _Client(on);
    await visitor.csrf();
    expect((await visitor.post('/api/demo/login', {'role': 'developer'})).status, 200);
    expect((await visitor.get('/api/projects')).status, 200);
    final blocked = await visitor.post('/api/projects', {'name': 'Новый', 'address': 'Адрес'});
    expect(blocked.status, 403);
    expect(blocked.json['error'], 'demo_read_only');
    expect((await visitor.post('/api/auth/password', {'current': 'a', 'next': 'bbbbbbbbbbbb'})).status, 403);
    final admin = _Client(on);
    await admin.csrf();
    await admin.post('/api/demo/login', {'role': 'admin'});
    expect((await admin.post('/api/admin/mail/test', {'to': 'x@example.uz'})).status, 403);
  });

  test('real people never see the demo and the demo never sees real data', () async {
    final real = _Client(on);
    expect((await real.login('real.admin', password)).status, 200);
    final realCompanies = ((await real.get('/api/admin/companies')).json['items'] as List).map((e) => (e as Map)['name']).toList();
    expect(realCompanies, ['Реал Строй']);
    final realUsers = ((await real.get('/api/admin/users')).json['items'] as List).map((e) => (e as Map)['login']).toList();
    expect(realUsers, ['real.admin']);
    final realApps = (await real.get('/api/admin/applications')).json;
    expect((realApps['items'] as List).map((e) => (e as Map)['orgName']).toList(), ['Реальная заявка']);
    final realOverview = (await real.get('/api/admin/overview')).json;
    expect((realOverview['counts'] as Map)['banks'], 0);
    expect((realOverview['counts'] as Map)['developers'], 1);

    final demo = _Client(on);
    await demo.csrf();
    await demo.post('/api/demo/login', {'role': 'admin'});
    final demoCompanies = ((await demo.get('/api/admin/companies')).json['items'] as List).map((e) => (e as Map)['name']).toList();
    expect(demoCompanies, isNot(contains('Реал Строй')));
    expect(demoCompanies, contains('Банк Навои'));
    final demoUsers = ((await demo.get('/api/admin/users')).json['items'] as List).map((e) => (e as Map)['login']).toList();
    expect(demoUsers, isNot(contains('real.admin')));
    final demoApps = ((await demo.get('/api/admin/applications')).json['items'] as List);
    expect(demoApps, isNotEmpty);
    expect(demoApps.map((e) => (e as Map)['orgName']), isNot(contains('Реальная заявка')));
    final system = (await demo.get('/api/admin/system')).json;
    expect((system['server'] as Map)['environment'], 'demo');

    final realId = (await db.owner.execute("SELECT id::text FROM applications WHERE org_name = 'Реальная заявка'")).first[0] as String;
    final demoId = (await db.owner.execute('SELECT id::text FROM applications WHERE is_demo LIMIT 1')).first[0] as String;
    expect((await demo.get('/api/admin/applications/$realId')).status, 404);
    expect((await real.get('/api/admin/applications/$demoId')).status, 404);
    expect((await real.get('/api/admin/applications/$realId')).status, 200);
  });

  test('a brand new database holds no data at all', () async {
    final root = Pool<void>.withUrl('postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable');
    try {
      await root.execute('DROP DATABASE IF EXISTS ibuild_empty_test WITH (FORCE)');
      await root.execute('CREATE DATABASE ibuild_empty_test');
    } finally {
      await root.close();
    }
    const url = 'postgres://ibuild:ibuild@localhost:5433/ibuild_empty_test?sslmode=disable';
    final fresh = await AppDatabase.open(url);
    try {
      await fresh.migrate('migrations');
      final tables = await fresh.owner.execute(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' AND table_name NOT IN ('schema_migrations', 'bank_holidays')",
      );
      expect(tables, isNotEmpty);
      for (final row in tables) {
        final name = row[0]! as String;
        final count = await fresh.owner.execute('SELECT count(*)::int FROM "$name"');
        expect(count.first[0], 0, reason: name);
      }
    } finally {
      await fresh.close();
      final cleanup = Pool<void>.withUrl('postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable');
      await cleanup.execute('DROP DATABASE IF EXISTS ibuild_empty_test WITH (FORCE)');
      await cleanup.close();
    }
  });
}

class _Reply {
  _Reply(this.status, this.json);

  final int status;
  final Map<String, dynamic> json;
}

class _Client {
  _Client(this.handler);

  final Handler handler;
  final cookies = <String, String>{};
  String? csrfToken;

  Future<void> csrf() async {
    await get('/api/auth/csrf');
  }

  Future<_Reply> login(String login, String pass) async {
    await csrf();
    return post('/api/auth/login', {'login': login, 'password': pass});
  }

  Map<String, String> _headers({String? token, bool json = false}) => {
    if (cookies.isNotEmpty) 'cookie': cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
    if (json) 'content-type': 'application/json',
    if (csrfToken != null) 'x-csrf-token': csrfToken!,
    if (token != null) 'x-application-token': token,
  };

  Future<Response> getRaw(String path) async {
    return await handler(Request("GET", Uri.parse("http://localhost$path"), headers: _headers()));
  }

  Future<_Reply> get(String path, {String? token}) async {
    final response = await handler(
      Request('GET', Uri.parse('http://localhost$path'), headers: _headers(token: token)),
    );
    return _read(response);
  }

  Future<_Reply> post(String path, Map<String, Object?> body) async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost$path'),
        headers: _headers(json: true),
        body: jsonEncode(body),
      ),
    );
    return _read(response);
  }

  Future<_Reply> upload(String id, String type, Uint8List bytes, {required String token}) async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/applications/$id/documents?type=$type&name=scan.png'),
        headers: _headers(token: token),
        body: bytes,
      ),
    );
    return _read(response);
  }

  Future<_Reply> _read(Response response) async {
    for (final line in response.headersAll['set-cookie'] ?? const <String>[]) {
      final first = line.split(';').first;
      final at = first.indexOf('=');
      if (at <= 0) continue;
      final name = first.substring(0, at).trim();
      final value = first.substring(at + 1).trim();
      if (value.isEmpty) {
        cookies.remove(name);
      } else {
        cookies[name] = value;
      }
      if (name == 'ibuild_csrf') csrfToken = value;
    }
    final raw = await response.readAsString();
    Map<String, dynamic> json = {};
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) json = decoded.map((k, v) => MapEntry(k.toString(), v));
    }
    if (json['csrfToken'] is String) csrfToken = json['csrfToken'] as String;
    return _Reply(response.statusCode, json);
  }
}
