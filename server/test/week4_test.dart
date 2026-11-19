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

late AppDatabase db;
late Handler handler;
late Directory files;

void main() {
  late Connection lock;

  setUpAll(() async {
    final admin = Pool.withUrl(
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
    files = await Directory.systemTemp.createTemp('ibuild-files');
    db = await AppDatabase.open(testDatabaseUrl);
    await db.migrate('migrations');
    await db.truncateAll();
    await seedDemo(db, password);
    handler = buildHandler(db: db, env: _env(files.path));
  });

  tearDownAll(() async {
    await db.close();
    if (files.existsSync()) await files.delete(recursive: true);
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
  });

  test('every role follows the request through reserve, review, and approval', () async {
    expect((await Client(handler).login('a.disabled', password)).status, 403);

    final people = [
      'a.director',
      'a.contractor',
      'a.contractor2',
      'a.tech',
      'a.observer',
      'b.director',
      'b.contractor',
      'b.tech',
      'b.observer',
    ];
    final sessions = <String, Client>{};
    for (final login in people) {
      final client = Client(handler);
      expect((await client.login(login, password)).status, 200, reason: login);
      expect((await client.send('GET', '/api/requests')).status, 200, reason: login);
      expect(
        (await client.send('POST', '/api/requests/00000000-0000-4000-8000-000000000099/submit', json: {
          'version': 1,
        }, idempotencyKey: 'missing-request-01')).status,
        404,
        reason: login,
      );
      sessions[login] = client;
    }

    final mason = sessions['a.contractor']!;
    final projectId = await _projectId(mason);
    final budget = await mason.send('GET', '/api/projects/$projectId/budget');
    final foundation = ((budget.body!['items'] as List).cast<Map<String, dynamic>>())
        .firstWhere((item) => item['title'] == 'Фундамент');

    final first = await _draft(mason, projectId, foundation['id'] as String, '3000000000.00', 'Первая');
    final second = await _draft(mason, projectId, foundation['id'] as String, '3000000000.00', 'Вторая');
    final bare = await mason.send('POST', '/api/requests/${first.id}/submit', json: {
      'version': first.version,
    }, idempotencyKey: 'submit-without-photo');
    expect(bare.status, 400);
    expect(bare.body!['message'], 'Добавьте хотя бы одно фото работы.');
    expect((await _money(mason, projectId)).reserved, '0.00');

    await _photo(mason, first.id);
    await _photo(mason, second.id);
    final masonAgain = Client(handler);
    expect((await masonAgain.login('a.contractor', password)).status, 200);

    final raced = await Future.wait([
      mason.send('POST', '/api/requests/${first.id}/submit', json: {'version': first.version}, idempotencyKey: 'submit-first-key'),
      masonAgain.send('POST', '/api/requests/${second.id}/submit', json: {'version': second.version}, idempotencyKey: 'submit-second-key'),
    ]);
    final statuses = raced.map((call) => call.status).toList()..sort();
    expect(statuses, [200, 409]);
    final winner = raced.firstWhere((call) => call.status == 200);
    final loser = raced.firstWhere((call) => call.status == 409);
    expect(loser.body!['message'], 'Сумма больше, чем можно запросить.');
    expect(winner.body!['status'], 'submitted');
    final requestId = winner.body!['id'] as String;
    final submittedVersion = winner.body!['version'] as int;

    final replay = await mason.send('POST', '/api/requests/$requestId/submit', json: {
      'version': submittedVersion - 1,
    }, idempotencyKey: requestId == first.id ? 'submit-first-key' : 'submit-second-key');
    expect(replay.status, 200);
    expect(replay.body!['status'], 'submitted');
    expect((await _money(mason, projectId)).reserved, '3000000000.00');

    final reused = await mason.send('POST', '/api/requests/$requestId/submit', json: {
      'version': submittedVersion,
    }, idempotencyKey: requestId == first.id ? 'submit-first-key' : 'submit-second-key');
    expect(reused.status, 409);
    expect(reused.body!['message'], 'Не получилось отправить. Попробуйте ещё раз.');
    expect((await _money(sessions['a.director']!, projectId)).reserved, '3000000000.00');
    expect((await _money(sessions['a.director']!, projectId)).available, '14500000000.00');
    expect((await mason.send('GET', '/api/projects/$projectId/budget')).body!['locked'], isTrue);

    final edited = await mason.send('PATCH', '/api/requests/$requestId', json: {
      'amount': '10.00',
      'description': 'уже отправлена',
      'budgetItemId': foundation['id'],
    });
    expect(edited.status, 409);

    for (final login in ['a.contractor2', 'b.director', 'b.tech', 'b.observer']) {
      expect((await sessions[login]!.send('GET', '/api/requests/$requestId')).status, 404, reason: login);
    }
    expect((await sessions['a.observer']!.send('GET', '/api/requests/$requestId')).status, 200);
    expect((await sessions['a.tech']!.send('GET', '/api/requests/$requestId')).status, 200);
    expect((await sessions['a.director']!.send('GET', '/api/requests/$requestId')).status, 200);

    expect(
      (await sessions['a.observer']!.send('POST', '/api/requests/$requestId/tech', json: {
        'version': submittedVersion,
        'decision': 'approve',
        'reason': '',
      }, idempotencyKey: 'observer-tech-01')).status,
      403,
    );
    expect(
      (await sessions['a.contractor2']!.send('POST', '/api/requests/$requestId/tech', json: {
        'version': submittedVersion,
        'decision': 'approve',
        'reason': '',
      }, idempotencyKey: 'other-tech-0001')).status,
      404,
    );
    final noReason = await sessions['a.tech']!.send('POST', '/api/requests/$requestId/tech', json: {
      'version': submittedVersion,
      'decision': 'reject',
      'reason': ' ',
    }, idempotencyKey: 'tech-reject-empty');
    expect(noReason.status, 400);
    expect(noReason.body!['message'], 'Напишите причину.');

    final tech = await sessions['a.tech']!.send('POST', '/api/requests/$requestId/tech', json: {
      'version': submittedVersion,
      'decision': 'approve',
      'reason': '',
    }, idempotencyKey: 'tech-approve-key');
    expect(tech.status, 200);
    expect(tech.body!['status'], 'tech_approved');
    final techVersion = tech.body!['version'] as int;
    final again = await sessions['a.tech']!.send('POST', '/api/requests/$requestId/tech', json: {
      'version': techVersion,
      'decision': 'approve',
      'reason': '',
    }, idempotencyKey: 'tech-approve-two');
    expect(again.status, 409);
    expect(again.body!['message'], 'Транш уже изменили. Обновите страницу.');
    expect((await _money(mason, projectId)).reserved, '3000000000.00');

    final agreed = await sessions['a.observer']!.send('POST', '/api/requests/$requestId/approve', json: {
      'version': techVersion,
    }, idempotencyKey: 'director-approve');
    expect(agreed.status, 200);
    expect(agreed.body!['status'], 'approved');
    final repeat = await sessions['a.observer']!.send('POST', '/api/requests/$requestId/approve', json: {
      'version': agreed.body!['version'],
    }, idempotencyKey: 'director-approve-2');
    expect(repeat.status, 409);
    expect((await _money(sessions['a.director']!, projectId)).reserved, '3000000000.00');
    expect((await _money(sessions['a.director']!, projectId)).paid, '0.00');
    final events = (agreed.body!['events'] as List).cast<Map<String, dynamic>>();
    expect(events.map((event) => event['action']), containsAll(['submitted', 'tech_approved', 'approved']));

    final small = await _draft(mason, projectId, foundation['id'] as String, '10.00', 'Короткая');
    await _photo(mason, small.id);
    final sent = await mason.send('POST', '/api/requests/${small.id}/submit', json: {
      'version': small.version,
    }, idempotencyKey: 'submit-small-001');
    expect(sent.status, 200, reason: sent.body.toString());
    expect((await _money(mason, projectId)).reserved, '3000000010.00');
    final cancelled = await mason.send('POST', '/api/requests/${small.id}/cancel', json: {
      'version': sent.body!['version'],
    }, idempotencyKey: 'cancel-small-001');
    expect(cancelled.status, 200);
    expect(cancelled.body!['status'], 'cancelled');
    expect((await _money(mason, projectId)).reserved, '3000000000.00');
    final secondCancel = await mason.send('POST', '/api/requests/${small.id}/cancel', json: {
      'version': cancelled.body!['version'],
    }, idempotencyKey: 'cancel-small-002');
    expect(secondCancel.status, 409);
    expect((await _money(mason, projectId)).reserved, '3000000000.00');
    final replayCancel = await mason.send('POST', '/api/requests/${small.id}/cancel', json: {
      'version': sent.body!['version'],
    }, idempotencyKey: 'cancel-small-001');
    expect(replayCancel.status, 200);
    expect((await _money(sessions['a.observer']!, projectId)).reserved, '3000000000.00');
  });
}

Future<_Draft> _draft(Client client, String projectId, String itemId, String amount, String description) async {
  final created = await client.send('POST', '/api/requests', json: {
    'projectId': projectId,
    'budgetItemId': itemId,
    'amount': amount,
    'description': description,
  });
  expect(created.status, 201, reason: created.body.toString());
  return _Draft(created.body!['id'] as String, created.body!['version'] as int);
}

Future<void> _photo(Client client, String requestId) async {
  final uploaded = await client.sendBytes(
    'POST',
    '/api/requests/$requestId/files',
    Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
  );
  expect(uploaded.status, 201, reason: uploaded.raw);
}

Future<String> _projectId(Client client) async {
  final projects = await client.send('GET', '/api/projects');
  final list = (projects.body!['projects'] as List).cast<Map<String, dynamic>>();
  return list.firstWhere((item) => item['name'] == 'ЖК Навои')['id'] as String;
}

Future<_Money> _money(Client client, String projectId) async {
  final project = await client.send('GET', '/api/projects/$projectId');
  return _Money(
    project.body!['reserved'] as String,
    project.body!['paid'] as String,
    project.body!['available'] as String,
  );
}

class _Draft {
  _Draft(this.id, this.version);
  final String id;
  final int version;
}

class _Money {
  _Money(this.reserved, this.paid, this.available);
  final String reserved;
  final String paid;
  final String available;
}

AppEnv _env(String fileRoot) {
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
    fileRoot: fileRoot,
  );
}

