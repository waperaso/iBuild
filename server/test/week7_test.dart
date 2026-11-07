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

  test('a request keeps its full amount and the bank cannot change it', () async {
    final mason = Client(handler);
    final tech = Client(handler);
    final director = Client(handler);
    final observer = Client(handler);
    expect((await mason.login('a.contractor', password)).status, 200);
    expect((await tech.login('a.tech', password)).status, 200);
    expect((await director.login('a.director', password)).status, 200);
    expect((await observer.login('a.observer', password)).status, 200);

    final projectId = ((await mason.send('GET', '/api/projects')).body!['projects'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((item) => item['name'] == 'ЖК Навои')['id'] as String;
    final budget = await mason.send('GET', '/api/projects/$projectId/budget');
    final line = ((budget.body!['items'] as List).cast<Map<String, dynamic>>())
        .firstWhere((item) => item['title'] == 'Фундамент');
    final itemId = line['id'] as String;
    expect(line['available'], matches(RegExp(r'^\d+\.\d{2}$')));

    final before = await _money(director, projectId);
    final first = await _ready(mason, projectId, itemId, '100.00', 'Фундамент, секция В');
    expect(first.status, 200, reason: first.raw);
    expect(first.body!['amount'], '100.00');
    expect(first.body!['status'], 'submitted');
    expect(first.body!['lineAvailable'], isA<String>());
    expect((await _money(director, projectId)).reserved, _plus(before.reserved, '100.00'));

    final id = first.body!['id'];
    expect((await observer.send('POST', '/api/requests/$id/decide', json: {
      'version': first.body!['version'],
      'mode': 'part',
      'reason': '',
    }, idempotencyKey: 'decide-bank-0001')).status, 404);
    expect((await observer.send('POST', '/api/projects/$projectId/funding', json: {
      'paused': true,
    })).status, 404);

    final checked = await tech.send('POST', '/api/requests/$id/tech', json: {
      'version': first.body!['version'],
      'decision': 'approve',
      'reason': 'Объём на площадке совпадает с заявкой.',
      'confirmedAmount': '40.00',
    }, idempotencyKey: 'tech-full-0001');
    expect(checked.status, 200, reason: checked.body.toString());
    expect(checked.body!['status'], 'tech_approved');
    expect(checked.body!['amount'], '100.00');

    expect((await director.send('POST', '/api/requests/$id/approve', json: {
      'version': checked.body!['version'],
    }, idempotencyKey: 'approve-bank-01')).status, 403);

    final approved = await observer.send('POST', '/api/requests/$id/approve', json: {
      'version': checked.body!['version'],
    }, idempotencyKey: 'approve-dir-001');
    expect(approved.status, 200, reason: approved.body.toString());
    expect(approved.body!['status'], 'approved');
    expect(approved.body!['amount'], '100.00');
    expect((await _money(director, projectId)).reserved, _plus(before.reserved, '100.00'));
    expect((await _money(observer, projectId)).paid, before.paid);
  });

  test('a director can file and send a request on their own project', () async {
    final director = Client(handler);
    final mason = Client(handler);
    final tech = Client(handler);
    expect((await director.login('a.director', password)).status, 200);
    expect((await mason.login('a.contractor', password)).status, 200);
    expect((await tech.login('a.tech', password)).status, 200);

    final projectId = ((await director.send('GET', '/api/projects')).body!['projects'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((item) => item['name'] == 'ЖК Навои')['id'] as String;
    final line = ((await director.send('GET', '/api/projects/$projectId/budget')).body!['items'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((item) => item['title'] == 'Фундамент');
    final before = await _money(director, projectId);
    final created = await director.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'budgetItemId': line['id'],
      'amount': '50.00',
      'description': 'Заявка директора, секция Г',
    });
    expect(created.status, 201, reason: created.raw);
    final id = created.body!['id'] as String;
    expect((await mason.send('GET', '/api/requests/$id')).status, 404);
    expect((await tech.send('GET', '/api/requests/$id')).status, 404);

    final photo = await director.sendBytes(
      'POST',
      '/api/requests/$id/files',
      Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
    );
    expect(photo.status, 201, reason: photo.raw);
    final sent = await director.send('POST', '/api/requests/$id/submit', json: {
      'version': created.body!['version'],
    }, idempotencyKey: 'dir-submit-001');
    expect(sent.status, 200, reason: sent.raw);
    expect(sent.body!['status'], 'submitted');
    expect(sent.body!['amount'], '50.00');
    expect((await _money(director, projectId)).reserved, _plus(before.reserved, '50.00'));
    expect((await mason.send('GET', '/api/requests/$id')).status, 200);
    expect((await tech.send('GET', '/api/requests/$id')).status, 200);
    expect((await tech.send('POST', '/api/requests/$id/approve', json: {
      'version': sent.body!['version'],
    }, idempotencyKey: 'tech-no-approve1')).status, 403);
  });

  test('a request goes from draft to paid and the remainder stays exact', () async {
    final mason = Client(handler);
    final tech = Client(handler);
    final director = Client(handler);
    final observer = Client(handler);
    expect((await mason.login('a.contractor', password)).status, 200);
    expect((await tech.login('a.tech', password)).status, 200);
    expect((await director.login('a.director', password)).status, 200);
    expect((await observer.login('a.observer', password)).status, 200);

    final projectId = ((await director.send('GET', '/api/projects')).body!['projects'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((item) => item['name'] == 'ЖК Навои')['id'] as String;
    final itemId = ((await mason.send('GET', '/api/projects/$projectId/budget')).body!['items'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((item) => item['title'] == 'Кровля и фасад')['id'] as String;

    Future<Map<String, dynamic>> money() async {
      final project = await director.send('GET', '/api/projects/$projectId');
      return project.body!;
    }

    final start = await money();
    final submitted = await _ready(mason, projectId, itemId, '80.00', 'Кровля, полный цикл');
    expect(submitted.status, 200, reason: submitted.raw);
    final held = await money();
    expect(held['reserved'], _plus(start['reserved'] as String, '80.00'));
    expect(held['paid'], start['paid']);
    expect(held['available'], _minus(start['available'] as String, '80.00'));

    final id = submitted.body!['id'];
    expect((await tech.send('POST', '/api/requests/$id/tech', json: {
      'version': submitted.body!['version'],
      'decision': 'reject',
      'reason': '',
    }, idempotencyKey: 'cycle-reject-empty')).status, 400);
    expect((await money())['reserved'], held['reserved']);

    final checked = await tech.send('POST', '/api/requests/$id/tech', json: {
      'version': submitted.body!['version'],
      'decision': 'approve',
      'reason': 'Объём на кровле совпадает.',
    }, idempotencyKey: 'cycle-tech-approve');
    expect(checked.status, 200, reason: checked.raw);
    expect(checked.body!['status'], 'tech_approved');
    expect(checked.body!['amount'], '80.00');
    expect((await money())['reserved'], held['reserved']);
    expect((await director.send('POST', '/api/requests/$id/approve', json: {
      'version': checked.body!['version'],
    }, idempotencyKey: 'cycle-bank-approve')).status, 403);

    final approved = await observer.send('POST', '/api/requests/$id/approve', json: {
      'version': checked.body!['version'],
    }, idempotencyKey: 'cycle-dir-approve');
    expect(approved.status, 200, reason: approved.raw);
    expect(approved.body!['status'], 'approved');
    expect(approved.body!['amount'], '80.00');
    expect((await money())['reserved'], held['reserved']);
    expect((await money())['paid'], start['paid']);

    expect((await observer.send('POST', '/api/requests/$id/pay', json: {
      'version': approved.body!['version'],
      'paidOn': '2026-10-18',
      'paymentNumber': 'ПП-цикл',
    }, idempotencyKey: 'cycle-pay-nofile')).status, 400);
    expect((await money())['paid'], start['paid']);

    final proof = await observer.sendBytes(
      'POST',
      '/api/requests/$id/payment-file',
      Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
    );
    expect(proof.status, 201, reason: proof.raw);
    final paid = await observer.send('POST', '/api/requests/$id/pay', json: {
      'version': approved.body!['version'],
      'paidOn': '2026-10-18',
      'paymentNumber': 'ПП-цикл',
    }, idempotencyKey: 'cycle-pay-record');
    expect(paid.status, 200, reason: paid.raw);
    expect(paid.body!['status'], 'paid');
    expect(paid.body!['amount'], '80.00');
    final done = await money();
    expect(done['reserved'], start['reserved']);
    expect(done['paid'], _plus(start['paid'] as String, '80.00'));
    expect(done['available'], held['available']);
    expect((await observer.send('POST', '/api/requests/$id/pay', json: {
      'version': paid.body!['version'],
      'paidOn': '2026-10-18',
      'paymentNumber': 'ПП-цикл',
    }, idempotencyKey: 'cycle-pay-again')).status, 409);
    expect((await money())['paid'], done['paid']);
  });
}

String _minus(String left, String right) {
  final a = left.split('.');
  final b = right.split('.');
  var whole = int.parse(a[0]) - int.parse(b[0]);
  var cents = int.parse(a[1]) - int.parse(b[1]);
  if (cents < 0) {
    whole -= 1;
    cents += 100;
  }
  return '$whole.${cents.toString().padLeft(2, '0')}';
}

Future<Call> _ready(
  Client mason,
  String projectId,
  String itemId,
  String amount,
  String description,
) async {
  final created = await mason.send('POST', '/api/requests', json: {
    'projectId': projectId,
    'budgetItemId': itemId,
    'amount': amount,
    'description': description,
  });
  expect(created.status, 201, reason: created.body.toString());
  final id = created.body!['id'] as String;
  final uploaded = await mason.sendBytes(
    'POST',
    '/api/requests/$id/files',
    Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
  );
  expect(uploaded.status, 201, reason: uploaded.raw);
  final submitted = await mason.send('POST', '/api/requests/$id/submit', json: {
    'version': created.body!['version'],
  }, idempotencyKey: 'submit-${id.substring(0, 8)}');
  if (submitted.status != 200) return submitted;
  return submitted;
}

String _plus(String left, String right) {
  final a = left.split('.');
  final b = right.split('.');
  final cents = int.parse(a[1]) + int.parse(b[1]);
  final whole = int.parse(a[0]) + int.parse(b[0]) + cents ~/ 100;
  return '$whole.${(cents % 100).toString().padLeft(2, '0')}';
}

Future<_Money> _money(Client client, String projectId) async {
  final project = await client.send('GET', '/api/projects/$projectId');
  return _Money(project.body!['reserved'] as String, project.body!['paid'] as String);
}

class _Money {
  _Money(this.reserved, this.paid);
  final String reserved;
  final String paid;
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

  Future<Call> send(String method, String path, {Map<String, dynamic>? json, String? idempotencyKey}) async {
    final headers = <String, String>{
      if (cookies.isNotEmpty) 'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
      if (json != null) 'content-type': 'application/json',
      if (csrf != null && method != 'GET') 'x-csrf-token': csrf!,
      if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
    };
    final response = await handler(Request(method, Uri.parse('http://localhost$path'), headers: headers, body: json == null ? null : jsonEncode(json)));
    _cookies(response);
    final raw = await response.readAsString();
    Map<String, dynamic>? body;
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) body = decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    if (body?['csrfToken'] is String) csrf = body!['csrfToken'] as String;
    return Call(response.statusCode, body, raw);
  }

  Future<RawCall> sendBytes(String method, String path, Uint8List bytes) async {
    final headers = <String, String>{
      if (cookies.isNotEmpty) 'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
      'content-type': 'application/octet-stream',
      if (csrf != null) 'x-csrf-token': csrf!,
    };
    final response = await handler(Request(method, Uri.parse('http://localhost$path'), headers: headers, body: bytes));
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
  Call(this.status, this.body, this.raw);
  final int status;
  final Map<String, dynamic>? body;
  final String raw;
}

class RawCall {
  RawCall(this.status, this.raw);
  final int status;
  final String raw;
}
