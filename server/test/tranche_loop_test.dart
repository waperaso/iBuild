import 'dart:convert';
import 'dart:typed_data';

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

  test('the bank approves a submitted request once', () async {
    final director = Client(handler);
    await director.login('a.director', password);
    final projects = await director.send('GET', '/api/projects');
    final project = (projects.body!['projects'] as List).cast<Map<String, dynamic>>().singleWhere(
      (item) => item['name'] == 'ЖК Навои',
    );
    final projectId = project['id'] as String;
    final plan = project['plan'];
    final budget = await director.send('GET', '/api/projects/$projectId/budget');
    final foundation = (budget.body!['items'] as List).cast<Map<String, dynamic>>().singleWhere(
      (item) => item['title'] == 'Фундамент',
    );

    final custom = await director.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'customTitle': 'Заливка',
      'amount': '1000.00',
      'description': 'Плита',
    }, withCsrf: true);
    expect(custom.status, 201, reason: '${custom.body}');
    final unchanged = await director.send('GET', '/api/projects/$projectId');
    expect(unchanged.body!['plan'], plan);

    final bank = Client(handler);
    await bank.login('a.observer', password);
    final planned = await bank.send(
      'PATCH',
      '/api/projects/$projectId/budget/${custom.body!['budgetItemId']}',
      json: {
        'title': 'Заливка',
        'amount': '5000.00',
        'contractorFirmId': foundation['contractorFirmId'],
      },
      withCsrf: true,
    );
    expect(planned.status, 200, reason: '${planned.body}');
    final afterPlan = await director.send('GET', '/api/projects/$projectId/budget');
    final line = (afterPlan.body!['items'] as List).cast<Map<String, dynamic>>().singleWhere(
      (item) => item['title'] == 'Заливка',
    );
    expect(line['amount'], '5000.00');
    expect(line['planSet'], true);

    final draft = await director.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'budgetItemId': foundation['id'],
      'amount': '100.00',
      'description': 'Фундамент',
    }, withCsrf: true);
    expect(draft.status, 201);
    final requestId = draft.body!['id'] as String;
    final photo = await director.sendBytes(
      'POST',
      '/api/requests/$requestId/files',
      Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
    );
    expect(photo.status, 201);
    final sent = await director.send('POST', '/api/requests/$requestId/submit', json: {
      'version': draft.body!['version'],
    }, withCsrf: true, idempotencyKey: 'submit-loop-0001');
    expect(sent.status, 200, reason: '${sent.body}');
    expect(sent.body!['status'], 'submitted');

    final reserved = (await director.send('GET', '/api/projects/$projectId')).body!['reserved'];
    final approved = await bank.send('POST', '/api/requests/$requestId/approve', json: {
      'version': sent.body!['version'],
    }, withCsrf: true, idempotencyKey: 'approve-loop-01');
    expect(approved.status, 200, reason: '${approved.body}');
    expect(approved.body!['status'], 'approved');
    final replay = await bank.send('POST', '/api/requests/$requestId/approve', json: {
      'version': sent.body!['version'],
    }, withCsrf: true, idempotencyKey: 'approve-loop-01');
    expect(replay.status, 200);
    expect((await director.send('GET', '/api/projects/$projectId')).body!['reserved'], reserved);

    final other = Client(handler);
    await other.login('b.director', password);
    expect((await other.send('GET', '/api/requests/$requestId')).status, 404);
    final foreignQueue = await other.send('GET', '/api/notices');
    final foreignIds = [
      for (final item in (foreignQueue.body!['queue'] as List).cast<Map<String, dynamic>>())
        item['id'],
    ];
    expect(foreignIds, isNot(contains(requestId)));
    expect(foreignIds, isNot(contains(custom.body!['id'])));

    final queue = await bank.send('GET', '/api/notices');
    final ids = [
      for (final item in (queue.body!['queue'] as List).cast<Map<String, dynamic>>()) item['id'],
    ];
    expect(ids, contains(requestId));
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

  Future<Call> sendBytes(String method, String path, Uint8List bytes) {
    return _raw(method, path, bytes, 'application/octet-stream', withCsrf: true);
  }

  Future<Call> send(
    String method,
    String path, {
    Map<String, dynamic>? json,
    bool withCsrf = false,
    String? idempotencyKey,
  }) {
    return _raw(
      method,
      path,
      json == null ? null : utf8.encode(jsonEncode(json)),
      json == null ? null : 'application/json',
      withCsrf: withCsrf,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<Call> _raw(
    String method,
    String path,
    List<int>? body,
    String? contentType, {
    bool withCsrf = false,
    String? idempotencyKey,
  }) async {
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: {
          if (cookies.isNotEmpty)
            'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
          if (contentType != null) 'content-type': contentType,
          if (withCsrf && csrf != null) 'x-csrf-token': csrf!,
          if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
        },
        body: body,
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
    Map<String, dynamic>? decoded;
    if (raw.isNotEmpty && (response.headers['content-type'] ?? '').contains('json')) {
      final parsed = jsonDecode(raw);
      if (parsed is Map) {
        decoded = parsed.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    if (decoded?['csrfToken'] is String) csrf = decoded!['csrfToken'] as String;
    return Call(response.statusCode, decoded);
  }
}
