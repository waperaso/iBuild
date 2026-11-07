import 'package:ibuild_server/ibuild_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'dart:convert';

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

  Future<Call> post(Client c, String path, Map<String, dynamic> json) =>
      c.send('POST', path, json: json, csrf: true);

  test('a letter is sealed in the database and readable by both sides', () async {
    final bank = await signIn('a.head1');
    final contacts = (await bank.send('GET', '/api/mail/contacts')).body!['items'] as List;
    expect(contacts, isNotEmpty);
    final developerId = ((contacts.cast<Map>()).firstWhere((p) => p['company'] != contacts.first['company'] || true))['id'];
    final sent = await post(bank, '/api/mail/messages', {
      'to': [developerId],
      'subject': 'Секретная тема',
      'body': 'Секретный текст письма',
    });
    expect(sent.status, 200, reason: sent.body.toString());

    final raw = await db.owner.execute('SELECT subject, body FROM messages ORDER BY created_at DESC LIMIT 1');
    expect(raw.first[0], startsWith('v1.'));
    expect(raw.first[1], startsWith('v1.'));
    expect('${raw.first[0]}${raw.first[1]}', isNot(contains('Секретн')));

    final sentList = await bank.send('GET', '/api/mail/messages?folder=sent');
    expect((sentList.body!['items'] as List).first['subject'], 'Секретная тема');
  });

  test('inbox, unread count, reading, reply and delete', () async {
    final sender = await signIn('a.head1');
    final other = await db.owner.execute(
      "SELECT login FROM users WHERE login = 'a.committee1'",
    );
    expect(other, isNotEmpty);
    final receiver = await signIn('a.committee1');
    // Colleagues of one bank can always write to each other.
    final colleague = (await sender.send('GET', '/api/mail/contacts')).body!['items'] as List;
    final target = (await db.owner.execute("SELECT id::text FROM users WHERE login = 'a.committee1'")).first[0]! as String;
    expect(colleague.any((p) => (p as Map)['id'] == target), isTrue);

    final before = (await receiver.send('GET', '/api/mail/unread')).body!['count'] as int;
    final sent = await post(sender, '/api/mail/messages', {'to': [target], 'subject': 'Вопрос', 'body': 'Когда заседание?'});
    expect(sent.status, 200, reason: sent.body.toString());
    expect((await receiver.send('GET', '/api/mail/unread')).body!['count'], before + 1);

    final inbox = (await receiver.send('GET', '/api/mail/messages')).body!['items'] as List;
    final first = inbox.first as Map;
    expect(first['subject'], 'Вопрос');
    expect(first['unread'], true);

    final read = await receiver.send('GET', '/api/mail/messages/${first['id']}');
    expect(read.status, 200);
    expect(((read.body!['messages'] as List).first as Map)['body'], 'Когда заседание?');
    expect((await receiver.send('GET', '/api/mail/unread')).body!['count'], before);

    final reply = await post(receiver, '/api/mail/messages', {
      'to': [(first['sender_id'] ?? (read.body!['messages'] as List).first['sender_id'])],
      'subject': 'Re: Вопрос',
      'body': 'Завтра',
      'threadId': first['thread_id'],
    });
    expect(reply.status, 200, reason: reply.body.toString());
    final thread = await sender.send('GET', '/api/mail/messages/${first['id']}');
    expect((thread.body!['messages'] as List).length, 2);

    // A stranger sees nothing.
    final stranger = await signIn('b.director');
    expect((await stranger.send('GET', '/api/mail/messages/${first['id']}')).status, 404);
    expect((await post(stranger, '/api/mail/messages', {'to': [target], 'subject': 'x', 'body': 'y'})).status, 403);

    expect((await post(receiver, '/api/mail/messages/${first['id']}/delete', {})).status, 200);
    expect((await receiver.send('GET', '/api/mail/messages/${first['id']}')).status, 404);
    expect((await sender.send('GET', '/api/mail/messages/${first['id']}')).status, 200);
  });

  test('validation and sessions', () async {
    expect((await Client(handler).send('GET', '/api/mail/unread')).status, 401);
    final c = await signIn('a.head1');
    expect((await post(c, '/api/mail/messages', {'to': [], 'subject': 'x', 'body': 'y'})).status, 400);
    expect((await post(c, '/api/mail/messages', {'to': ['nope'], 'subject': 'x', 'body': 'y'})).status, 400);
    final me = (await db.owner.execute("SELECT id::text FROM users WHERE login = 'a.head1'")).first[0]!;
    expect((await post(c, '/api/mail/messages', {'to': [me], 'subject': 'x', 'body': 'y'})).status, 400);
  });

  test('the administrator creates accounts and approves a bank application', () async {
    final admin = await signIn('a.admin');
    expect((await post(await signIn('a.head1'), '/api/admin/users', {'name': 'X', 'login': 'xx1', 'role': 'head'})).status, 403);

    final companies = ((await admin.send('GET', '/api/admin/companies')).body!['items'] as List).cast<Map>();
    final developer = companies.firstWhere((c) => c['kind'] == 'developer');
    final made = await post(admin, '/api/admin/users', {
      'companyId': developer['id'], 'name': 'Новый Прораб', 'login': 'New.Foreman', 'role': 'tech',
    });
    expect(made.status, 200, reason: made.body.toString());
    expect(made.body!['login'], 'new.foreman');
    final fresh = Client(handler);
    expect((await fresh.login('new.foreman', made.body!['password'] as String)).status, 200);
    final untouched = await db.owner.execute(
      "SELECT count(*) FROM project_members m JOIN users u ON u.id = m.user_id WHERE u.login = 'new.foreman'",
    );
    expect(untouched.first[0], 0);
    expect((await post(admin, '/api/admin/users', {'companyId': developer['id'], 'name': 'Дубль', 'login': 'new.foreman', 'role': 'tech'})).status, 409);
    expect((await post(admin, '/api/admin/users', {'companyId': developer['id'], 'name': 'Дубль', 'login': 'dub.le', 'role': 'head'})).status, 400);

    final bank = await post(admin, '/api/admin/users', {
      'company': {'kind': 'bank', 'name': 'Тест Банк', 'inn': '777000111'},
      'name': 'Админ Тест Банка', 'login': 'tb.admin', 'role': 'admin',
    });
    expect(bank.status, 200, reason: bank.body.toString());
    final bankLogin = Client(handler);
    expect((await bankLogin.login('tb.admin', bank.body!['password'] as String)).status, 200);
    expect((await bankLogin.send('GET', '/api/bank/queue')).status, lessThan(500));

    final inserted = await db.owner.execute(
      "INSERT INTO applications (kind, status, org_name, inn, contact_name, phone, email, region, data, token_hash, consent_at, consent_version) "
      "VALUES ('bank','new','АКБ Новый','200111222','Иван Банков','+998901112233','ivan@newbank.example','tashkent_city','{}'::jsonb,'h-bank-1',now(),'1') RETURNING id::text",
    );
    final id = inserted.first[0]! as String;
    for (final rule in bankDocs.where((d) => d.required)) {
      await db.owner.execute(
        Sql.named("INSERT INTO application_documents (application_id, doc_type, file_name, content_type, size_bytes, storage_path) VALUES (@id::uuid, @type, 'a.pdf', 'application/pdf', 10, '/tmp/none')"),
        parameters: {'id': id, 'type': rule.type},
      );
    }
    final detail = (await admin.send('GET', '/api/admin/applications/$id')).body!;
    for (final key in (detail['checkKeys'] as List)) {
      await post(admin, '/api/admin/applications/$id/checks', {'key': key, 'done': true});
    }
    final approved = await post(admin, '/api/admin/applications/$id/approve', {});
    expect(approved.status, 200, reason: approved.body.toString());
    final account = approved.body!['account'] as Map;
    expect(account['login'], 'ivan@newbank.example');
    final staff = await db.owner.execute("SELECT s.role FROM bank_staff s JOIN users u ON u.id = s.user_id WHERE u.login = 'ivan@newbank.example'");
    expect(staff.first[0], 'admin');
    final entered = Client(handler);
    expect((await entered.login('ivan@newbank.example', account['password'] as String)).status, 200);
  });

  test('an account receives only the projects and roles that were chosen', () async {
    final admin = await signIn('a.admin');
    final director = await signIn('a.director');
    final me = await director.send('GET', '/api/auth/me');
    final companyId = me.body!['companyId'] as String;
    final companies = ((await admin.send('GET', '/api/admin/companies')).body!['items'] as List).cast<Map>();
    final developer = companies.firstWhere((company) => company['id'] == companyId);
    final known = (developer['projects'] as List).cast<Map>();
    expect(known, isNotEmpty);
    final created = await post(director, '/api/projects', {'name': 'Второй объект', 'address': 'Ташкент, новый'});
    expect(created.status, 201, reason: created.body.toString());
    final second = created.body!['id'] as String;
    expect(known.any((project) => project['id'] == second), isFalse);

    final bare = await post(admin, '/api/admin/users', {
      'companyId': companyId,
      'name': 'Только вход',
      'login': 'only.login',
      'role': 'director',
    });
    expect(bare.status, 200, reason: bare.body.toString());
    final bareRows = await db.owner.execute(
      "SELECT count(*) FROM project_members m JOIN users u ON u.id = m.user_id WHERE u.login = 'only.login'",
    );
    expect(bareRows.first[0], 0);
    final bareClient = Client(handler);
    expect((await bareClient.login('only.login', bare.body!['password'] as String)).status, 200);
    expect((await post(bareClient, '/api/projects', {'name': 'Чужой', 'address': 'нет'})).status, 403);

    final made = await post(admin, '/api/admin/users', {
      'companyId': companyId,
      'name': 'Технадзор Два',
      'login': 'site.tech',
      'role': 'director',
      'assignments': [
        {'projectId': second, 'role': 'tech'},
      ],
    });
    expect(made.status, 200, reason: made.body.toString());
    final rows = await db.owner.execute(
      "SELECT p.id::text, m.role FROM project_members m JOIN users u ON u.id = m.user_id JOIN projects p ON p.id = m.project_id WHERE u.login = 'site.tech'",
    );
    expect(rows, hasLength(1));
    expect(rows.first[0], second);
    expect(rows.first[1], 'tech');
    final tech = Client(handler);
    expect((await tech.login('site.tech', made.body!['password'] as String)).status, 200);
    final mine = ((await tech.send('GET', '/api/projects')).body!['projects'] as List).cast<Map>();
    expect(mine.map((project) => project['id']), [second]);
    expect(mine.single['myRole'], 'tech');
    expect((await post(tech, '/api/projects', {'name': 'Нет', 'address': 'нет'})).status, 403);
    expect((await post(tech, '/api/projects/$second/members', {
      'userId': '00000000-0000-4000-8000-000000000099',
      'role': 'director',
    })).status, 403);

    final foreign = companies.firstWhere((company) => company['id'] != companyId && (company['projects'] as List).isNotEmpty);
    final denied = await post(admin, '/api/admin/users', {
      'companyId': companyId,
      'name': 'Чужой объект',
      'login': 'foreign.role',
      'assignments': [
        {'projectId': (foreign['projects'] as List).first['id'], 'role': 'director'},
      ],
    });
    expect(denied.status, 400, reason: denied.body.toString());
    expect(denied.body!['message'], 'Этот объект не принадлежит выбранной организации.');

    final duplicate = await post(admin, '/api/admin/users', {
      'companyId': companyId,
      'name': 'Две роли',
      'login': 'two.roles',
      'assignments': [
        {'projectId': second, 'role': 'tech'},
        {'projectId': second, 'role': 'director'},
      ],
    });
    expect(duplicate.status, 400, reason: duplicate.body.toString());

    final firms = await director.send('GET', '/api/contractor-firms');
    final firmId = (firms.body!['firms'] as List).cast<Map>().first['id'] as String;
    final noFirm = await post(admin, '/api/admin/users', {
      'companyId': companyId,
      'name': 'Без фирмы',
      'login': 'no.firm',
      'assignments': [
        {'projectId': second, 'role': 'contractor'},
      ],
    });
    expect(noFirm.status, 400, reason: noFirm.body.toString());
    final withFirm = await post(admin, '/api/admin/users', {
      'companyId': companyId,
      'name': 'С фирмой',
      'login': 'with.firm',
      'assignments': [
        {'projectId': second, 'role': 'contractor', 'contractorFirmId': firmId},
      ],
    });
    expect(withFirm.status, 200, reason: withFirm.body.toString());
    final firmRow = await db.owner.execute(
      "SELECT m.role, m.contractor_company_id::text FROM project_members m JOIN users u ON u.id = m.user_id WHERE u.login = 'with.firm'",
    );
    expect(firmRow.single[0], 'contractor');
    expect(firmRow.single[1], firmId);

    final bank = companies.firstWhere((company) => company['kind'] == 'bank');
    final bankBad = await post(admin, '/api/admin/users', {
      'companyId': bank['id'],
      'name': 'Банк с объектом',
      'login': 'bank.project',
      'role': 'specialist',
      'assignments': [
        {'projectId': second, 'role': 'tech'},
      ],
    });
    expect(bankBad.status, 400, reason: bankBad.body.toString());
    expect(bankBad.body!['message'], 'Сотруднику банка роль задаётся в банке, а не на объекте застройщика.');
  });

  test('legacy outbox letters get sealed', () async {
    await db.owner.execute(
      "INSERT INTO mail_outbox (kind, to_email, subject, body, status) VALUES ('test','x@y.uz','Открытая','Открытое тело','queued')",
    );
    expect(await sealLegacyMail(db), greaterThan(0));
    final rows = await db.owner.execute("SELECT subject FROM mail_outbox WHERE to_email = 'x@y.uz'");
    expect(rows.first[0], startsWith('v1.'));
    expect(await Vault.open(rows.first[0]! as String), 'Открытая');
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
