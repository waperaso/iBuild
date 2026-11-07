import 'dart:convert';

import 'package:ibuild_server/ibuild_server.dart';
import 'package:ibuild_server/src/mail.dart';
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
    await _ensureTestDatabase();
    lock = await Connection.openFromUrl(testDatabaseUrl);
    await lock.execute('SELECT pg_advisory_lock(424242)');
    db = await AppDatabase.open(testDatabaseUrl);
    await db.migrate('migrations');
    await db.truncateAll();
    await seedDemo(db, password);
    await ensureBankCabinet(db, password);
    handler = buildHandler(db: db, env: _env());
  });

  tearDownAll(() async {
    await db.close();
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
  });

  Future<Client> signIn(String login) async {
    final client = Client(handler);
    expect((await client.login(login, password)).status, 200);
    return client;
  }

  Future<Call> post(Client client, String path, Map<String, dynamic> json) =>
      client.send('POST', path, json: json, csrf: true);

  test('portfolio, objects and developers show the same bank', () async {
    final client = await signIn('a.head1');
    final portfolio = await client.send('GET', '/api/bank/portfolio');
    expect(portfolio.status, 200);
    expect(portfolio.body!['kpi'], isA<Map>());
    expect(portfolio.body!['stageDays'], isA<List>());

    final objects = await client.send('GET', '/api/bank/objects');
    expect(objects.status, 200);
    final items = (objects.body!['items'] ?? objects.body!['objects']) as List;
    expect(items, isNotEmpty);
    final id = (items.first as Map)['id'];
    final detail = await client.send('GET', '/api/bank/objects/$id');
    expect(detail.status, 200);
    expect(detail.body!['object'], isA<Map>());
    expect(detail.body!['budget'], isNotNull);
    expect((await client.send('GET', '/api/bank/objects/00000000-0000-0000-0000-000000000000')).status, 404);

    final developers = await client.send('GET', '/api/bank/developers');
    expect(developers.status, 200);
    final list = (developers.body!['items'] ?? developers.body!['developers']) as List;
    expect(list, isNotEmpty);
    final one = await client.send('GET', '/api/bank/developers/${(list.first as Map)['id']}');
    expect(one.status, 200);
  });

  test('only an expert completes an inspection; an overdue one is marked', () async {
    final head = await signIn('a.head1');
    final expert = await signIn('a.expert');
    final list = await head.send('GET', '/api/bank/inspections');
    expect(list.status, 200);
    final counts = list.body!['counts'] as Map;
    expect(counts.keys, containsAll(['planned', 'done', 'overdue']));
    final planned = (list.body!['items'] as List).cast<Map>().where((i) => i['status'] != 'done').toList();
    if (planned.isEmpty) return;
    final id = planned.first['id'];
    final denied = await post(head, '/api/bank/inspections/$id/complete',
        {'note': 'Осмотрено', 'risk': 'low', 'recommendation': 'issue'});
    expect(denied.status, 403);
    final bad = await post(expert, '/api/bank/inspections/$id/complete', {'risk': 'nonsense'});
    expect(bad.status, 400);
  });

  test('reports: catalog, a table and the three files', () async {
    final client = await signIn('a.head1');
    final catalog = await client.send('GET', '/api/bank/reports');
    expect(catalog.status, 200);
    final items = (catalog.body!['catalog'] as List).cast<Map>();
    expect({for (final item in items) item['group']}.length, 4);
    final codes = [for (final item in items) item['code'] as String];
    expect(codes.length, 11);
    for (final code in codes) {
      final shown = await client.send('GET', '/api/bank/reports/$code');
      expect(shown.status, 200, reason: code);
      expect(shown.body!['columns'], isA<List>(), reason: code);
    }
    expect((await client.send('GET', '/api/bank/reports/nothing')).status, 404);
    for (final format in ['csv', 'xlsx', 'pdf']) {
      final response = await handler(Request(
        'GET',
        Uri.parse('http://localhost/api/bank/reports/${codes.first}/file?format=$format'),
        headers: {'cookie': client.cookies.entries.map((e) => '${e.key}=${e.value}').join('; ')},
      ));
      expect(response.statusCode, 200, reason: format);
      final bytes = await response.read().expand((chunk) => chunk).toList();
      expect(bytes, isNotEmpty);
      if (format == 'xlsx') expect(bytes.take(2).toList(), [0x50, 0x4b]);
      if (format == 'pdf') expect(utf8.decode(bytes.take(4).toList()), '%PDF');
    }
    final off = await post(client, '/api/bank/reports/${codes.first}/schedule',
        {'enabled': true, 'recipients': 'riski@example.uz'});
    expect(off.status, 200);
  });

  test('platform admin: overview, users, reset, journal; others are refused', () async {
    final head = await signIn('a.head1');
    for (final path in ['overview', 'companies', 'users', 'events', 'system']) {
      expect((await head.send('GET', '/api/admin/$path')).status, 403, reason: path);
    }
    final admin = await signIn('a.admin');
    for (final path in ['overview', 'companies', 'users', 'events', 'system']) {
      expect((await admin.send('GET', '/api/admin/$path')).status, 200, reason: path);
    }
    final users = ((await admin.send('GET', '/api/admin/users?q=a.tech')).body!['items'] as List).cast<Map>();
    final tech = users.firstWhere((u) => u['login'] == 'a.tech');
    final me = ((await admin.send('GET', '/api/admin/users?q=a.admin')).body!['items'] as List).cast<Map>().first;
    expect((await post(admin, '/api/admin/users/${me['id']}/active', {'active': false})).status, 409);

    final victim = await signIn('a.tech');
    expect((await post(admin, '/api/admin/users/${tech['id']}/active', {'active': false})).status, 200);
    expect((await victim.send('GET', '/api/auth/me')).status, 401);
    expect((await Client(handler).login('a.tech', password)).status, isNot(200));
    expect((await post(admin, '/api/admin/users/${tech['id']}/active', {'active': true})).status, 200);

    final reset = await post(admin, '/api/admin/users/${tech['id']}/reset-password', {});
    expect(reset.status, 200);
    final fresh = reset.body!['password'] as String;
    expect(fresh.length, 14);
    expect((await Client(handler).login('a.tech', password)).status, isNot(200));
    final forced = Client(handler);
    final forcedLogin = await forced.login('a.tech', fresh);
    expect(forcedLogin.status, 200);
    expect(forcedLogin.body!['mustChangePassword'], isTrue);

    final events = ((await admin.send('GET', '/api/admin/events')).body!['items'] as List).cast<Map>();
    expect(events.map((e) => e['action']), contains('users.reset-password'));
    expect(events.any((e) => e.toString().contains(fresh)), isFalse);
    // The seeded password is restored for the tests that follow.
    await db.owner.execute(Sql.named('UPDATE users SET password_hash = @hash, must_change_password = false WHERE login = \'a.tech\''),
        parameters: {'hash': hashPassword(password)});
  });

  test('a user changes the password; the others sessions end; the flag clears', () async {
    final first = await signIn('a.observer');
    final second = await signIn('a.observer');
    expect((await post(first, '/api/auth/password', {'current': 'wrong', 'next': 'Another-pass-2026'})).status, 400);
    expect((await post(first, '/api/auth/password', {'current': password, 'next': 'short'})).status, 400);
    expect((await post(first, '/api/auth/password', {'current': password, 'next': password})).status, 400);
    expect((await post(first, '/api/auth/password', {'current': password, 'next': 'Another-pass-2026'})).status, 200);
    expect((await first.send('GET', '/api/auth/me')).status, 200);
    expect((await second.send('GET', '/api/auth/me')).status, 401);
    expect((await Client(handler).login('a.observer', password)).status, isNot(200));
    expect((await Client(handler).login('a.observer', 'Another-pass-2026')).status, 200);
    await db.owner.execute(Sql.named('UPDATE users SET password_hash = @hash WHERE login = \'a.observer\''),
        parameters: {'hash': hashPassword(password)});
  });

  test('a reminder and a report letter reach the outbox; only the admin reads it', () async {
    final head = await signIn('a.head1');
    final objects = ((await head.send('GET', '/api/bank/objects')).body!['items'] ?? (await head.send('GET', '/api/bank/objects')).body!['objects']) as List;
    final id = (objects.first as Map)['id'];
    final remind = await post(head, '/api/bank/objects/$id/remind', {'kind': 'documents'});
    expect(remind.status, 200);
    expect(remind.body!['mail'], isIn(['queued', 'sent', 'failed', 'no_recipient']));

    expect((await post(head, '/api/bank/reports/money_flow/send', {})).status, anyOf(400, 404));
    final catalog = ((await head.send('GET', '/api/bank/reports')).body!['catalog'] as List).cast<Map>();
    final code = catalog.first['code'];
    await db.owner.execute('DELETE FROM bank_report_schedules');
    expect((await post(head, '/api/bank/reports/$code/send', {})).status, 400);
    expect((await post(head, '/api/bank/reports/$code/schedule', {'enabled': true, 'recipients': 'risk@bank.uz'})).status, 200);
    final sent = await post(head, '/api/bank/reports/$code/send', {});
    expect(sent.status, 200);
    expect(sent.body!['count'], 1);

    expect(await runReportSchedules(db, now: DateTime.utc(2026, 10, 28, 12)), 0, reason: 'not a Monday');
    final before = await db.owner.execute('SELECT count(*) FROM mail_outbox');
    expect(await runReportSchedules(db, force: true), greaterThanOrEqualTo(1));
    expect(await runReportSchedules(db, force: true), 0, reason: 'once per week');
    final after = await db.owner.execute('SELECT count(*) FROM mail_outbox');
    expect((after.first[0]! as int) > (before.first[0]! as int), isTrue);

    expect((await head.send('GET', '/api/admin/mail')).status, 403);
    final admin = await signIn('a.admin');
    final mail = await admin.send('GET', '/api/admin/mail');
    expect(mail.status, 200);
    final items = (mail.body!['items'] as List).cast<Map>();
    expect(items.any((m) => m['to'] == 'risk@bank.uz' && m['attachment'] != ''), isTrue);
    expect(mail.body!['connected'], isFalse);
    final bad = await post(admin, '/api/admin/mail/test', {'to': 'not-an-address'});
    expect(bad.status, 400);
    expect(bad.body!['message'], 'Проверьте адрес почты');
    final previousMail = mailConfig;
    mailConfig = const MailConfig();
    final testLetter = await post(admin, '/api/admin/mail/test', {'to': 'me@example.com'});
    mailConfig = previousMail;
    expect(testLetter.status, 200);
    expect(testLetter.body!['mail'], 'queued');
    final stored = await db.owner.execute(
      "SELECT status FROM mail_outbox WHERE to_email = 'me@example.com' ORDER BY created_at DESC LIMIT 1",
    );
    expect(stored.first[0], 'queued');
  });

  test('the journal of the bank is for the audit roles only', () async {
    final expert = await signIn('a.expert');
    expect((await expert.send('GET', '/api/bank/audit')).status, 403);
    final head = await signIn('a.head1');
    final journal = await head.send('GET', '/api/bank/audit?limit=5');
    expect(journal.status, 200);
    expect(journal.body!['items'], isA<List>());
    expect((await head.send('GET', '/api/bank/audit?from=nonsense')).status, 400);
  });

  test('rules: admin only, every change is a new version, groups keep a quorum', () async {
    final head = await signIn('a.head1');
    expect((await head.send('GET', '/api/bank/rules')).status, 403);
    expect((await post(head, '/api/bank/rules', {'issuedAbovePercent': 2})).status, 403);

    final admin = await signIn('a.bankadmin');
    final before = await admin.send('GET', '/api/bank/rules');
    expect(before.status, 200);
    final version = before.body!['version'] as int;
    final rules = Map<String, dynamic>.from(before.body!['rules'] as Map);

    expect((await post(admin, '/api/bank/rules', {'issuedAbovePercent': 500})).status, 400);
    expect((await post(admin, '/api/bank/rules', {})).status, 409);

    final saved = await post(admin, '/api/bank/rules', {
      'issuedAbovePercent': (rules['issuedAbovePercent'] as int) + 1,
      'note': 'Проверка версий',
    });
    expect(saved.status, 200);
    expect(saved.body!['version'], version + 1);
    final after = await admin.send('GET', '/api/bank/rules');
    expect(after.body!['version'], version + 1);
    final history = after.body!['history'] as List;
    expect((history.first as Map)['changed'], contains('issuedAbovePercent'));
    expect((await admin.send('GET', '/api/bank/rules/versions/$version')).status, 200);

    final groups = (after.body!['groups'] as List).cast<Map>();
    final heads = groups.firstWhere((g) => g['code'] == 'heads');
    expect((await post(admin, '/api/bank/rules/groups/heads', {'requiredApprovals': 99})).status, 400);
    expect((await post(admin, '/api/bank/rules/groups/heads', {'requiredApprovals': 1})).status, 200);
    expect(heads['members'], isNotEmpty);
    final member = (heads['members'] as List).first as Map;
    expect((await post(admin, '/api/bank/rules/members/${member['userId']}', {'onLeaveUntil': '2026-12-01'})).status, 200);
    expect((await post(admin, '/api/bank/rules/members/${member['userId']}', {'onLeaveUntil': null})).status, 200);
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

Future<void> _ensureTestDatabase() async {
  final admin = Pool<void>.withUrl(
    'postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable',
  );
  try {
    final existing = await admin.execute(
      "SELECT 1 FROM pg_database WHERE datname = 'ibuild_test'",
    );
    if (existing.isEmpty) {
      await admin.execute('CREATE DATABASE ibuild_test');
    }
  } finally {
    await admin.close();
  }
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
    }, csrf: true);
  }

  Future<Call> send(
    String method,
    String path, {
    Map<String, dynamic>? json,
    bool csrf = false,
    Map<String, String> headers = const {},
  }) async {
    final sent = <String, String>{
      ...headers,
      if (cookies.isNotEmpty)
        'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
      if (json != null) 'content-type': 'application/json',
      if (csrf && this.csrf != null) 'x-csrf-token': this.csrf!,
    };
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: sent,
        body: json == null ? null : jsonEncode(json),
      ),
    );
    for (final line in response.headersAll['set-cookie'] ?? const <String>[]) {
      final first = line.split(';').first;
      final separator = first.indexOf('=');
      if (separator <= 0) continue;
      final name = first.substring(0, separator).trim();
      final value = first.substring(separator + 1).trim();
      cookies[name] = value;
      if (name == 'ibuild_csrf') this.csrf = value;
    }
    final raw = await response.readAsString();
    Map<String, dynamic>? body;
    if (raw.isNotEmpty && raw.startsWith('{')) {
      body = (jsonDecode(raw) as Map).map((key, value) => MapEntry(key.toString(), value));
      if (body['csrfToken'] is String) this.csrf = body['csrfToken'] as String;
    }
    return Call(response.statusCode, body);
  }
}
