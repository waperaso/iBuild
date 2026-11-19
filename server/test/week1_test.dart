import 'dart:convert';
import 'dart:io';

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
    await db.migrate('migrations');
    await db.truncateAll();
    await seedDemo(db, password);
    await seedIfEmpty(db, password);
    handler = buildHandler(db: db, env: _env());
  });

  tearDownAll(() async {
    await db.close();
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
  });

  test('passwords are hashed and future money tables stay empty', () async {
    final hashes = await db.pool.execute('SELECT password_hash FROM users');
    expect(hashes, isNotEmpty);
    for (final row in hashes) {
      final hash = row[0]! as String;
      expect(hash, isNot(password));
      expect(hash.startsWith(r'$2'), isTrue);
    }
    expect(await db.countOf('budget_items'), 7);
    for (final table in ['funding_requests', 'request_files', 'audit_events']) {
      expect(await db.countOf(table), 0, reason: table);
    }
    final column = await db.pool.execute('''
      SELECT data_type, numeric_precision, numeric_scale
      FROM information_schema.columns
      WHERE table_name = 'budget_items' AND column_name = 'planned_amount'
    ''');
    expect(column.first[0], 'numeric');
    expect(column.first[1], 18);
    expect(column.first[2], 2);
  });

  test('login branches', () async {
    final client = Client(handler);

    final empty = await client.send('POST', '/api/auth/login', json: {
      'login': '',
      'password': '',
    });
    expect(empty.status, 400);
    expect(empty.body!['message'], 'Введите логин и пароль.');

    final missingCsrf = await client.send('POST', '/api/auth/login', json: {
      'login': 'a.director',
      'password': 'wrong',
    });
    expect(missingCsrf.status, 403);
    expect(missingCsrf.body!['error'], 'csrf');

    await client.fetchCsrf();
    final wrong = await client.send('POST', '/api/auth/login', json: {
      'login': 'a.director',
      'password': 'wrong',
    }, csrf: true);
    expect(wrong.status, 401);
    expect(wrong.body!['message'], 'Неверный логин или пароль.');

    final unknown = await client.send('POST', '/api/auth/login', json: {
      'login': 'nobody',
      'password': password,
    }, csrf: true);
    expect(unknown.status, 401);

    final disabled = await Client(handler).login('a.disabled', password);
    expect(disabled.status, 403);
    expect(disabled.body!['message'], 'Эта учётная запись отключена.');

    final ok = await Client(handler).login('a.director', password);
    expect(ok.status, 200);
    expect(ok.body!['login'], 'a.director');
    expect(ok.body!.containsKey('passwordHash'), isFalse);
    expect(
      ok.setCookies.any((line) => line.startsWith('ibuild_session=') && line.contains('HttpOnly')),
      isTrue,
    );

    final me = await ok.client.send('GET', '/api/auth/me');
    expect(me.status, 200);
    expect(me.body!['companyName'], 'Навои Девелопмент');

    final loggedOut = await ok.client.send('POST', '/api/auth/logout', json: {}, csrf: true);
    expect(loggedOut.status, 204);
    expect(ok.client.cookies.containsKey('ibuild_session'), isFalse);

    final again = await ok.client.send('POST', '/api/auth/logout');
    expect(again.status, 401);
    expect(again.body!['message'], 'Вы уже вышли из аккаунта.');

    final repeat = Client(handler);
    final signed = await repeat.login('a.tech', password);
    expect(signed.status, 200);
    final stale = Map<String, String>.from(repeat.cookies);
    final second = await repeat.send('POST', '/api/auth/logout', json: {}, csrf: true);
    expect(second.status, 204);
    repeat.cookies.addAll(stale);
    final replay = await repeat.send('POST', '/api/auth/logout', json: {}, csrf: true);
    expect(replay.status, 204);
  });

  test('expired session and a disabled account lose access', () async {
    final client = Client(handler);
    final signed = await client.login('a.observer', password);
    expect(signed.status, 200);
    final token = client.cookies['ibuild_session']!;
    await db.expireSessionByHash(sha256Hex(token));
    final expired = await client.send('GET', '/api/auth/me');
    expect(expired.status, 401);
    expect(expired.body!['message'], 'Войдите, чтобы продолжить.');

    final again = Client(handler);
    expect((await again.login('a.observer', password)).status, 200);
    await db.setActive('a.observer', false);
    final blocked = await again.send('GET', '/api/projects');
    expect(blocked.status, 403);
    expect(blocked.body!['error'], 'inactive');
    await db.setActive('a.observer', true);
  });

  test('five failures lock the next attempt', () async {
    final companyId = await db.companyIdByInn('300000001');
    await db.insertUser(
      companyId: companyId!,
      name: 'Проверка лимита',
      login: 'a.ratelimit',
      passwordHash: hashPassword(password),
    );
    final client = Client(handler);
    await client.fetchCsrf();
    for (var attempt = 0; attempt < 5; attempt++) {
      final wrong = await client.send('POST', '/api/auth/login', json: {
        'login': 'a.ratelimit',
        'password': 'nope-$attempt',
      }, csrf: true);
      expect(wrong.status, 401, reason: 'attempt $attempt');
    }
    final locked = await client.send('POST', '/api/auth/login', json: {
      'login': 'a.ratelimit',
      'password': password,
    }, csrf: true);
    expect(locked.status, 429);
    expect(locked.body!['message'], 'Слишком много попыток. Подождите и попробуйте снова.');
  });

  test('every role of both companies is isolated', () async {
    final anon = Client(handler);
    final health = await anon.send('GET', '/api/health');
    expect(health.status, 200);
    final csp = health.headers['content-security-policy'] ?? '';
    expect(csp, contains("default-src 'self'"));
    expect(csp, contains("frame-ancestors 'none'"));
    expect(csp, contains("object-src 'none'"));
    expect(csp, contains("script-src 'self' 'wasm-unsafe-eval' blob:"));
    expect(csp, contains("style-src 'self'"));
    expect(csp, isNot(contains('unsafe-inline')));
    expect(csp, isNot(contains('gstatic.com')));
    expect(csp, isNot(contains('*')));
    expect(RegExp(r'frame-src [^;]+').allMatches(csp).map((match) => match.group(0)).toList(), [
      'frame-src https://www.openstreetmap.org',
    ]);
    expect(csp, isNot(contains('frame-src *')));
    expect(csp, isNot(contains('https://tile.openstreetmap.org')));
    expect((await anon.send('GET', '/api/auth/csrf')).status, 200);
    expect((await anon.send('GET', '/api/auth/me')).status, 401);
    expect((await anon.send('GET', '/api/projects')).status, 401);
    expect((await anon.send('POST', '/api/projects', json: {
      'name': 'Чужой',
      'address': 'Адрес',
    })).status, 401);
    expect((await anon.send('POST', '/api/auth/logout')).status, 401);

    final logins = [
      'a.director',
      'a.contractor',
      'a.tech',
      'a.observer',
      'b.director',
      'b.contractor',
      'b.tech',
      'b.observer',
    ];
    final ownIds = <String, String>{};
    final companyIds = <String, String>{};
    for (final login in logins) {
      final client = Client(handler);
      final signed = await client.login(login, password);
      expect(signed.status, 200, reason: login);
      expect((await client.send('GET', '/api/health')).status, 200);
      expect((await client.send('GET', '/api/auth/me')).status, 200);
      final list = await client.send('GET', '/api/projects');
      expect(list.status, 200, reason: login);
      final projects = (list.body!['projects'] as List).cast<Map<String, dynamic>>();
      expect(projects, hasLength(1), reason: login);
      final project = projects.single;
      ownIds[login] = project['id'] as String;
      companyIds[login] = project['companyId'] as String;
      expect(project['plan'], _expectedPlan(login));
      expect(project['reserved'], '0.00');
      expect(project['paid'], '0.00');
      expect(project['available'], project['plan']);
      expect(project['name'], login.startsWith('a.') ? 'ЖК Навои' : 'ЖК Чиланзар');
      final card = await client.send('GET', '/api/projects/${ownIds[login]}');
      expect(card.status, 200, reason: login);
      expect(card.body!['myRole'], _roleOf(login));
    }

    for (final login in logins) {
      final client = Client(handler);
      await client.login(login, password);
      final foreignLogin = login.startsWith('a.') ? 'b.director' : 'a.director';
      final foreign = await client.send('GET', '/api/projects/${ownIds[foreignLogin]}');
      expect(foreign.status, 404, reason: '$login -> $foreignLogin');
      expect(foreign.body!['error'], 'not_found');

      final created = await client.send('POST', '/api/projects', json: {
        'name': 'Проверка $login',
        'address': 'Ташкент',
        'companyId': companyIds[foreignLogin],
      }, csrf: true);
      if (login.endsWith('director')) {
        expect(created.status, 201, reason: login);
        expect(created.body!['companyId'], companyIds[login]);
        expect(created.body!['plan'], '0.00');
        expect(created.body!['available'], '0.00');
        final other = Client(handler);
        await other.login(foreignLogin, password);
        final hidden = await other.send('GET', '/api/projects/${created.body!['id']}');
        expect(hidden.status, 404, reason: login);
      } else {
        expect(created.status, 403, reason: login);
        expect(created.body!['error'], 'forbidden');
      }
    }

    final director = Client(handler);
    await director.login('a.director', password);
    final withoutCsrf = await director.send('POST', '/api/projects', json: {
      'name': 'Без токена',
      'address': 'Ташкент',
    });
    expect(withoutCsrf.status, 403);
    expect(withoutCsrf.body!['error'], 'csrf');
  });

  test('operator can create, reset, and disable an account', () async {
    final created = await Process.run(Platform.resolvedExecutable, [
      'run',
      'bin/operator.dart',
      'create',
      '--inn',
      '300000001',
      '--login',
      'a.operator',
      '--name',
      'Учётная запись оператора',
      '--password',
      'Operator-pass-1',
    ], environment: {'DATABASE_URL': testDatabaseUrl});
    expect(created.exitCode, 0, reason: '${created.stdout}\n${created.stderr}');

    final client = Client(handler);
    expect((await client.login('a.operator', 'Operator-pass-1')).status, 200);
    final empty = await client.send('GET', '/api/projects');
    expect((empty.body!['projects'] as List), isEmpty);

    final reset = await Process.run(Platform.resolvedExecutable, [
      'run',
      'bin/operator.dart',
      'reset-password',
      '--login',
      'a.operator',
      '--password',
      'Operator-pass-2',
    ], environment: {'DATABASE_URL': testDatabaseUrl});
    expect(reset.exitCode, 0, reason: '${reset.stderr}');

    expect((await Client(handler).login('a.operator', 'Operator-pass-1')).status, 401);
    expect((await Client(handler).login('a.operator', 'Operator-pass-2')).status, 200);

    final disabled = await Process.run(Platform.resolvedExecutable, [
      'run',
      'bin/operator.dart',
      'set-active',
      '--login',
      'a.operator',
      '--active',
      'false',
    ], environment: {'DATABASE_URL': testDatabaseUrl});
    expect(disabled.exitCode, 0, reason: '${disabled.stderr}');
    final blocked = await Client(handler).login('a.operator', 'Operator-pass-2');
    expect(blocked.status, 403);
    expect(blocked.body!['message'], 'Эта учётная запись отключена.');
  });
}

String _roleOf(String login) => login.split('.').last;

String _expectedPlan(String login) {
  if (login.startsWith('b.')) return chilonzorPlan;
  if (login == 'a.contractor') return navoiMasonryPlan;
  return navoiPlan;
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
  Call(this.client, this.status, this.body, this.setCookies, this.headers);

  final Client client;
  final int status;
  final Map<String, dynamic>? body;
  final List<String> setCookies;
  final Map<String, String> headers;
}

class Client {
  Client(this.handler);

  final Handler handler;
  final cookies = <String, String>{};
  String? csrf;

  Future<void> fetchCsrf() async {
    await send('GET', '/api/auth/csrf');
  }

  Future<Call> login(String login, String password) async {
    await fetchCsrf();
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
    _takeCookies(setCookies);
    final raw = await response.readAsString();
    Map<String, dynamic>? body;
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        body = decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    if (body?['csrfToken'] is String) {
      this.csrf = body!['csrfToken'] as String;
    }
    return Call(this, response.statusCode, body, setCookies, response.headers);
  }

  void _takeCookies(List<String> lines) {
    for (final line in lines) {
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
