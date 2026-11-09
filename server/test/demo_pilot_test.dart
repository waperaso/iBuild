// The shipped docker-compose starts with SEED_ON_START=true and
// DEMO_ENABLED=true at the same time. The pilot world is then created with the
// known SEED_PASSWORD, and the demo world marks those same companies as demo.
// Being read-only must follow the session that the demo buttons open, not the
// accounts: otherwise every documented pilot login is read-only on the stand.
import 'dart:convert';
import 'dart:io';

import 'package:ibuild_server/ibuild_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const password = 'Pilot-2026-demo';
const testDatabaseUrl =
    'postgres://ibuild:ibuild@localhost:5433/ibuild_test?sslmode=disable';

AppEnv _env(String root) {
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
    demoEnabled: true,
  );
}

void main() {
  late AppDatabase db;
  late Handler handler;
  late Connection lock;
  late Directory files;

  setUpAll(() async {
    final admin = Pool<void>.withUrl(
      'postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable',
    );
    try {
      final existing = await admin
          .execute("SELECT 1 FROM pg_database WHERE datname = 'ibuild_test'");
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

    // Exactly what bin/server.dart does on the stand, in the same order.
    await seedIfEmpty(db, password);
    await seedPilotBudgetIfMissing(db, password);
    await ensurePlatformAdmin(db, password);
    await ensureBankCabinet(db, password);
    await seedDemoWorld(db);

    files = await Directory.systemTemp.createTemp('ibuild-demo-pilot-');
    handler = buildHandler(db: db, env: _env(files.path));
  });

  tearDownAll(() async {
    await db.close();
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
    await files.delete(recursive: true);
  });

  test('a seeded pilot login signs in with its password and is not read-only', () async {
    for (final login in ['a.director', 'a.observer', 'a.admin', 'a.bankadmin']) {
      final person = _Client(handler);
      final entered = await person.login(login, password);
      expect(entered.status, 200, reason: login);
      expect(entered.json['demo'], false, reason: login);
      expect((await person.get('/api/auth/me')).json['demo'], false, reason: login);
    }

    final director = _Client(handler);
    await director.login('a.director', password);
    final created = await director.post('/api/projects', {
      'name': 'Объект показа',
      'address': 'Ташкент, проверка',
    });
    expect(created.status, 201, reason: 'the presenter must be able to change data');
  });

  test('a session opened by a demo button stays read-only', () async {
    final visitor = _Client(handler);
    await visitor.csrf();
    final entered = await visitor.post('/api/demo/login', {'role': 'developer'});
    expect(entered.status, 200);
    expect(entered.json['demo'], true);
    expect((await visitor.get('/api/projects')).status, 200);
    final blocked = await visitor.post('/api/projects', {'name': 'Н', 'address': 'А'});
    expect(blocked.status, 403);
    expect(blocked.json['error'], 'demo_read_only');
  });
}

class _Reply {
  _Reply(this.status, this.body);

  final int status;
  final String body;

  Map<String, dynamic> get json =>
      body.isEmpty ? {} : jsonDecode(body) as Map<String, dynamic>;
}

class _Client {
  _Client(this.handler);

  final Handler handler;
  final _cookies = <String, String>{};
  String _csrf = '';

  Future<_Reply> _send(String method, String path, {Object? body}) async {
    final request = Request(
      method,
      Uri.parse('http://localhost:8080$path'),
      headers: {
        if (_cookies.isNotEmpty)
          'cookie': _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
        if (_csrf.isNotEmpty) 'x-csrf-token': _csrf,
        if (body != null) 'content-type': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    );
    final reply = await handler(request);
    for (final raw in reply.headersAll['set-cookie'] ?? const <String>[]) {
      final pair = raw.split(';').first.split('=');
      if (pair.length >= 2) _cookies[pair.first] = pair.sublist(1).join('=');
    }
    final text = await reply.readAsString();
    final decoded = text.isEmpty ? null : jsonDecode(text);
    if (decoded is Map && decoded['csrfToken'] is String) {
      _csrf = decoded['csrfToken'] as String;
    }
    return _Reply(reply.statusCode, text);
  }

  Future<_Reply> get(String path) => _send('GET', path);

  Future<_Reply> post(String path, Object? body) => _send('POST', path, body: body);

  Future<void> csrf() async {
    final reply = await get('/api/auth/csrf');
    _csrf = reply.json['csrfToken'] as String;
  }

  Future<_Reply> login(String login, String password) async {
    await csrf();
    return post('/api/auth/login', {'login': login, 'password': password});
  }
}
