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

final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3]);

Map<String, Object?> developerForm({String inn = '301234567', String email = 'new.dev@example.uz'}) => {
  'org_full_name': 'ООО «Тест Девелопмент»',
  'legal_form': 'llc',
  'inn': inn,
  'reg_number': '12345',
  'reg_date': '2019-05-14',
  'reg_authority': 'Агентство государственных услуг',
  'charter_capital': '500000000',
  'legal_address': 'г. Ташкент, ул. Тестовая, 1',
  'actual_address': 'г. Ташкент, ул. Тестовая, 1',
  'region': 'tashkent_city',
  'org_phone': '+998 71 200 00 00',
  'org_email': 'info@example.uz',
  'dir_name': 'Иван Директоров',
  'dir_position': 'Директор',
  'dir_pinfl': '31205880120045',
  'dir_passport': 'aa 1234567',
  'dir_passport_issued': '2020-01-10',
  'dir_passport_authority': 'ИИБ Мирзо-Улугбекского района',
  'dir_citizenship': 'Узбекистан',
  'dir_phone': '+998901234567',
  'dir_email': 'dir@example.uz',
  'dir_basis': 'charter',
  'owners': [
    {'kind': 'person', 'name': 'Иван Директоров', 'tax_id': '31205880120045', 'share': '100'},
  ],
  'beneficial_name': 'Иван Директоров',
  'beneficial_id': '31205880120045',
  'pdl': 'no',
  'object_name': 'ЖК «Тестовый»',
  'object_address': 'г. Ташкент, Чиланзар',
  'object_cadastre': '10:01:02:03:04:0005',
  'land_basis': 'lease',
  'land_doc_no': 'Договор аренды № 5 от 01.02.2024',
  'permit_number': 'РС-77',
  'permit_date': '2025-03-01',
  'expertise_number': 'Э-12',
  'expertise_date': '2025-02-01',
  'object_cost': '120000000000',
  'object_area': '24000',
  'commissioning_date': '2027-12-31',
  'own_funds_percent': '35',
  'escrow_status': 'planned',
  'bank_name': 'Тест Банк',
  'bank_mfo': '00014',
  'bank_account': '20208000000000000001',
  'contact_name': 'Пётр Контактов',
  'contact_position': 'Заместитель директора',
  'contact_phone': '90 111 22 33',
  'contact_email': email,
  'call_time': 'day',
  'language': 'ru',
};

