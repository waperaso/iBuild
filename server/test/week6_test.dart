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

  test('a request goes to technical supervision or the bank without moving money early', () async {
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
    final members = ((await mason.send('GET', '/api/projects/$projectId/members')).body!['members']
            as List)
        .cast<Map<String, dynamic>>();
    String person(String role) =>
        members.firstWhere((item) => item['role'] == role)['userId'] as String;
    final directorId = person('director');
    final techId = person('tech');
    final observerId = person('observer');

    final budget = await mason.send('GET', '/api/projects/$projectId/budget');
    final itemId = ((budget.body!['items'] as List).cast<Map<String, dynamic>>())
        .firstWhere((item) => item['title'] == 'Фундамент')['id'] as String;

    final draft = await _draft(mason, projectId, itemId, '100.00', 'Фундамент, секция В');
    final tooSoon = await mason.send('POST', '/api/requests/${draft.id}/submit', json: {
      'version': draft.version,
      'addresseeUserId': directorId,
    }, idempotencyKey: 'submit-director-1');
    expect(tooSoon.status, 400);
    expect(tooSoon.body!['message'], 'Транш можно отправить технадзору или в банк.');
    expect((await _money(director, projectId)).reserved, '0.00');

    final addressed = await mason.send('POST', '/api/requests/${draft.id}/submit', json: {
      'version': draft.version,
      'addresseeUserId': observerId,
    }, idempotencyKey: 'submit-bank-0001');
    expect(addressed.status, 200, reason: addressed.body.toString());
    expect(addressed.body!['status'], 'submitted');
    expect(addressed.body!['forBank'], true);
    expect(addressed.body!['bankSent'], false);
    expect(addressed.body!['addresseeUserId'], observerId);
    expect((await _money(director, projectId)).reserved, '100.00');

    final early = await director.send('POST', '/api/requests/${draft.id}/deliver', json: {
      'version': addressed.body!['version'],
      'addresseeUserId': observerId,
    }, idempotencyKey: 'deliver-early-01');
    expect(early.status, 400);
    expect(early.body!['message'], 'В банк транш отправляет застройщик после одобрения.');
    expect((await _money(director, projectId)).reserved, '100.00');

    final checked = await tech.send('POST', '/api/requests/${draft.id}/tech', json: {
      'version': addressed.body!['version'],
      'decision': 'approve',
      'reason': '',
    }, idempotencyKey: 'tech-${draft.id.substring(0, 8)}');
    expect(checked.status, 200, reason: checked.body.toString());
    final approved = await observer.send('POST', '/api/requests/${draft.id}/approve', json: {
      'version': checked.body!['version'],
    }, idempotencyKey: 'approve-${draft.id.substring(0, 8)}');
    expect(approved.status, 200, reason: approved.body.toString());

    final passed = await director.send('POST', '/api/requests/${draft.id}/deliver', json: {
      'version': approved.body!['version'],
      'addresseeUserId': techId,
    }, idempotencyKey: 'forward-tech-01');
    expect(passed.status, 200, reason: passed.body.toString());
    expect(passed.body!['status'], 'approved');
    expect(passed.body!['addresseeRole'], 'tech');
    expect(passed.body!['bankSent'], false);
    expect((await _money(director, projectId)).reserved, '100.00');
    expect((await _money(director, projectId)).paid, '0.00');

    final sent = await director.send('POST', '/api/requests/${draft.id}/deliver', json: {
      'version': passed.body!['version'],
      'addresseeUserId': observerId,
    }, idempotencyKey: 'deliver-bank-01');
    expect(sent.status, 200, reason: sent.body.toString());
    expect(sent.body!['status'], 'approved');
    expect(sent.body!['forBank'], true);
    expect(sent.body!['bankSent'], true);
    expect(sent.body!['addresseeRole'], 'observer');
    final again = await director.send('POST', '/api/requests/${draft.id}/deliver', json: {
      'version': passed.body!['version'],
      'addresseeUserId': observerId,
    }, idempotencyKey: 'deliver-bank-01');
    expect(again.status, 200);
    expect(again.body!['version'], sent.body!['version']);
    final second = await director.send('POST', '/api/requests/${draft.id}/deliver', json: {
      'version': sent.body!['version'],
      'addresseeUserId': observerId,
    }, idempotencyKey: 'deliver-bank-02');
    expect(second.status, 409);
    expect(second.body!['message'], 'Транш уже отправлен в банк.');
    expect((await _money(director, projectId)).reserved, '100.00');
    expect((await _money(observer, projectId)).paid, '0.00');

    expect((await observer.send('POST', '/api/requests/${draft.id}/deliver', json: {
      'version': sent.body!['version'],
      'addresseeUserId': techId,
    }, idempotencyKey: 'deliver-observer1')).status, 403);
    expect((await mason.send('POST', '/api/requests/${draft.id}/deliver', json: {
      'version': sent.body!['version'],
      'addresseeUserId': techId,
    }, idempotencyKey: 'deliver-mason-01')).status, 404);

    final plain = await _draft(mason, projectId, itemId, '50.00', 'Фундамент, без адресата');
    final open = await mason.send('POST', '/api/requests/${plain.id}/submit', json: {
      'version': plain.version,
    }, idempotencyKey: 'submit-plain-001');
    expect(open.status, 200, reason: open.body.toString());
    expect(open.body!['status'], 'submitted');
    expect(open.body!['forBank'], false);
    expect((await _money(director, projectId)).reserved, '150.00');
  });
}

Future<_Draft> _draft(
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
  return _Draft(id, created.body!['version'] as int);
}

Future<_Money> _money(Client client, String projectId) async {
  final project = await client.send('GET', '/api/projects/$projectId');
  return _Money(project.body!['reserved'] as String, project.body!['paid'] as String);
}

class _Draft {
  _Draft(this.id, this.version);
  final String id;
  final int version;
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

  Future<Call> send(
    String method,
    String path, {
    Map<String, dynamic>? json,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      if (cookies.isNotEmpty)
        'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
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
      if (cookies.isNotEmpty)
        'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
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