class Client {
  Client(this.handler);

  final Handler handler;
  final cookies = <String, String>{};
  String? csrf;

  Future<Call> login(String login, String password) async {
    await send('GET', '/api/auth/csrf');
    return send('POST', '/api/auth/login', json: {'login': login, 'password': password});
  }

  Future<Call> send(
    String method,
    String path, {
    Map<String, dynamic>? json,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      if (cookies.isNotEmpty) 'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
      if (json != null) 'content-type': 'application/json',
      if (csrf != null && method != 'GET') 'x-csrf-token': csrf!,
      if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
    };
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: headers,
        body: json == null ? null : jsonEncode(json),
      ),
    );
    _cookies(response);
    final raw = await response.readAsString();
    Map<String, dynamic>? body;
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) body = decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    if (body?['csrfToken'] is String) csrf = body!['csrfToken'] as String;
    return Call(response.statusCode, body);
  }

  Future<RawCall> sendBytes(String method, String path, Uint8List bytes) async {
    final headers = <String, String>{
      if (cookies.isNotEmpty) 'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
      'content-type': 'application/octet-stream',
      if (csrf != null) 'x-csrf-token': csrf!,
    };
    final response = await handler(
      Request(method, Uri.parse('http://localhost$path'), headers: headers, body: bytes),
    );
    _cookies(response);
    final collected = await response.read().fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
    return RawCall(response.statusCode, utf8.decode(collected, allowMalformed: true));
  }

  void _cookies(Response response) {
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
  }
}

class Call {
  Call(this.status, this.body);
  final int status;
  final Map<String, dynamic>? body;
}

class RawCall {
  RawCall(this.status, this.raw);
  final int status;
  final String raw;
}