void main() {
  late AppDatabase db;
  late Handler handler;
  late Connection lock;
  late Directory files;

  setUpAll(() async {
    final admin = Pool<void>.withUrl(
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
    await db.owner.execute('TRUNCATE applications CASCADE');
    await seedDemo(db, password);
    files = await Directory.systemTemp.createTemp('ibuild-reg-');
    handler = buildHandler(db: db, env: _env(files.path, 100));
  });

  tearDownAll(() async {
    await db.close();
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
    await files.delete(recursive: true);
  });

  test('a developer applies, sends papers, and the admin approves', () async {
    final visitor = _Client(handler);
    await visitor.csrf();

    // Missing consent, bad tax number and a trapped bot are all refused.
    var response = await visitor.post('/api/applications', {
      'kind': 'developer',
      'data': developerForm(),
      'consents': ['truth'],
    });
    expect(response.status, 400);
    expect(response.json['field'], 'consents');

    response = await visitor.post('/api/applications', {
      'kind': 'developer',
      'data': developerForm(inn: '123'),
      'consents': ['personal_data', 'truth'],
    });
    expect(response.status, 400);
    expect(response.json['field'], 'inn');

    final withoutToken = _Client(handler);
    response = await withoutToken.post('/api/applications', {
      'kind': 'developer',
      'data': developerForm(),
      'consents': ['personal_data', 'truth'],
    });
    expect(response.status, 403);

    response = await visitor.post('/api/applications', {
      'kind': 'developer',
      'data': developerForm(),
      'consents': ['personal_data', 'truth'],
      'website_url': 'http://spam.example',
    });
    expect(response.status, 201);
    final count = await db.owner.execute('SELECT count(*)::int FROM applications');
    expect(count.first[0], 0);

    response = await visitor.post('/api/applications', {
      'kind': 'developer',
      'data': developerForm(),
      'consents': ['personal_data', 'truth'],
    });
    expect(response.status, 201);
    final id = response.json['id'] as String;
    final token = response.json['token'] as String;
    expect(response.json['code'], startsWith('IB-'));

    // The same company cannot apply twice while the first one is open.
    response = await visitor.post('/api/applications', {
      'kind': 'developer',
      'data': developerForm(email: 'other@example.uz'),
      'consents': ['personal_data', 'truth'],
    });
    expect(response.status, 409);

    // The applicant sees only their own status.
    response = await visitor.get('/api/applications/status', token: token);
    expect(response.status, 200);
    expect(response.json['status'], 'new');
    expect((response.json['missing'] as List), contains('charter'));
    response = await visitor.get('/api/applications/status', token: 'nope');
    expect(response.status, 404);

    // Papers: wrong type, wrong bytes, wrong token, then the real ones.
    response = await visitor.upload(id, 'passport_selfie', png, token: token);
    expect(response.status, 400);
    response = await visitor.upload(id, 'charter', Uint8List.fromList([1, 2, 3, 4, 5, 6]), token: token);
    expect(response.status, 400);
    response = await visitor.upload(id, 'charter', png, token: 'wrong');
    expect(response.status, 404);
    final docs = [
      'registration_cert',
      'charter',
      'director_id',
      'owners_proof',
      'bank_details',
      'land_rights',
      'construction_permit',
      'tax_clearance',
      'ecology_approval',
    ];
    for (final type in docs) {
      response = await visitor.upload(id, type, png, token: token);
      expect(response.status, 201, reason: type);
    }

    // Admin side is closed to everyone else.
    final director = _Client(handler);
    expect((await director.login('a.director', password)).status, 200);
    expect((await director.get('/api/admin/applications')).status, 403);
    expect((await visitor.get('/api/admin/applications')).status, 401);

    final admin = _Client(handler);
    expect((await admin.login('a.admin', password)).status, 200);
    response = await admin.get('/api/admin/applications');
    expect(response.status, 200);
    expect((response.json['counts'] as Map)['new'], 1);
    expect((response.json['items'] as List), hasLength(1));
    response = await admin.get('/api/admin/applications?q=${Uri.encodeQueryComponent('Тест')}');
    expect((response.json['items'] as List), hasLength(1));
    response = await admin.get('/api/admin/applications?status=rejected');
    expect((response.json['items'] as List), isEmpty);

    // A call moves it to "calling".
    response = await admin.post('/api/admin/applications/$id/calls', {
      'outcome': 'reached',
      'note': 'Подтвердили заявку',
      'nextCallOn': '2026-11-03',
    });
    expect(response.status, 200);
    expect(response.json['status'], 'calling');
    expect(response.json['nextCallOn'], '2026-11-03');

    // Approve is blocked: one required paper is missing and nothing is ticked.
    response = await admin.post('/api/admin/applications/$id/approve', {});
    expect(response.status, 409);

    // Ask for the missing paper; the applicant sees the request.
    response = await admin.post('/api/admin/applications/$id/status', {
      'status': 'docs_requested',
      'note': '',
    });
    expect(response.status, 400);
    response = await admin.post('/api/admin/applications/$id/status', {
      'status': 'docs_requested',
      'note': 'Пришлите заключение экспертизы.',
    });
    expect(response.status, 200);
    response = await visitor.get('/api/applications/status', token: token);
    expect(response.json['requestNote'], 'Пришлите заключение экспертизы.');
    expect(response.json['missing'], ['expertise_conclusion']);
    response = await visitor.upload(id, 'expertise_conclusion', png, token: token);
    expect(response.status, 201);
    response = await visitor.get('/api/applications/status', token: token);
    expect(response.json['status'], 'in_review');

    response = await admin.post('/api/admin/applications/$id/approve', {});
    expect(response.status, 409, reason: 'checks are not ticked');
    for (final key in developerChecks) {
      response = await admin.post('/api/admin/applications/$id/checks', {'key': key, 'done': true});
      expect(response.status, 200);
    }
    response = await admin.post('/api/admin/applications/$id/checks', {'key': 'bogus', 'done': true});
    expect(response.status, 400);

    // The admin can open a paper.
    final detail = await admin.get('/api/admin/applications/$id');
    final firstDoc = (detail.json['documents'] as List).first as Map;
    final file = await admin.getRaw('/api/admin/applications/$id/documents/${firstDoc['id']}');
    expect(file.statusCode, 200);
    expect(file.headers['x-content-type-options'], 'nosniff');
    expect((await file.read().expand((chunk) => chunk).toList()).length, png.length);

    response = await admin.post('/api/admin/applications/$id/approve', {});
    expect(response.status, 200);
    final account = response.json['account'] as Map;
    expect(account['login'], 'new.dev@example.uz');
    expect((account['password'] as String).length, 10);
    expect((response.json['application'] as Map)['status'], 'approved');

    // The new director can sign in and already has an object.
    final newcomer = _Client(handler);
    final signedIn = await newcomer.login(account['login'] as String, account['password'] as String);
    expect(signedIn.status, 200);
    final projects = await newcomer.get('/api/projects');
    expect((projects.json['projects'] as List), hasLength(1));
    expect(((projects.json['projects'] as List).first as Map)['name'], 'ЖК «Тестовый»');

    // A closed application takes no more papers or decisions.
    response = await visitor.upload(id, 'other', png, token: token);
    expect(response.status, 409);
    response = await admin.post('/api/admin/applications/$id/status', {
      'status': 'rejected',
      'note': 'Поздно',
    });
    expect(response.status, 409);

    // The same company is now a customer, so it cannot apply again.
    response = await visitor.post('/api/applications', {
      'kind': 'developer',
      'data': developerForm(),
      'consents': ['personal_data', 'truth'],
    });
    expect(response.status, 409);
  });

  test('a rejected application can be sent again; an approved bank gets an administrator', () async {
    final visitor = _Client(handler);
    await visitor.csrf();
    final admin = _Client(handler);
    await admin.login('a.admin', password);

    var response = await visitor.post('/api/applications', {
      'kind': 'developer',
      'data': developerForm(inn: '302222222', email: 'second@example.uz'),
      'consents': ['personal_data', 'truth'],
    });
    expect(response.status, 201);
    final id = response.json['id'] as String;
    response = await admin.post('/api/admin/applications/$id/status', {
      'status': 'rejected',
      'note': 'Нет разрешения на строительство.',
    });
    expect(response.status, 200);
    response = await visitor.get('/api/applications/status', token: 'x');
    expect(response.status, 404);
    response = await visitor.post('/api/applications', {
      'kind': 'developer',
      'data': developerForm(inn: '302222222', email: 'second@example.uz'),
      'consents': ['personal_data', 'truth'],
    });
    expect(response.status, 201);

    response = await visitor.post('/api/applications', {
      'kind': 'bank',
      'data': {
        'org_full_name': 'АКБ «Тест»',
        'inn': '200111222',
        'bank_mfo': '00999',
        'license_number': '№ 55',
        'license_date': '2001-03-03',
        'legal_address': 'г. Ташкент',
        'region': 'tashkent_city',
        'org_phone': '+998712000000',
        'org_email': 'bank@example.uz',
        'contact_name': 'Дилноза',
        'contact_position': 'Начальник отдела',
        'contact_phone': '+998901112233',
        'contact_email': 'dilnoza@example.uz',
        'authority_basis': 'poa',
        'call_time': 'any',
        'language': 'uz',
      },
      'interests': ['escrow'],
      'consents': ['personal_data', 'truth'],
    });
    expect(response.status, 400);
    expect(response.json['field'], 'interests', reason: 'interests live inside data');

    response = await visitor.post('/api/applications', {
      'kind': 'bank',
      'data': {
        'org_full_name': 'АКБ «Тест»',
        'inn': '200111222',
        'bank_mfo': '00999',
        'license_number': '№ 55',
        'license_date': '2001-03-03',
        'legal_address': 'г. Ташкент',
        'region': 'tashkent_city',
        'org_phone': '+998712000000',
        'org_email': 'bank@example.uz',
        'contact_name': 'Дилноза',
        'contact_position': 'Начальник отдела',
        'contact_phone': '+998901112233',
        'contact_email': 'dilnoza@example.uz',
        'authority_basis': 'poa',
        'call_time': 'any',
        'language': 'uz',
        'interests': ['escrow', 'tranche_control'],
      },
      'consents': ['personal_data', 'truth'],
    });
    expect(response.status, 201);
    final bankId = response.json['id'] as String;
    final bankToken = response.json['token'] as String;
    for (final type in ['bank_license', 'bank_registration', 'charter', 'authority', 'representative_id']) {
      expect((await visitor.upload(bankId, type, png, token: bankToken)).status, 201);
    }
    // A bank cannot send developer papers.
    expect((await visitor.upload(bankId, 'land_rights', png, token: bankToken)).status, 400);
    for (final key in bankChecks) {
      await admin.post('/api/admin/applications/$bankId/checks', {'key': key, 'done': true});
    }
    final companiesBefore = await db.companyCount();
    response = await admin.post('/api/admin/applications/$bankId/approve', {});
    expect(response.status, 200);
    final account = response.json['account'] as Map;
    expect(account['login'], 'dilnoza@example.uz');
    expect(await db.companyCount(), companiesBefore + 1);
    final staff = await db.owner.execute(
      "SELECT s.role FROM bank_staff s JOIN users u ON u.id = s.user_id WHERE u.login = 'dilnoza@example.uz'",
    );
    expect(staff.first[0], 'admin');
    final rules = await db.owner.execute(
      "SELECT count(*) FROM bank_rule_versions v JOIN companies c ON c.id = v.bank_id WHERE c.inn = '200111222'",
    );
    expect('${rules.first[0]}', '1');
    final groups = await db.owner.execute(
      "SELECT g.code FROM bank_groups g JOIN companies c ON c.id = g.bank_id WHERE c.inn = '200111222' ORDER BY g.code",
    );
    expect(groups.map((row) => row[0]).toList(), ['committee', 'heads']);
  });

  test('a director connects one bank and only that bank admin sets the credit limit', () async {
    final admin = _Client(handler);
    await admin.login('a.admin', password);
    final created = await admin.post('/api/admin/users', {
      'company': {'kind': 'developer', 'name': 'QA Zero Development', 'inn': '309000111'},
      'name': 'QA Director',
      'login': 'qa.zero.director',
      'role': 'director',
      'firstProject': {'name': 'QA Zero Residence', 'address': 'Ташкент, Нукус, 1'},
    });
    expect(created.status, 200, reason: created.json.toString());
    final director = _Client(handler);
    expect((await director.login('qa.zero.director', created.json['password'] as String)).status, 200);
    final projectId = ((await director.get('/api/projects')).json['projects'] as List).cast<Map>().single['id'] as String;
    expect((await director.post('/api/projects', {'name': 'Второй', 'address': 'Ташкент'})).status, 201);

    final bankCompany = (await db.owner.execute("SELECT id::text FROM companies WHERE inn = '200111222'")).first[0]! as String;
    final head = await admin.post('/api/admin/users', {
      'companyId': bankCompany,
      'name': 'QA Head',
      'login': 'qa.zero.head',
      'role': 'head',
    });
    expect(head.status, 200, reason: head.json.toString());
    final membership = await db.owner.execute(
      "SELECT g.code FROM bank_group_members m JOIN bank_groups g ON g.id = m.group_id JOIN users u ON u.id = m.user_id WHERE u.login = 'qa.zero.head'",
    );
    expect(membership.single[0], 'heads');

    expect((await director.post('/api/projects/$projectId/bank', {'inn': '123'})).status, 400);
    expect((await director.post('/api/projects/$projectId/bank', {'inn': '309000111'})).status, 404);
    final linked = await director.post('/api/projects/$projectId/bank', {'inn': '200111222'});
    expect(linked.status, 201, reason: linked.json.toString());
    expect((await director.post('/api/projects/$projectId/bank', {'inn': '200111222'})).status, 409);

    final bankUser = (await db.owner.execute("SELECT id::text FROM users WHERE login = 'dilnoza@example.uz'")).first[0]! as String;
    final reset = await admin.post('/api/admin/users/$bankUser/reset-password', {});
    expect(reset.status, 200, reason: reset.json.toString());
    final bankAdmin = _Client(handler);
    expect((await bankAdmin.login('dilnoza@example.uz', reset.json['password'] as String)).status, 200);
    final headClient = _Client(handler);
    expect((await headClient.login('qa.zero.head', head.json['password'] as String)).status, 200);
    expect((await headClient.post('/api/bank/objects/$projectId/limit', {'creditLimit': '1000.00'})).status, 403);
    expect((await bankAdmin.post('/api/bank/objects/$projectId/limit', {'creditLimit': '0'})).status, 400);
    expect((await bankAdmin.post('/api/bank/objects/$projectId/limit', {'creditLimit': '500000000.00', 'utilizeUntil': 'soon'})).status, 400);
    final limited = await bankAdmin.post('/api/bank/objects/$projectId/limit', {
      'creditLimit': '500000000.00',
      'utilizeUntil': '2027-12-31',
    });
    expect(limited.status, 200, reason: limited.json.toString());
    final stored = await db.owner.execute(
      "SELECT to_char(credit_limit, 'FM999999999999990.00'), utilize_until::text FROM project_facilities WHERE project_id = '$projectId'::uuid",
    );
    expect(stored.single[0], '500000000.00');
    expect(stored.single[1], '2027-12-31');
  });

  test('applications are out of reach of the app role', () async {
    for (final table in ['applications', 'application_documents', 'application_events']) {
      final rows = await db.owner.execute(
        Sql.named("SELECT has_table_privilege('ibuild_app', @table, 'SELECT')"),
        parameters: {'table': table},
      );
      expect(rows.first[0], isFalse, reason: table);
    }
  });

  test('too many applications from one address are slowed down', () async {
    final strict = buildHandler(db: db, env: _env(files.path, 2));
    final visitor = _Client(strict);
    await visitor.csrf();
    var last = 0;
    for (var i = 0; i < 3; i++) {
      final response = await visitor.post('/api/applications', {
        'kind': 'bank',
        'data': {'inn': 'bad'},
        'consents': ['personal_data', 'truth'],
      });
      last = response.status;
    }
    expect(last, 429);
  });

  test('a spoofed X-Forwarded-For does not open a new registration bucket', () async {
    final trusted = buildHandler(db: db, env: _env(files.path, 2, trustProxy: true));
    final visitor = _Client(trusted);
    await visitor.csrf();
    Future<int> send(String forwarded) async {
      final response = await visitor.post('/api/applications', {
        'kind': 'bank',
        'data': {'inn': 'bad'},
      }, headers: {'x-forwarded-for': forwarded});
      return response.status;
    }

    expect(await send('1.1.1.1, 10.0.0.8'), isNot(429));
    expect(await send('2.2.2.2, 10.0.0.8'), isNot(429));
    expect(await send('3.3.3.3, 10.0.0.8'), 429);

    final fresh = buildHandler(db: db, env: _env(files.path, 2));
    final direct = _Client(fresh);
    await direct.csrf();
    Future<int> sendDirect(String forwarded) async {
      final response = await direct.post('/api/applications', {
        'kind': 'bank',
        'data': {'inn': 'bad'},
      }, headers: {'x-forwarded-for': forwarded});
      return response.status;
    }

    expect(await sendDirect('1.1.1.1'), isNot(429));
    expect(await sendDirect('2.2.2.2'), isNot(429));
    expect(await sendDirect('3.3.3.3'), 429);
  });
}

AppEnv _env(String root, int perHour, {bool trustProxy = false}) {
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
    fileRoot: root,
    registrationPerHour: perHour,
    trustProxy: trustProxy,
  );
}

