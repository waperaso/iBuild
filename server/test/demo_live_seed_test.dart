// A production database already has the real platform admin. Turning the demo
// on must add the presentation accounts beside it, with the seed password, and
// must not mark the real company as demo.
import 'dart:convert';
import 'dart:io';

import 'package:ibuild_server/ibuild_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const password = 'Pilot-2026-demo';
const testDatabaseUrl =
    'postgres://ibuild:ibuild@localhost:5433/ibuild_test?sslmode=disable';

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
      final existing = await admin.execute(
        "SELECT 1 FROM pg_database WHERE datname = 'ibuild_test'",
      );
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
    await db.insertCompany(name: 'iBuild', inn: '000000000', contact: 'real');
    await seedDemoWorld(db, password: password);
    files = await Directory.systemTemp.createTemp('ibuild-demo-live-');
    handler = buildHandler(
      db: db,
      env: AppEnv(
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
        fileRoot: files.path,
        registrationPerHour: 100,
        demoEnabled: true,
      ),
    );
  });

  tearDownAll(() async {
    await db.close();
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
    await files.delete(recursive: true);
  });

  test('the presentation login can change demo data and the real company stays real', () async {
    final real = await db.owner.execute(
      Sql.named('SELECT is_demo FROM companies WHERE inn = @inn'),
      parameters: {'inn': '000000000'},
    );
    expect(real.single[0], false);

    final director = _Client(handler);
    final entered = await director.login('a.director', password);
    expect(entered.status, 200);
    expect(entered.json['demo'], false);
    final created = await director.post('/api/projects', {
      'name': 'Объект показа',
      'address': 'Ташкент, проверка',
    });
    expect(created.status, 201);

    final visitor = _Client(handler);
    await visitor.csrf();
    final demo = await visitor.post('/api/demo/login', {'role': 'developer'});
    expect(demo.status, 200);
    expect(demo.json['demo'], true);
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

  Future<_Reply> post(String path, Object? body) => _send('POST', path, body: body);

  Future<void> csrf() async {
    final reply = await _send('GET', '/api/auth/csrf');
    _csrf = reply.json['csrfToken'] as String;
  }

  Future<_Reply> login(String login, String password) async {
    await csrf();
    return post('/api/auth/login', {'login': login, 'password': password});
  }
}
