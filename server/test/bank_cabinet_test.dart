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

  test('the developer and another bank cannot read this queue', () async {
    final anon = await Client(handler).send('GET', '/api/bank/queue');
    expect(anon.status, 401);

    final director = Client(handler);
    expect((await director.login('a.director', password)).status, 200);
    expect(director.last?['bank'], isNull);
    final denied = await director.send('GET', '/api/bank/queue');
    expect(denied.status, 404);

    final specialist = Client(handler);
    final signed = await specialist.login('a.observer', password);
    expect(signed.status, 200);
    expect(signed.body!['name'], 'Д. Рахимов');
    final bank = signed.body!['bank'] as Map<String, dynamic>;
    expect(bank['role'], 'specialist');
    expect(bank['name'], 'Банк Навои');
    expect(bank['queueCount'], 2);
    expect(bank['trancheCount'], 12);
    expect(bank['waitingAmount'], '18740000000.00');

    final queue = await specialist.send('GET', '/api/bank/queue?tab=all');
    expect(queue.status, 200);
    final counts = queue.body!['counts'] as Map<String, dynamic>;
    expect(counts['mine'], 2);
    expect(counts['all'], 12);
    expect(counts['developer'], 3);
    expect(counts['overdue'], 1);
    final items = (queue.body!['items'] as List).cast<Map<String, dynamic>>();
    final navoi = items.singleWhere((item) => item['projectName'] == 'ЖК Навои');
    expect(navoi['trancheNo'], 2);
    expect(navoi['requestedAmount'], '2260000000.00');
    expect(navoi['elapsedLabel'], '1 д 4 ч из 2 д');
    expect(navoi['mine'], true);
    expect(navoi['overdue'], false);
    expect(items.where((item) => item['overdue'] == true).length, 1);
    expect(items.where((item) => item['waitingDeveloper'] == true).length, 3);

    final foreign = Client(handler);
    expect((await foreign.login('b.observer', password)).status, 200);
    final foreignQueue = await foreign.send('GET', '/api/bank/queue');
    expect(foreignQueue.status, 200);
    expect((foreignQueue.body!['counts'] as Map)['all'], 0);
    final hidden = await foreign.send('GET', '/api/bank/tranches/${navoi['id']}');
    expect(hidden.status, 404);

    final stillOwn = await specialist.send('GET', '/api/projects');
    expect((stillOwn.body!['projects'] as List).length, 1);
  });

  group('queue tabs', () {
    late Client specialist;

    setUpAll(() async {
      specialist = Client(handler);
      expect((await specialist.login('a.observer', password)).status, 200);
    });

    Future<List<Map<String, dynamic>>> tab(String name) async {
      final response = await specialist.send('GET', '/api/bank/queue?tab=$name');
      expect(response.status, 200);
      expect(response.body!['tab'], name);
      return (response.body!['items'] as List).cast<Map<String, dynamic>>();
    }

    test('the default tab is mine', () async {
      final response = await specialist.send('GET', '/api/bank/queue');
      expect(response.body!['tab'], 'mine');
      expect((response.body!['items'] as List).length, 2);
    });

    test('mine holds only own tranches: Navoi and Yunusabad', () async {
      final items = await tab('mine');
      expect(items.map((item) => item['projectName']).toList(),
          ['ЖК Навои', 'ЖК Юнусабад Гарден']);
      expect(items.every((item) => item['mine'] == true), isTrue);
    });

    test('all shows all 12 tranches in queue order', () async {
      final items = await tab('all');
      expect(items.length, 12);
      expect(items.first['projectName'], 'ЖК Навои');
    });

    test('the developer tab shows only tranches waiting on the developer', () async {
      final items = await tab('developer');
      expect(items.map((item) => item['projectName']).toSet(),
          {'ЖК Мирзо-Улугбек', 'ЖК Бектемир', 'ЖК Яккасарай'});
      expect(items.every((item) => item['signal'] == 'developer'), isTrue);
    });

    test('time at the developer is not bank time: no overdue tranche among them', () async {
      final items = await tab('developer');
      final mirzo = items.singleWhere((item) => item['projectName'] == 'ЖК Мирзо-Улугбек');
      expect(mirzo['elapsedDays'], 6);
      expect(mirzo['slaDays'], 2);
      expect(mirzo['overdue'], false);
      expect(mirzo['elapsedLabel'], '6 д у застройщика');
    });

    test('overdue holds only Sergeli Nur: 4 days against 3', () async {
      final items = await tab('overdue');
      expect(items.length, 1);
      final sergeli = items.single;
      expect(sergeli['projectName'], 'ЖК Сергели Нур');
      expect(sergeli['elapsedDays'], 4);
      expect(sergeli['elapsedHours'], 0);
      expect(sergeli['slaDays'], 3);
      expect(sergeli['overdue'], true);
      expect(sergeli['mine'], false);
    });

    test('counts do not depend on the tab', () async {
      for (final name in ['mine', 'all', 'developer', 'overdue']) {
        final response = await specialist.send('GET', '/api/bank/queue?tab=$name');
        final counts = response.body!['counts'] as Map<String, dynamic>;
        expect(counts, {'mine': 2, 'all': 12, 'developer': 3, 'overdue': 1});
        expect(response.body!['waitingAmount'], '18740000000.00');
      }
    });

    test('an unknown tab is a validation error', () async {
      final response = await specialist.send('GET', '/api/bank/queue?tab=trash');
      expect(response.status, 400);
      expect(response.body!['error'], 'validation');
    });

    test('another bank sees an empty queue', () async {
      final foreign = Client(handler);
      expect((await foreign.login('b.observer', password)).status, 200);
      final response = await foreign.send('GET', '/api/bank/queue?tab=all');
      expect((response.body!['items'] as List), isEmpty);
    });
  });

  group('tranche card', () {
    late Client specialist;
    late Map<String, dynamic> card;

    setUpAll(() async {
      specialist = Client(handler);
      expect((await specialist.login('a.observer', password)).status, 200);
      final queue = await specialist.send('GET', '/api/bank/queue?tab=all');
      final navoi = (queue.body!['items'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((item) => item['projectName'] == 'ЖК Навои');
      final response = await specialist.send('GET', '/api/bank/tranches/${navoi['id']}');
      expect(response.status, 200);
      card = response.body!;
    });

    test('the header carries the object, developer and facility', () {
      expect(card['projectName'], 'ЖК Навои');
      expect(card['developerName'], 'Навои Девелопмент');
      expect(card['trancheNo'], 2);
      expect(card['stageLabel'], 'Решение специалиста');
      expect(card['creditLimit'], '17500000000.00');
      expect(card['issuedTotal'], '1240100000.00');
      expect(card['rulesVersion'], 7);
    });

    test('the stage strip: three done, one current, two pending', () {
      final stages = (card['stages'] as List).cast<Map<String, dynamic>>();
      expect(stages.map((stage) => stage['code']).toList(),
          ['submitted', 'docs', 'inspection', 'specialist', 'approval', 'payout']);
      expect(stages.map((stage) => stage['state']).toList(),
          ['done', 'done', 'done', 'current', 'pending', 'pending']);
    });

    test('the dates and the bank clock', () {
      expect(card['submittedDate'], '24.10.2026');
      expect(card['submittedTime'], '18:10');
      expect(card['techConfirmed'], '24.10');
      expect(card['elapsedDays'], 1);
      expect(card['elapsedHours'], 4);
      expect(card['slaDays'], 2);
      expect(card['overdue'], false);
      expect(card['waitingDeveloper'], false);
    });

    test('five numbers and the amount to return', () {
      final totals = card['totals'] as Map<String, dynamic>;
      expect(totals['requested'], '2260000000.00');
      expect(totals['confirmed'], '2083900000.00');
      expect(totals['blocked'], '360000000.00');
      expect(totals['issue'], '1723900000.00');
      expect(totals['returned'], '536100000.00');
      // 17 500,0 - 1 240,1 - 1 723,9 = 14 536,0
      expect(totals['remaining'], '14536000000.00');
    });

    test('four open checks in a fixed order, eight passed', () {
      final checks = card['checks'] as Map<String, dynamic>;
      final open = (checks['open'] as List).cast<Map<String, dynamic>>();
      final passed = (checks['passed'] as List).cast<Map<String, dynamic>>();
      expect(open.map((check) => check['code']).toList(),
          ['certificate', 'above_confirmed', 'subcontractor', 'forecast']);
      expect(open.map((check) => check['level']).toList(),
          ['block', 'warning', 'warning', 'warning']);
      expect(passed.length, 8);
      expect(passed.first['title'], 'Акт выполненных работ приложен');
      expect(passed.first['basis'], 'ГС п. 3.5');
      expect(passed.every((check) => check['passed'] == true), isTrue);
    });

    test('actions depend on the check', () {
      final open = ((card['checks'] as Map)['open'] as List).cast<Map<String, dynamic>>();
      Object? actions(String code) =>
          open.singleWhere((check) => check['code'] == code)['actions'];
      expect(actions('certificate'), ['request_document', 'waive']);
      expect(actions('above_confirmed'), ['waive']);
      expect(actions('subcontractor'), ['waive']);
      expect(actions('forecast'), ['request_schedule']);
      final passed = ((card['checks'] as Map)['passed'] as List).cast<Map<String, dynamic>>();
      expect(passed.every((check) => (check['actions'] as List).isEmpty), isTrue);
    });

    test('the budget lines carry readiness and the level of each', () {
      final lines = (card['lines'] as List).cast<Map<String, dynamic>>();
      expect(lines.map((line) => line['title']).toList(), [
        'Котлован и земляные работы',
        'Фундаментная плита',
        'Каркас, 1–4 этажи',
        'Арматура A500C и бетон на площадке',
      ]);
      expect(lines.map((line) => line['level']).toList(), ['ok', 'warning', 'warning', 'block']);
      expect(lines.map((line) => line['readinessPercent']).toList(), ['100', '62', '12', null]);
      final rebar = lines.last;
      expect(rebar['requested'], '360000000.00');
      expect(rebar['confirmed'], '360000000.00');
      expect(rebar['toIssue'], '0.00');
      expect(rebar['choice'], 'confirmed');
      final plate = lines[1];
      expect(plate['requested'], '980000000.00');
      expect(plate['confirmed'], '867900000.00');
      expect(plate['toIssue'], '867900000.00');
    });

    test('the sums of the lines match the totals', () {
      final lines = (card['lines'] as List).cast<Map<String, dynamic>>();
      BigInt cents(String value) => BigInt.parse(value.replaceAll('.', ''));
      BigInt sum(String key) =>
          lines.fold(BigInt.zero, (total, line) => total + cents(line[key] as String));
      final totals = card['totals'] as Map<String, dynamic>;
      expect(sum('requested'), cents(totals['requested'] as String));
      expect(sum('toIssue'), cents(totals['issue'] as String));
    });

    test('a malformed or unknown id is not found, a developer sees nothing', () async {
      expect((await specialist.send('GET', '/api/bank/tranches/not-a-uuid')).status, 404);
      expect(
        (await specialist.send('GET', '/api/bank/tranches/00000000-0000-4000-8000-000000000000')).status,
        404,
      );
      final developer = Client(handler);
      expect((await developer.login('a.director', password)).status, 200);
      expect((await developer.send('GET', '/api/bank/tranches/${card['id']}')).status, 404);
    });
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
  Map<String, dynamic>? last;

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
  }) async {
    final headers = <String, String>{
      if (cookies.isNotEmpty)
        'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
      if (json != null) 'content-type': 'application/json',
      if (csrf && this.csrf != null) 'x-csrf-token': this.csrf!,
    };
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: headers,
        body: json == null ? null : jsonEncode(json),
      ),
    );
    final setCookies = response.headersAll['set-cookie'] ?? const <String>[];
    for (final line in setCookies) {
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
      if (name == 'ibuild_csrf') this.csrf = value;
    }
    final raw = await response.readAsString();
    Map<String, dynamic>? body;
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        body = decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    if (body?['csrfToken'] is String) this.csrf = body!['csrfToken'] as String;
    last = body;
    return Call(response.statusCode, body);
  }
}
