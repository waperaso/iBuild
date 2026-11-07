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

  test('1 mason files a request and the register shows only his row', () async {
    final mason = Client(handler);
    final engineer = Client(handler);
    expect((await mason.login('a.contractor', password)).status, 200);
    expect((await engineer.login('a.contractor2', password)).status, 200);
    final projectId = await _navoi(mason);
    final itemId = await _line(mason, projectId, 'Фундамент');
    final sent = await _ready(mason, projectId, itemId, '25.00', '=CMD("чужая формула")');
    expect(sent.body!['status'], 'submitted');
    final csv = await mason.text('/api/requests.csv');
    expect(csv.contains('Объект;Вид работ;Подрядчик;ID транша'), isTrue);
    expect(csv, contains(sent.body!['id'] as String));
    expect(csv, contains('25.00'));
    expect(csv, contains('Ждёт решения банка'));
    expect(csv, contains('Навои Строй Монтаж'));
    expect(await engineer.text('/api/requests.csv'), isNot(contains(sent.body!['id'])));
    expect((await Client(handler).send('GET', '/api/requests.csv')).status, 401);
  });

  test('2 the second contractor files his own line and cannot see the first', () async {
    final mason = Client(handler);
    final engineer = Client(handler);
    expect((await mason.login('a.contractor', password)).status, 200);
    expect((await engineer.login('a.contractor2', password)).status, 200);
    final projectId = await _navoi(mason);
    final itemId = await _line(engineer, projectId, 'Инженерия');
    final foreign = await _line(mason, projectId, 'Фундамент');
    expect((await engineer.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'budgetItemId': foreign,
      'amount': '10.00',
      'description': 'чужой фундамент',
    })).status, 404);
    final sent = await _ready(engineer, projectId, itemId, '15.00', 'Сети, секция А');
    final own = await engineer.text('/api/requests.csv');
    expect(own, contains(sent.body!['id'] as String));
    expect(own, contains('Навои Инженерные Сети'));
    expect(await mason.text('/api/requests.csv'), isNot(contains(sent.body!['id'])));
  });

  test('3 technical supervision sees both queues and cannot pay or create', () async {
    final tech = Client(handler);
    expect((await tech.login('a.tech', password)).status, 200);
    final projectId = await _navoi(tech);
    final csv = await tech.text('/api/requests.csv?status=submitted');
    expect(csv, contains('Ждёт решения банка'));
    expect(csv, contains('Фундамент'));
    expect(csv, contains('Инженерия'));
    expect((await tech.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'budgetItemId': await _line(tech, projectId, 'Фундамент'),
      'amount': '10.00',
      'description': 'технадзор не создаёт',
    })).status, 403);
    final id = _idOf(csv, 'Фундамент');
    final card = await tech.send('GET', '/api/requests/$id');
    expect((await tech.send('POST', '/api/requests/$id/pay', json: {
      'version': card.body!['version'],
      'paidOn': '2026-10-19',
      'paymentNumber': 'нет',
    }, idempotencyKey: 'tech-pay-no-0001')).status, 403);
  });

  test('4 the bank approves the tranche, records the release, and the register keeps the number', () async {
    final mason = Client(handler);
    final tech = Client(handler);
    final director = Client(handler);
    final bank = Client(handler);
    final other = Client(handler);
    expect((await mason.login('a.contractor', password)).status, 200);
    expect((await tech.login('a.tech', password)).status, 200);
    expect((await director.login('a.director', password)).status, 200);
    expect((await bank.login('a.observer', password)).status, 200);
    expect((await other.login('b.director', password)).status, 200);
    final projectId = await _navoi(director);
    expect((await other.send('GET', '/api/projects/$projectId')).status, 404);
    final csvBefore = await mason.text('/api/requests.csv?status=submitted');
    final id = _idOf(csvBefore, 'Фундамент');
    final card = await tech.send('GET', '/api/requests/$id');
    final checked = await tech.send('POST', '/api/requests/$id/tech', json: {
      'version': card.body!['version'],
      'decision': 'approve',
      'reason': 'Фундамент принят.',
    }, idempotencyKey: 'reg-tech-0001');
    expect(checked.status, 200, reason: checked.raw);
    final approved = await bank.send('POST', '/api/requests/$id/approve', json: {
      'version': checked.body!['version'],
    }, idempotencyKey: 'reg-dir-00001');
    expect(approved.status, 200, reason: approved.raw);
    expect((await bank.send('POST', '/api/requests/$id/pay', json: {
      'version': approved.body!['version'],
      'paidOn': '2026-10-19',
      'paymentNumber': '=ПП-19',
    }, idempotencyKey: 'reg-pay-nofile')).status, 400);
    final proof = await bank.sendBytes(
      'POST',
      '/api/requests/$id/payment-file',
      Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
    );
    expect(proof.status, 201, reason: proof.raw);
    final paid = await bank.send('POST', '/api/requests/$id/pay', json: {
      'version': approved.body!['version'],
      'paidOn': '2026-10-19',
      'paymentNumber': '=ПП-19',
    }, idempotencyKey: 'reg-pay-record');
    expect(paid.status, 200, reason: paid.raw);
    final csv = await director.text('/api/requests.csv?status=paid&project=$projectId');
    expect(csv, contains(id));
    expect(csv, contains('Выплачен'));
    expect(csv, contains('2026-10-19'));
    expect(csv, contains("'=ПП-19"));
    expect(await other.text('/api/requests.csv'), isNot(contains(id)));
  });

  test('5 the bank sees the register and cannot file a tranche', () async {
    final observer = Client(handler);
    final foreign = Client(handler);
    final disabled = Client(handler);
    expect((await observer.login('a.observer', password)).status, 200);
    expect((await foreign.login('b.observer', password)).status, 200);
    expect((await disabled.login('a.disabled', password)).status, 403);
    final projectId = await _navoi(observer);
    final csv = await observer.text('/api/requests.csv?project=$projectId');
    expect(csv, contains('Выплачен'));
    expect(csv, contains('Ждёт решения банка'));
    final id = _idOf(csv, 'Фундамент');
    final card = await observer.send('GET', '/api/requests/$id');
    expect(card.status, 200);
    expect((await observer.send('POST', '/api/requests/$id/approve', json: {
      'version': card.body!['version'],
    }, idempotencyKey: 'bank-approve-001')).status, 409);
    expect((await observer.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'budgetItemId': await _line(observer, projectId, 'Фундамент'),
      'amount': '10.00',
      'description': 'банк не создаёт',
    })).status, 403);
    expect(await foreign.text('/api/requests.csv'), isNot(contains(id)));
    expect((await foreign.send('GET', '/api/requests/$id')).status, 404);
  });

  test('6 developer account can run the full lifecycle from draft to paid alone', () async {
    final dev = Client(handler);
    expect((await dev.login('a.developer', password)).status, 200);
    final projectId = await _navoi(dev);
    final itemId = await _line(dev, projectId, 'Кровля и фасад');

    final draft = await dev.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'budgetItemId': itemId,
      'amount': '40.00',
      'description': 'Тест разработчика: полный проход',
    });
    expect(draft.status, 201, reason: draft.raw);
    final id = draft.body!['id'] as String;

    expect(
      (await dev.sendBytes(
        'POST',
        '/api/requests/$id/files',
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
      )).status,
      201,
    );

    final sub = await dev.send('POST', '/api/requests/$id/submit', json: {
      'version': draft.body!['version'],
    }, idempotencyKey: 'dev-sub-0001');
    expect(sub.status, 200, reason: sub.raw);
    expect(sub.body!['status'], 'submitted');

    final techOk = await dev.send('POST', '/api/requests/$id/tech', json: {
      'version': sub.body!['version'],
      'decision': 'approve',
      'reason': 'Проверено разработчиком',
    }, idempotencyKey: 'dev-tech-001');
    expect(techOk.status, 200, reason: techOk.raw);
    expect(techOk.body!['status'], 'tech_approved');

    final dirOk = await dev.send('POST', '/api/requests/$id/approve', json: {
      'version': techOk.body!['version'],
    }, idempotencyKey: 'dev-dir-0001');
    expect(dirOk.status, 200, reason: dirOk.raw);
    expect(dirOk.body!['status'], 'approved');

    expect(
      (await dev.sendBytes(
        'POST',
        '/api/requests/$id/payment-file',
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
      )).status,
      201,
    );

    final paid = await dev.send('POST', '/api/requests/$id/pay', json: {
      'version': dirOk.body!['version'],
      'paidOn': '2026-10-19',
      'paymentNumber': 'DEV-777',
    }, idempotencyKey: 'dev-pay-0001');
    expect(paid.status, 200, reason: paid.raw);
    expect(paid.body!['status'], 'paid');
    expect(paid.body!['paymentNumber'], 'DEV-777');
  });
}

