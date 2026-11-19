import 'dart:convert';

import 'package:ibuild_server/ibuild_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const password = 'Pilot-2026-demo';
const testDatabaseUrl =
    'postgres://ibuild:ibuild@localhost:5433/ibuild_test?sslmode=disable';
const ghostItem = '00000000-0000-4000-8000-000000000001';

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
    handler = buildHandler(db: db, env: _env());
  });

  tearDownAll(() async {
    await db.close();
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
  });

  test('every account calls every function', () async {
    final anon = Client(handler);
    expect((await anon.send('GET', '/api/health')).status, 200);
    expect((await anon.send('GET', '/api/auth/csrf')).status, 200);
    for (final path in [
      '/api/auth/me',
      '/api/projects',
      '/api/projects/$ghostItem',
      '/api/projects/$ghostItem/budget',
      '/api/projects/$ghostItem/members',
      '/api/contractor-firms',
      '/api/company/users',
    ]) {
      expect((await anon.send('GET', path)).status, 401, reason: path);
    }
    expect((await anon.send('POST', '/api/projects', json: {'name': 'X', 'address': 'Y'})).status, 401);
    expect((await anon.send('POST', '/api/auth/logout')).status, 401);

    final disabled = await Client(handler).login('a.disabled', password);
    expect(disabled.status, 403);
    expect(disabled.body!['message'], 'Эта учётная запись отключена.');

    final sessions = <String, Client>{};
    final projects = <String, String>{};
    for (final person in people) {
      final client = Client(handler);
      final signed = await client.login(person.login, password);
      expect(signed.status, 200, reason: person.login);
      expect(signed.body!['login'], person.login);
      expect(signed.body!['name'], person.name);
      expect(signed.body!['active'], isTrue);
      sessions[person.login] = client;

      final me = await client.send('GET', '/api/auth/me');
      expect(me.status, 200, reason: person.login);
      expect(me.body!['login'], person.login);

      final list = await client.send('GET', '/api/projects');
      expect(list.status, 200, reason: person.login);
      final rows = list.body!['projects'] as List<dynamic>;
      expect(rows, hasLength(1), reason: person.login);
      final row = (rows.single as Map).cast<String, dynamic>();
      expect(row['name'], person.project, reason: person.login);
      expect(row['myRole'], person.role, reason: person.login);
      expect(row['plan'], person.plan, reason: person.login);
      expect(row['reserved'], '0.00', reason: person.login);
      expect(row['paid'], '0.00', reason: person.login);
      expect(row['available'], person.plan, reason: person.login);
      projects[person.login] = row['id'] as String;

      final card = await client.send('GET', '/api/projects/${row['id']}');
      expect(card.status, 200, reason: person.login);
      expect(card.body!['myRole'], person.role);

      final budget = await client.send('GET', '/api/projects/${row['id']}/budget');
      expect(budget.status, 200, reason: person.login);
      final items = budget.body!['items'] as List<dynamic>;
      expect(items, hasLength(person.lines), reason: person.login);
      expect(budget.body!['plan'], person.plan, reason: person.login);
      final titles = [for (final item in items) (item as Map)['title']];
      if (person.login == 'a.contractor') {
        expect(titles, isNot(contains('Инженерия')));
        expect(titles, contains('Фундамент'));
      }
      if (person.login == 'a.contractor2') {
        expect(titles, contains('Инженерия'));
        expect(titles, isNot(contains('Фундамент')));
      }
      if (person.role != 'contractor') {
        expect(titles, contains('Фундамент'));
      }

      final members = await client.send('GET', '/api/projects/${row['id']}/members');
      expect(members.status, 200, reason: person.login);
      expect(members.body!['members'] as List, hasLength(person.members), reason: person.login);

      final firms = await client.send('GET', '/api/contractor-firms');
      final users = await client.send('GET', '/api/company/users');
      if (person.role == 'director' || person.role == 'developer') {
        expect(firms.status, 200, reason: person.login);
        expect((firms.body!['firms'] as List), isNotEmpty);
        expect(users.status, 200, reason: person.login);
        expect((users.body!['users'] as List), isNotEmpty);
      } else {
        expect(firms.status, 403, reason: person.login);
        expect(users.status, 403, reason: person.login);
      }
    }

    final navoi = projects['a.director']!;
    final chilonzor = projects['b.director']!;
    for (final person in people) {
      final client = sessions[person.login]!;
      final foreign = person.login.startsWith('a.') ? chilonzor : navoi;
      expect((await client.send('GET', '/api/projects/$foreign')).status, 404, reason: person.login);
      expect((await client.send('GET', '/api/projects/$foreign/budget')).status, 404, reason: person.login);
      expect((await client.send('GET', '/api/projects/$foreign/members')).status, 404, reason: person.login);
      expect((await client.send('GET', '/api/requests')).status, 200, reason: person.login);
      expect((await client.send('GET', '/api/requests/$ghostItem')).status, 404, reason: person.login);
      final foreignDraft = await client.send('POST', '/api/requests', json: {
        'projectId': foreign,
        'budgetItemId': ghostItem,
        'amount': '10.00',
        'description': 'проверка',
      }, withCsrf: true);
      expect(foreignDraft.status, 404, reason: person.login);

      final own = projects[person.login]!;
      final create = await client.send('POST', '/api/projects', json: {
        'name': 'Проверка ${person.login}',
        'address': 'Ташкент',
      }, withCsrf: true);
      final line = await client.send('POST', '/api/projects/$own/budget', json: {
        'title': 'Лишняя',
        'amount': '10.00',
        'contractorFirmId': ghostItem,
      }, withCsrf: true);
      final foreignLine = await client.send('POST', '/api/projects/$foreign/budget', json: {
        'title': 'Чужая',
        'amount': '10.00',
        'contractorFirmId': ghostItem,
      }, withCsrf: true);
      final patch = await client.send('PATCH', '/api/projects/$own/budget/$ghostItem', json: {
        'title': 'Лишняя',
        'amount': '10.00',
        'contractorFirmId': ghostItem,
      }, withCsrf: true);
      final removeLine = await client.send('DELETE', '/api/projects/$own/budget/$ghostItem', withCsrf: true);
      final add = await client.send('POST', '/api/projects/$own/members', json: {
        'userId': ghostItem,
        'role': 'tech',
      }, withCsrf: true);
      final foreignMember = await client.send('POST', '/api/projects/$foreign/members', json: {
        'userId': ghostItem,
        'role': 'tech',
      }, withCsrf: true);
      final removeMember = await client.send('DELETE', '/api/projects/$own/members/$ghostItem', withCsrf: true);
      final firm = await client.send('POST', '/api/contractor-firms', json: {
        'name': 'Чужая фирма',
        'inn': '309000099',
        'contact': 'нет',
      }, withCsrf: true);

      if (person.role == 'director' || person.role == 'developer') {
        expect(create.status, 201, reason: person.login);
        expect(foreignLine.status, 404, reason: person.login);
        expect(foreignMember.status, 404, reason: person.login);
      } else if (person.role == 'observer') {
        expect(create.status, 403, reason: person.login);
        expect(line.status, 404, reason: person.login);
        expect(foreignLine.status, 404, reason: person.login);
        expect(patch.status, 404, reason: person.login);
        expect(removeLine.status, 403, reason: person.login);
        expect(add.status, 403, reason: person.login);
        expect(foreignMember.status, 404, reason: person.login);
        expect(removeMember.status, 403, reason: person.login);
        expect(firm.status, 403, reason: person.login);
      } else {
        expect(create.status, 403, reason: person.login);
        expect(line.status, 403, reason: person.login);
        expect(foreignLine.status, 404, reason: person.login);
        expect(patch.status, 403, reason: person.login);
        expect(removeLine.status, 403, reason: person.login);
        expect(add.status, 403, reason: person.login);
        expect(foreignMember.status, 404, reason: person.login);
        expect(removeMember.status, 403, reason: person.login);
        expect(firm.status, 403, reason: person.login);
      }
    }

    final director = sessions['a.director']!;
    final duplicate = await director.send('POST', '/api/contractor-firms', json: {
      'name': 'Повтор',
      'inn': '301000001',
      'contact': '+998 90 100 00 01',
    }, withCsrf: true);
    expect(duplicate.status, 409);

    final created = await director.send('POST', '/api/projects', json: {
      'name': 'Проверка правок',
      'address': 'Ташкент',
    }, withCsrf: true);
    expect(created.status, 201);
    final freshId = created.body!['id'] as String;
    expect(created.body!['plan'], '0.00');

    final firmList = await director.send('GET', '/api/contractor-firms');
    final firmId = ((firmList.body!['firms'] as List).first as Map)['id'] as String;
    final added = await director.send('POST', '/api/projects/$freshId/budget', json: {
      'title': 'Проверка',
      'amount': '100.00',
      'contractorFirmId': firmId,
    }, withCsrf: true);
    expect(added.status, 201);
    expect(added.body!['amount'], '100.00');
    final itemId = added.body!['id'] as String;

    final edited = await director.send('PATCH', '/api/projects/$freshId/budget/$itemId', json: {
      'title': 'Проверка, правка',
      'amount': '80.00',
      'contractorFirmId': firmId,
    }, withCsrf: true);
    expect(edited.status, 200);
    expect(edited.body!['amount'], '80.00');

    final contractor = sessions['a.contractor']!;
    expect(
      (await contractor.send('PATCH', '/api/projects/$freshId/budget/$itemId', json: {
        'title': 'Чужая правка',
        'amount': '1.00',
        'contractorFirmId': firmId,
      }, withCsrf: true)).status,
      404,
    );

    final users = await director.send('GET', '/api/company/users');
    final tech = (users.body!['users'] as List)
        .cast<Map>()
        .singleWhere((user) => user['login'] == 'a.tech');
    final assigned = await director.send('POST', '/api/projects/$freshId/members', json: {
      'userId': tech['id'],
      'role': 'tech',
    }, withCsrf: true);
    expect(assigned.status, 201);
    final again = await director.send('POST', '/api/projects/$freshId/members', json: {
      'userId': tech['id'],
      'role': 'observer',
    }, withCsrf: true);
    expect(again.status, 409);

    final memberList = await director.send('GET', '/api/projects/$freshId/members');
    final rows = (memberList.body!['members'] as List).cast<Map>();
    final techMember = rows.singleWhere((member) => member['login'] == 'a.tech');
    final directorMember = rows.singleWhere((member) => member['role'] == 'director');
    expect((await director.send('DELETE', '/api/projects/$freshId/members/${directorMember['id']}', withCsrf: true)).status, 409);
    expect((await director.send('DELETE', '/api/projects/$freshId/members/${techMember['id']}', withCsrf: true)).status, 204);
    expect((await director.send('DELETE', '/api/projects/$freshId/budget/$itemId', withCsrf: true)).status, 204);

    final negative = await director.send('POST', '/api/projects/$freshId/budget', json: {
      'title': 'Минус',
      'amount': '-1.00',
      'contractorFirmId': firmId,
    }, withCsrf: true);
    expect(negative.status, 400);

    for (final client in sessions.values) {
      expect((await client.send('POST', '/api/auth/logout', json: {}, withCsrf: true)).status, 204);
      expect((await client.send('GET', '/api/auth/me')).status, 401);
    }
  });
}