class _Reply {
  _Reply(this.status, this.json);

  final int status;
  final Map<String, dynamic> json;
}

class _Client {
  _Client(this.handler);

  final Handler handler;
  final cookies = <String, String>{};
  String? csrfToken;

  Future<void> csrf() async {
    await get('/api/auth/csrf');
  }

  Future<_Reply> login(String login, String pass) async {
    await csrf();
    return post('/api/auth/login', {'login': login, 'password': pass});
  }

  Map<String, String> _headers({String? token, bool json = false}) => {
    if (cookies.isNotEmpty) 'cookie': cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
    if (json) 'content-type': 'application/json',
    if (csrfToken != null) 'x-csrf-token': csrfToken!,
    if (token != null) 'x-application-token': token,
  };

  Future<Response> getRaw(String path) async {
    return await handler(Request("GET", Uri.parse("http://localhost$path"), headers: _headers()));
  }

  Future<_Reply> get(String path, {String? token}) async {
    final response = await handler(
      Request('GET', Uri.parse('http://localhost$path'), headers: _headers(token: token)),
    );
    return _read(response);
  }

  Future<_Reply> post(String path, Map<String, Object?> body, {Map<String, String> headers = const {}}) async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost$path'),
        headers: {..._headers(json: true), ...headers},
        body: jsonEncode(body),
      ),
    );
    return _read(response);
  }

  Future<_Reply> upload(String id, String type, Uint8List bytes, {required String token}) async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/applications/$id/documents?type=$type&name=scan.png'),
        headers: _headers(token: token),
        body: bytes,
      ),
    );
    return _read(response);
  }

  Future<_Reply> _read(Response response) async {
    for (final line in response.headersAll['set-cookie'] ?? const <String>[]) {
      final first = line.split(';').first;
      final at = first.indexOf('=');
      if (at <= 0) continue;
      final name = first.substring(0, at).trim();
      final value = first.substring(at + 1).trim();
      if (value.isEmpty) {
        cookies.remove(name);
      } else {
        cookies[name] = value;
      }
      if (name == 'ibuild_csrf') csrfToken = value;
    }
    final raw = await response.readAsString();
    Map<String, dynamic> json = {};
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) json = decoded.map((k, v) => MapEntry(k.toString(), v));
    }
    if (json['csrfToken'] is String) csrfToken = json['csrfToken'] as String;
    return _Reply(response.statusCode, json);
  }
}