Future<String> _navoi(Client client) async {
  final rows = (await client.send('GET', '/api/projects')).body!['projects'] as List;
  return (rows.cast<Map<String, dynamic>>().firstWhere((item) => item['name'] == 'ЖК Навои'))['id']
      as String;
}

Future<String> _line(Client client, String projectId, String title) async {
  final items = (await client.send('GET', '/api/projects/$projectId/budget')).body!['items'] as List;
  return (items.cast<Map<String, dynamic>>().firstWhere((item) => item['title'] == title))['id']
      as String;
}

String _idOf(String csv, String line) {
  final row = csv.split('\n').firstWhere((item) => item.contains(line) && item.contains(';'));
  return row.split(';')[3].trim();
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
  expect(created.status, 201, reason: created.raw);
  final id = created.body!['id'] as String;
  expect((await mason.sendBytes('POST', '/api/requests/$id/files', Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]))).status, 201);
  final submitted = await mason.send('POST', '/api/requests/$id/submit', json: {
    'version': created.body!['version'],
  }, idempotencyKey: 'submit-${id.substring(0, 8)}');
  expect(submitted.status, 200, reason: submitted.raw);
  return submitted;
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

  Future<String> text(String path) async {
    final response = await _request('GET', path);
    return response.readAsString();
  }

  Future<Call> send(String method, String path, {Map<String, dynamic>? json, String? idempotencyKey}) async {
    final response = await _request(method, path, json: json, idempotencyKey: idempotencyKey);
    final raw = await response.readAsString();
    Map<String, dynamic>? body;
    if (raw.isNotEmpty && (response.headers['content-type'] ?? '').contains('json')) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) body = decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    if (body?['csrfToken'] is String) csrf = body!['csrfToken'] as String;
    return Call(response.statusCode, body, raw);
  }

  Future<RawCall> sendBytes(String method, String path, Uint8List bytes) async {
    final response = await _request(method, path, bytes: bytes);
    final collected = await response.read().fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
    return RawCall(response.statusCode, utf8.decode(collected, allowMalformed: true));
  }

  Future<Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? json,
    Uint8List? bytes,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      if (cookies.isNotEmpty) 'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
      if (json != null) 'content-type': 'application/json',
      if (bytes != null) 'content-type': 'application/octet-stream',
      if (csrf != null && method != 'GET') 'x-csrf-token': csrf!,
      if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
    };
    final response = await handler(Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: headers,
      body: json == null ? bytes : jsonEncode(json),
    ));
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
    return response;
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