const people = <({String login, String name, String role, String project, String plan, int lines, int members})>[
  (login: 'a.director', name: 'Застройщик Навои', role: 'director', project: 'ЖК Навои', plan: navoiPlan, lines: 5, members: 6),
  (login: 'a.developer', name: 'Разработчик (тест)', role: 'developer', project: 'ЖК Навои', plan: navoiPlan, lines: 5, members: 6),
  (login: 'a.contractor', name: 'Подрядчик Навои', role: 'contractor', project: 'ЖК Навои', plan: navoiMasonryPlan, lines: 3, members: 6),
  (login: 'a.contractor2', name: 'Подрядчик инженерии', role: 'contractor', project: 'ЖК Навои', plan: navoiEngineeringPlan, lines: 2, members: 6),
  (login: 'a.tech', name: 'Технадзор Навои', role: 'tech', project: 'ЖК Навои', plan: navoiPlan, lines: 5, members: 6),
  (login: 'a.observer', name: 'Д. Рахимов', role: 'observer', project: 'ЖК Навои', plan: navoiPlan, lines: 5, members: 6),
  (login: 'b.director', name: 'Застройщик Чиланзара', role: 'director', project: 'ЖК Чиланзар', plan: chilonzorPlan, lines: 2, members: 4),
  (login: 'b.contractor', name: 'Подрядчик Чиланзара', role: 'contractor', project: 'ЖК Чиланзар', plan: chilonzorPlan, lines: 2, members: 4),
  (login: 'b.tech', name: 'Технадзор Чиланзара', role: 'tech', project: 'ЖК Чиланзар', plan: chilonzorPlan, lines: 2, members: 4),
  (login: 'b.observer', name: 'С. Юсупова', role: 'observer', project: 'ЖК Чиланзар', plan: chilonzorPlan, lines: 2, members: 4),
];

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
    final headers = <String, String>{
      if (cookies.isNotEmpty)
        'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
      if (json != null) 'content-type': 'application/json',
      if (withCsrf && csrf != null) 'x-csrf-token': csrf!,
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

class Call {
  Call(this.status, this.body);

  final int status;
  final Map<String, dynamic>? body;
}
