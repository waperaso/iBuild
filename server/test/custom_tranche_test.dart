import 'dart:convert';

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
    await seedDemo(db, password);
    handler = buildHandler(db: db, env: _env());
  });

  tearDownAll(() async {
    await db.close();
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
  });

  test('a custom tranche type does not set the bank plan', () async {
    final director = Client(handler);
    expect((await director.login('a.director', password)).status, 200);
    final before = await director.send('GET', '/api/projects');
    final project = (before.body!['projects'] as List).cast<Map<String, dynamic>>().singleWhere(
      (item) => item['name'] == 'ЖК Навои',
    );
    final projectId = project['id'] as String;
    final plan = project['plan'];

    final created = await director.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'customTitle': 'Заливка',
      'amount': '1000.00',
      'description': 'Плита секции А',
    }, withCsrf: true);
    expect(created.status, 201, reason: '${created.body}');
    expect(created.body!['lineTitle'], 'Заливка');

    final after = await director.send('GET', '/api/projects/$projectId');
    expect(after.body!['plan'], plan);
    final budget = await director.send('GET', '/api/projects/$projectId/budget');
    final line = (budget.body!['items'] as List).cast<Map<String, dynamic>>().singleWhere(
      (item) => item['title'] == 'Заливка',
    );
    expect(line['amount'], '0.00');

    final bank = Client(handler);
    await bank.login('a.observer', password);
    final denied = await bank.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'customTitle': 'Чужой тип',
      'amount': '10.00',
      'description': '',
    }, withCsrf: true);
    expect(denied.status, 403);

    final other = Client(handler);
    await other.login('b.director', password);
    final hidden = await other.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'customTitle': 'Чужая заливка',
      'amount': '10.00',
      'description': '',
    }, withCsrf: true);
    expect(hidden.status, 404);
  });
}

AppEnv _env() {
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
  );
}

class Call {
  Call(this.status, this.body);
  final int status;
  final Map<String, dynamic>? body;
}

class Client {
  Client(this.handler);
  final Handler handler;
  final cookies = <String, String>{};
  String? csrf;

  Future<Call> login(String login, String password) async {
    await send('GET', '/api/auth/csrf');
    return send('POST', '/api/auth/login', json: {
      'login': login,
      'password': password,
    }, withCsrf: true);
  }

  Future<Call> send(
    String method,
    String path, {
    Map<String, dynamic>? json,
    bool withCsrf = false,
  }) async {
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: {
          if (cookies.isNotEmpty)
            'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
          if (json != null) 'content-type': 'application/json',
          if (withCsrf && csrf != null) 'x-csrf-token': csrf!,
        },
        body: json == null ? null : jsonEncode(json),
      ),
    );
    for (final line in response.headersAll['set-cookie'] ?? const <String>[]) {
      final first = line.split(';').first;
      final separator = first.indexOf('=');
      if (separator <= 0) continue;
      final name = first.substring(0, separator).trim();
      final value = first.substring(separator + 1).trim();
      if (line.toLowerCase().contains('max-age=0') || value.isEmpty) {
        cookies.remove(name);
      } else {
        cookies[name] = value;
      }
      if (name == 'ibuild_csrf') csrf = value;
    }
    final raw = await response.readAsString();
    Map<String, dynamic>? body;
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        body = decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    if (body?['csrfToken'] is String) csrf = body!['csrfToken'] as String;
    return Call(response.statusCode, body);
  }
}
