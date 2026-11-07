import 'dart:convert';

import 'package:ibuild_server/ibuild_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const password = 'Pilot-2026-demo';
const testDatabaseUrl =
    'postgres://ibuild:ibuild@localhost:5433/ibuild_test?sslmode=disable';

late AppDatabase db;
late Handler handler;

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

  test('money strings reject zero, negatives, and extra fractions', () {
    expect(normalizeMoney('12500000.00'), '12500000.00');
    expect(normalizeMoney('12500000,5'), '12500000.50');
    expect(normalizeMoney('0'), isNull);
    expect(normalizeMoney('-10'), isNull);
    expect(normalizeMoney('1.234'), isNull);
    expect(normalizeMoney('abc'), isNull);
    expect(normalizeMoney('10.00'), '10.00');
  });

  test('pilot estimate, two contractors, and visible totals', () async {
    final director = await _session('a.director');
    final projectId = director.projectId;
    expect(director.project['plan'], navoiPlan);
    expect(director.project['available'], navoiPlan);

    final budget = await director.client.send('GET', '/api/projects/$projectId/budget');
    expect(budget.status, 200);
    final items = (budget.body!['items'] as List).cast<Map<String, dynamic>>();
    expect(items, hasLength(5));
    expect(budget.body!['locked'], isFalse);

    final members = await director.client.send('GET', '/api/projects/$projectId/members');
    final roles = [
      for (final member in (members.body!['members'] as List).cast<Map<String, dynamic>>())
        member['role'],
    ];
    expect(roles.where((role) => role == 'contractor'), hasLength(2));
    expect(roles, containsAll(['director', 'tech', 'observer']));

    final mason = await _session('a.contractor');
    final masonBudget = await mason.client.send('GET', '/api/projects/${mason.projectId}/budget');
    final masonItems = (masonBudget.body!['items'] as List).cast<Map<String, dynamic>>();
    expect(masonItems, hasLength(3));
    expect(masonBudget.body!['plan'], navoiMasonryPlan);

    final engineer = await _session('a.contractor2');
    final engineerBudget = await engineer.client.send('GET', '/api/projects/${engineer.projectId}/budget');
    expect((engineerBudget.body!['items'] as List), hasLength(2));
    expect(engineerBudget.body!['plan'], navoiEngineeringPlan);

    final stranger = await _session('b.director');
    expect((await stranger.client.send('GET', '/api/projects/$projectId/budget')).status, 404);
    expect((await stranger.client.send('GET', '/api/projects/$projectId/members')).status, 404);
  });

  test('only the project director edits lines, and a submitted request locks them', () async {
    final director = await _session('a.director');
    final created = await director.client.send('POST', '/api/projects', json: {
      'name': 'Проверка бюджета',
      'address': 'Ташкент',
    }, withCsrf: true);
    expect(created.status, 201);
    final projectId = created.body!['id'] as String;
    final firms = await director.client.send('GET', '/api/contractor-firms');
    final firmId = ((firms.body!['firms'] as List).first as Map)['id'] as String;

    final observer = await _session('a.observer');
    final forbidden = await observer.client.send('POST', '/api/projects/$projectId/budget', json: {
      'title': 'Чужая',
      'amount': '10.00',
      'contractorFirmId': firmId,
    }, withCsrf: true);
    expect(forbidden.status, 404);

    for (final amount in ['0', '-5', '1.234', 'нет']) {
      final rejected = await director.client.send('POST', '/api/projects/$projectId/budget', json: {
        'title': 'Плохая сумма',
        'amount': amount,
        'contractorFirmId': firmId,
      }, withCsrf: true);
      expect(rejected.status, 400, reason: amount);
    }

    final line = await director.client.send('POST', '/api/projects/$projectId/budget', json: {
      'title': 'Проверка',
      'amount': '100.00',
      'contractorFirmId': firmId,
    }, withCsrf: true);
    expect(line.status, 201);
    final itemId = line.body!['id'] as String;
    final card = await director.client.send('GET', '/api/projects/$projectId');
    expect(card.body!['plan'], '100.00');
    expect(card.body!['available'], '100.00');

    final author = (await db.userIdByLogin('a.director'))!;
    await db.pool.execute(
      Sql.named('''
        INSERT INTO funding_requests (
          project_id, budget_item_id, contractor_user_id, author_user_id,
          amount, description, status
        ) VALUES (
          @projectId::uuid, @itemId::uuid, @author::uuid, @author::uuid,
          40.00, '', 'draft'
        )
      '''),
      parameters: {'projectId': projectId, 'itemId': itemId, 'author': author},
    );
    final stillOpen = await director.client.send('POST', '/api/projects/$projectId/budget', json: {
      'title': 'Черновик не фиксирует',
      'amount': '10.00',
      'contractorFirmId': firmId,
    }, withCsrf: true);
    expect(stillOpen.status, 201);

    await db.pool.execute(
      Sql.named('''
        UPDATE funding_requests SET status = 'submitted', amount = 40.00
        WHERE project_id = @projectId::uuid AND status = 'draft'
      '''),
      parameters: {'projectId': projectId},
    );
    await db.pool.execute(
      Sql.named('''
        INSERT INTO funding_requests (
          project_id, budget_item_id, contractor_user_id, author_user_id,
          amount, description, status
        ) VALUES (
          @projectId::uuid, @itemId::uuid, @author::uuid, @author::uuid,
          25.00, '', 'paid'
        )
      '''),
      parameters: {'projectId': projectId, 'itemId': itemId, 'author': author},
    );

    final totals = await director.client.send('GET', '/api/projects/$projectId');
    expect(totals.body!['plan'], '110.00');
    expect(totals.body!['reserved'], '40.00');
    expect(totals.body!['paid'], '25.00');
    expect(totals.body!['available'], '45.00');

    final locked = await director.client.send(
      'DELETE',
      '/api/projects/$projectId/budget/$itemId',
      withCsrf: true,
    );
    expect(locked.status, 409);
    expect(locked.body!['error'], 'budget_locked');
  });

  test('assignment stays inside the company and keeps a director', () async {
    final director = await _session('a.director');
    final navoiId = director.projectId;
    final users = await director.client.send('GET', '/api/company/users');
    expect(users.status, 200);

    final foreign = await _session('b.contractor');
    final foreignId = (await foreign.client.send('GET', '/api/auth/me')).body!['id'] as String;
    final hidden = await director.client.send('POST', '/api/projects/$navoiId/members', json: {
      'userId': foreignId,
      'role': 'observer',
    }, withCsrf: true);
    expect(hidden.status, 404);

    final observer = await _session('a.observer');
    final blocked = await observer.client.send('POST', '/api/contractor-firms', json: {
      'name': 'Чужой',
      'inn': '309000001',
      'contact': 'нет',
    }, withCsrf: true);
    expect(blocked.status, 403);

    final duplicate = await director.client.send('POST', '/api/contractor-firms', json: {
      'name': 'Повтор',
      'inn': '301000001',
      'contact': '+998 90 100 00 09',
    }, withCsrf: true);
    expect(duplicate.status, 409);

    final members = await director.client.send('GET', '/api/projects/$navoiId/members');
    final directorMember = ((members.body!['members'] as List).cast<Map<String, dynamic>>())
        .firstWhere((member) => member['role'] == 'director');
    final keep = await director.client.send(
      'DELETE',
      '/api/projects/$navoiId/members/${directorMember['id']}',
      withCsrf: true,
    );
    expect(keep.status, 409);
  });
}

Future<Session> _session(String login) async {
  final client = Client(handler);
  final signed = await client.login(login, password);
  expect(signed.status, 200, reason: login);
  final projects = await client.send('GET', '/api/projects');
  final list = (projects.body!['projects'] as List).cast<Map<String, dynamic>>();
  final project = list.firstWhere(
    (item) => item['name'] == (login.startsWith('a.') ? 'ЖК Навои' : 'ЖК Чиланзар'),
  );
  return Session(client, project);
}

class Session {
  Session(this.client, this.project);

  final Client client;
  final Map<String, dynamic> project;

  String get projectId => project['id'] as String;
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
    return Call(this, response.statusCode, body);
  }
}

class Call {
  Call(this.client, this.status, this.body);

  final Client client;
  final int status;
  final Map<String, dynamic>? body;
}
