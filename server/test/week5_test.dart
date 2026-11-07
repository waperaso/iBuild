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

  test('payment, director rejection, and a fresh draft keep the budget exact', () async {
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
      expect(
        (await client.send(
          'POST',
          '/api/requests/00000000-0000-4000-8000-000000000099/pay',
          json: {'version': 1, 'paidOn': '2026-10-15', 'paymentNumber': 'ПП-1'},
          idempotencyKey: 'pay-missing-0001',
        )).status,
        404,
        reason: login,
      );
      sessions[login] = client;
    }

    final mason = sessions['a.contractor']!;
    final director = sessions['a.director']!;
    final bank = sessions['a.observer']!;
    final tech = sessions['a.tech']!;
    final projectId = await _projectId(mason);
    final budget = await mason.send('GET', '/api/projects/$projectId/budget');
    final foundation = ((budget.body!['items'] as List).cast<Map<String, dynamic>>())
        .firstWhere((item) => item['title'] == 'Фундамент');
    final itemId = foundation['id'] as String;

    final paid = await _approved(mason, tech, bank, projectId, itemId, '1000.00', 'Бетон секции А');
    final before = await _money(director, projectId);
    expect(before.reserved, '1000.00');
    expect(before.paid, '0.00');

    final bare = await bank.send('POST', '/api/requests/${paid.id}/pay', json: {
      'version': paid.version,
      'paidOn': '2026-10-15',
      'paymentNumber': 'ПП-1842',
    }, idempotencyKey: 'pay-without-file');
    expect(bare.status, 400);
    expect(bare.body!['message'], 'Добавьте подтверждение платежа.');
    expect((await _money(director, projectId)).paid, '0.00');

    final proof = await bank.sendBytes(
      'POST',
      '/api/requests/${paid.id}/payment-file',
      Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
    );
    expect(proof.status, 201, reason: proof.raw);
    expect((await tech.sendBytes('POST', '/api/requests/${paid.id}/payment-file', Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]))).status, 404);
    expect((await director.sendBytes('POST', '/api/requests/${paid.id}/payment-file', Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]))).status, 404);

    final missingNumber = await bank.send('POST', '/api/requests/${paid.id}/pay', json: {
      'version': paid.version,
      'paidOn': '2026-10-15',
      'paymentNumber': ' ',
    }, idempotencyKey: 'pay-missing-number');
    expect(missingNumber.status, 400);
    expect(missingNumber.body!['message'], 'Укажите дату и номер платежа.');

    final recorded = await bank.send('POST', '/api/requests/${paid.id}/pay', json: {
      'version': paid.version,
      'paidOn': '2026-10-15',
      'paymentNumber': 'ПП-1842',
    }, idempotencyKey: 'pay-concrete-001');
    expect(recorded.status, 200);
    expect(recorded.body!['status'], 'paid');
    expect(recorded.body!['paymentNumber'], 'ПП-1842');
    expect(recorded.body!['paidOn'], '2026-10-15');
    final after = await _money(director, projectId);
    expect(after.paid, '1000.00');
    expect(after.reserved, '0.00');
    expect(after.available, before.available);

    final replay = await bank.send('POST', '/api/requests/${paid.id}/pay', json: {
      'version': paid.version,
      'paidOn': '2026-10-15',
      'paymentNumber': 'ПП-1842',
    }, idempotencyKey: 'pay-concrete-001');
    expect(replay.status, 200);
    expect(replay.body!['status'], 'paid');
    final again = await bank.send('POST', '/api/requests/${paid.id}/pay', json: {
      'version': recorded.body!['version'],
      'paidOn': '2026-10-15',
      'paymentNumber': 'ПП-1842',
    }, idempotencyKey: 'pay-concrete-002');
    expect(again.status, 409);
    expect((await _money(director, projectId)).paid, '1000.00');
    expect((await sessions['a.observer']!.send('GET', '/api/requests/${paid.id}')).status, 200);
    expect((await sessions['b.director']!.send('GET', '/api/requests/${paid.id}')).status, 404);
    expect((await tech.send('POST', '/api/requests/${paid.id}/pay', json: {
      'version': recorded.body!['version'],
      'paidOn': '2026-10-15',
      'paymentNumber': 'ПП-9',
    }, idempotencyKey: 'tech-cannot-pay1')).status, 403);

    final rejected = await _untilTech(mason, tech, projectId, itemId, '800.00', 'Кладка секции Б');
    final tooSoon = await bank.send('POST', '/api/requests/${rejected.id}/reject', json: {
      'version': rejected.version - 1,
      'reason': 'рано',
    }, idempotencyKey: 'reject-too-soon1');
    expect(tooSoon.status, 409);
    final empty = await bank.send('POST', '/api/requests/${rejected.id}/reject', json: {
      'version': rejected.version,
      'reason': ' ',
    }, idempotencyKey: 'reject-empty-reason');
    expect(empty.status, 400);
    expect(empty.body!['message'], 'Напишите причину.');
    final declined = await bank.send('POST', '/api/requests/${rejected.id}/reject', json: {
      'version': rejected.version,
      'reason': 'Нет акта скрытых работ.',
    }, idempotencyKey: 'director-reject-01');
    expect(declined.status, 200);
    expect(declined.body!['status'], 'rejected');
    expect((await _money(director, projectId)).reserved, '0.00');
    expect((await _money(director, projectId)).paid, '1000.00');
    final declineAgain = await bank.send('POST', '/api/requests/${rejected.id}/reject', json: {
      'version': declined.body!['version'],
      'reason': 'Нет акта скрытых работ.',
    }, idempotencyKey: 'director-reject-02');
    expect(declineAgain.status, 409);
    expect((await _money(director, projectId)).paid, '1000.00');

    final copied = await mason.send('POST', '/api/requests/${rejected.id}/copy', json: {
      'version': declined.body!['version'],
    }, idempotencyKey: 'copy-rejected-01');
    expect(copied.status, 201);
    expect(copied.body!['status'], 'draft');
    expect(copied.body!['id'], isNot(rejected.id));
    expect(copied.body!['amount'], '800.00');
    expect(copied.body!['files'], isEmpty);
    final actions = ((copied.body!['events'] as List).cast<Map<String, dynamic>>())
        .map((event) => event['action'])
        .toList();
    expect(actions, ['draft_saved']);
    final sameCopy = await mason.send('POST', '/api/requests/${rejected.id}/copy', json: {
      'version': declined.body!['version'],
    }, idempotencyKey: 'copy-rejected-01');
    expect(sameCopy.body!['id'], copied.body!['id']);
    expect((await sessions['a.contractor2']!.send('POST', '/api/requests/${rejected.id}/copy', json: {
      'version': declined.body!['version'],
    }, idempotencyKey: 'copy-other-firm1')).status, 404);
    expect((await director.send('POST', '/api/requests/${rejected.id}/copy', json: {
      'version': declined.body!['version'],
    }, idempotencyKey: 'copy-director-01')).status, 404);
    expect((await _money(mason, projectId)).paid, '1000.00');

    final held = await _approved(mason, tech, bank, projectId, itemId, '20.00', 'Снять до банка');
    final noConfirm = await bank.send('POST', '/api/requests/${held.id}/withdraw', json: {
      'version': held.version,
      'reason': 'Платёж не ушёл',
      'unpaidConfirmed': false,
    }, idempotencyKey: 'withdraw-noconfirm');
    expect(noConfirm.status, 400);
    expect(noConfirm.body!['message'], 'Подтвердите, что платёж ещё не ушёл.');
    expect((await _money(director, projectId)).reserved, '20.00');
    final withdrawn = await bank.send('POST', '/api/requests/${held.id}/withdraw', json: {
      'version': held.version,
      'reason': 'Платёж не ушёл',
      'unpaidConfirmed': true,
    }, idempotencyKey: 'withdraw-held-001');
    expect(withdrawn.status, 200);
    expect(withdrawn.body!['status'], 'cancelled');
    final end = await _money(director, projectId);
    expect(end.reserved, '0.00');
    expect(end.paid, '1000.00');
    expect(end.available, before.available);
    final withdrawAgain = await bank.send('POST', '/api/requests/${held.id}/withdraw', json: {
      'version': withdrawn.body!['version'],
      'reason': 'Платёж не ушёл',
      'unpaidConfirmed': true,
    }, idempotencyKey: 'withdraw-held-002');
    expect(withdrawAgain.status, 409);
    expect((await _money(sessions['a.observer']!, projectId)).paid, '1000.00');
    expect((await _money(mason, projectId)).available, '13399999000.00');
  });
}

Future<_Draft> _approved(
  Client mason,
  Client tech,
  Client director,
  String projectId,
  String itemId,
  String amount,
  String description,
) async {
  final ready = await _untilTech(mason, tech, projectId, itemId, amount, description);
  final approved = await director.send('POST', '/api/requests/${ready.id}/approve', json: {
    'version': ready.version,
  }, idempotencyKey: 'approve-${ready.id.substring(0, 8)}');
  expect(approved.status, 200, reason: approved.body.toString());
  return _Draft(ready.id, approved.body!['version'] as int);
}

Future<_Draft> _untilTech(
  Client mason,
  Client tech,
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
  expect(submitted.status, 200, reason: submitted.body.toString());
  final reviewed = await tech.send('POST', '/api/requests/$id/tech', json: {
    'version': submitted.body!['version'],
    'decision': 'approve',
    'reason': 'Работа на площадке совпадает с заявкой.',
  }, idempotencyKey: 'tech-${id.substring(0, 8)}');
  expect(reviewed.status, 200, reason: reviewed.body.toString());
  return _Draft(id, reviewed.body!['version'] as int);
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
