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
    files = await Directory.systemTemp.createTemp('ibuild-built');
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

  test('a multi-line draw keeps retainage, sources, inspection, and a bank cut', () async {
    final director = Client(handler);
    final tech = Client(handler);
    final bank = Client(handler);
    final other = Client(handler);
    expect((await director.login('a.director', password)).status, 200);
    expect((await tech.login('a.tech', password)).status, 200);
    expect((await bank.login('a.observer', password)).status, 200);
    expect((await other.login('b.director', password)).status, 200);

    final created = await director.send('POST', '/api/projects', json: {
      'name': 'Кредит Тест',
      'address': 'Ташкент, тест',
    });
    expect(created.status, 201, reason: created.raw);
    final projectId = created.body!['id'] as String;
    final users = await director.send('GET', '/api/company/users');
    final techId = (users.body!['users'] as List).cast<Map<String, dynamic>>()
        .firstWhere((user) => user['login'] == 'a.tech')['id'];
    final bankId = (users.body!['users'] as List).cast<Map<String, dynamic>>()
        .firstWhere((user) => user['login'] == 'a.observer')['id'];
    expect((await director.send('POST', '/api/projects/$projectId/members', json: {
      'userId': techId,
      'role': 'tech',
    })).status, 201);
    expect((await director.send('POST', '/api/projects/$projectId/members', json: {
      'userId': bankId,
      'role': 'observer',
    })).status, 201);

    final firms = await director.send('GET', '/api/contractor-firms');
    final firmId = (firms.body!['firms'] as List).cast<Map<String, dynamic>>().first['id'] as String;
    final imported = await director.send('POST', '/api/projects/$projectId/budget/import', json: {
      'contractorFirmId': firmId,
      'csv': '03,Бетон,hard,use,600.00\n05,Отделка,soft,use,400.00',
    });
    expect(imported.status, 201, reason: imported.raw);
    final source = await director.send('POST', '/api/projects/$projectId/sources', json: {
      'name': 'Кредитная линия',
      'kind': 'loan',
      'amount': '1000.00',
    });
    expect(source.status, 201, reason: source.raw);
    final template = await director.send('POST', '/api/budget-templates', json: {
      'projectId': projectId,
      'name': 'Типовой дом',
    });
    expect(template.status, 201, reason: template.raw);

    final loan = await director.send('GET', '/api/projects/$projectId/loan');
    expect(loan.status, 200, reason: loan.raw);
    final uses = (loan.body!['lines'] as List).cast<Map<String, dynamic>>()
        .where((line) => line['budget_side'] == 'use')
        .toList();
    expect(uses, hasLength(2));
    final checklist = (loan.body!['checklist'] as List).cast<Map<String, dynamic>>();
    expect(checklist.map((item) => item['code']), containsAll(['act', 'invoice', 'waiver']));

    final draw = await director.send('POST', '/api/draws', json: {
      'projectId': projectId,
      'name': 'Транш 1',
    });
    expect(draw.status, 201, reason: draw.raw);
    final drawId = draw.body!['id'] as String;
    final card = await director.send('GET', '/api/draws/$drawId');
    final requirements = (card.body!['requirements'] as List).cast<Map<String, dynamic>>();
    final patched = await director.send('PATCH', '/api/draws/$drawId', json: {
      'signedName': 'Директор Навои',
      'finalDraw': false,
      'lines': [
        {
          'budgetItemId': uses[0]['id'],
          'requested': '600.00',
          'adjustment': '0.00',
          'retainageWithheld': '100.00',
          'retainageReleased': '0.00',
          'storedMaterials': '50.00',
        },
        {
          'budgetItemId': uses[1]['id'],
          'requested': '400.00',
          'retainageWithheld': '0.00',
          'retainageReleased': '0.00',
          'storedMaterials': '0.00',
        },
      ],
      'sources': [
        {'sourceId': source.body!['id'], 'amount': '900.00'},
      ],
      'requirements': [
        for (final item in requirements)
          if (item['required'] == true)
            {'itemId': item['item_id'], 'status': 'attached', 'note': 'пакет'},
      ],
    });
    expect(patched.status, 200, reason: patched.raw);
    final listed = await director.send('GET', '/api/projects/$projectId/loan');
    final summary = (listed.body!['draws'] as List).cast<Map<String, dynamic>>()
        .firstWhere((item) => item['id'] == drawId);
    expect(summary['requested'], '1000.00');

    final blocked = await director.send('POST', '/api/draws/$drawId/submit');
    expect(blocked.status, 200, reason: blocked.raw);
    expect(blocked.body!['status'], 'submitted');
    expect(blocked.body!['amount'], '900.00');

    final queue = await tech.send('GET', '/api/notices');
    expect(queue.status, 200, reason: queue.raw);
    expect(jsonEncode(queue.body), contains(drawId));

    final report = await tech.send('POST', '/api/projects/$projectId/inspections', json: {
      'requestId': drawId,
      'scheduledOn': '2026-10-20',
      'gateCode': '12',
      'note': 'Кран на площадке',
      'lines': [
        {'budgetItemId': uses[0]['id'], 'percent': '40.00', 'recommend': '400.00'},
        {'budgetItemId': uses[1]['id'], 'percent': '10.00', 'recommend': '200.00'},
      ],
    });
    expect(report.status, 201, reason: report.raw);

    final version = blocked.body!['version'] as int;
    final checked = await tech.send('POST', '/api/requests/$drawId/tech', json: {
      'version': version,
      'decision': 'approve',
      'reason': 'Объём подтверждён',
    }, idempotencyKey: 'built-tech-0001');
    expect(checked.status, 200, reason: checked.raw);

    final decided = await bank.send('POST', '/api/draws/$drawId/decide', json: {
      'lines': [
        {'budgetItemId': uses[0]['id'], 'approved': '500.00'},
        {'budgetItemId': uses[1]['id'], 'approved': '300.00'},
      ],
    });
    expect(decided.status, 200, reason: decided.raw);
    expect(decided.body!['confirmed'], '800.00');

    final approved = await bank.send('POST', '/api/requests/$drawId/approve', json: {
      'version': decided.body!['version'],
    }, idempotencyKey: 'built-bank-0001');
    expect(approved.status, 200, reason: approved.raw);
    expect(approved.body!['amount'], '800.00');

    final comment = await bank.send('POST', '/api/draws/$drawId/comments', json: {
      'body': 'Урезали отделку',
    });
    expect(comment.status, 201, reason: comment.raw);
    final payable = await director.send('POST', '/api/draws/$drawId/payables', json: {
      'budgetItemId': uses[0]['id'],
      'firmId': firmId,
      'number': 'СЧ-1',
      'amount': '500.00',
      'waiver': 'signed',
    });
    expect(payable.status, 201, reason: payable.raw);
    final compliance = await director.send('PATCH', '/api/contractor-firms/$firmId', json: {
      'insuranceUntil': '2026-11-01',
      'licenseUntil': '2026-12-01',
    });
    expect(compliance.status, 200, reason: compliance.raw);

    final pack = await bank.send('GET', '/api/draws/$drawId/package');
    expect(pack.status, 200, reason: pack.raw);
    expect(pack.raw, contains('Транш 1'));
    expect(pack.raw, contains('800.00'));

    expect((await other.send('GET', '/api/projects/$projectId/loan')).status, 404);
    final project = await director.send('GET', '/api/projects/$projectId');
    expect(project.body!['reserved'], '800.00');
    expect(project.body!['available'], '200.00');
    final usesAfter = (loan.body!['lines'] as List).cast<Map<String, dynamic>>();
    final firstLine = usesAfter.first['id'] as String;
    final budget = await director.send('GET', '/api/projects/$projectId/budget');
    final matched = (budget.body!['items'] as List).cast<Map<String, dynamic>>()
        .firstWhere((item) => item['id'] == firstLine);
    expect(matched['reserved'], anyOf('500.00', '300.00'));
    final grid = await director.send('GET', '/api/projects/$projectId/loan');
    final beton = (grid.body!['lines'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((line) => line['title'] == 'Бетон');
    expect(beton['original'], '600.00');
    expect(beton['revised'], '600.00');
    expect(beton['remaining'], '100.00');
    expect(beton['percent_complete'], '40.00');
  });

  test('an unbalanced draw is rejected and a second draw cannot pass the line limit', () async {
    final director = Client(handler);
    expect((await director.login('a.director', password)).status, 200);
    final created = await director.send('POST', '/api/projects', json: {
      'name': 'Лимит Тест',
      'address': 'Ташкент, лимит',
    });
    final projectId = created.body!['id'] as String;
    final firms = await director.send('GET', '/api/contractor-firms');
    final firmId = (firms.body!['firms'] as List).cast<Map<String, dynamic>>().first['id'] as String;
    expect((await director.send('POST', '/api/projects/$projectId/budget/import', json: {
      'contractorFirmId': firmId,
      'csv': '01,Фундамент,hard,use,100.00',
    })).status, 201);
    final source = await director.send('POST', '/api/projects/$projectId/sources', json: {
      'name': 'Кредит',
      'kind': 'loan',
      'amount': '100.00',
    });
    final loan = await director.send('GET', '/api/projects/$projectId/loan');
    final itemId = (loan.body!['lines'] as List).cast<Map<String, dynamic>>().first['id'] as String;
    final checklist = (loan.body!['checklist'] as List).cast<Map<String, dynamic>>();

    Future<String> draft(String name) async {
      final draw = await director.send('POST', '/api/draws', json: {
        'projectId': projectId,
        'name': name,
      });
      expect(draw.status, 201, reason: draw.raw);
      return draw.body!['id'] as String;
    }

    Future<void> fill(String id, String requested, String sourceAmount) async {
      final card = await director.send('GET', '/api/draws/$id');
      final requirements = (card.body!['requirements'] as List).cast<Map<String, dynamic>>();
      final patched = await director.send('PATCH', '/api/draws/$id', json: {
        'signedName': 'Директор',
        'lines': [
          {
            'budgetItemId': itemId,
            'requested': requested,
            'retainageWithheld': '0.00',
            'retainageReleased': '0.00',
            'storedMaterials': '0.00',
          },
        ],
        'sources': [
          {'sourceId': source.body!['id'], 'amount': sourceAmount},
        ],
        'requirements': [
          for (final item in requirements)
            if (item['required'] == true) {'itemId': item['item_id'], 'status': 'attached'},
        ],
      });
      expect(patched.status, 200, reason: patched.raw);
    }

    final unbalanced = await draft('Кривой');
    await fill(unbalanced, '40.00', '10.00');
    final rejected = await director.send('POST', '/api/draws/$unbalanced/submit');
    expect(rejected.status, 409, reason: rejected.raw);
    expect(rejected.body!['message'], 'Сумма источников не совпадает с суммой транша.');
    expect(checklist, isNotEmpty);

    final first = await draft('Первый');
    await fill(first, '80.00', '80.00');
    expect((await director.send('POST', '/api/draws/$first/submit')).status, 200);

    final second = await draft('Второй');
    await fill(second, '30.00', '30.00');
    final over = await director.send('POST', '/api/draws/$second/submit');
    expect(over.status, 409, reason: over.raw);
    expect(over.body!['message'], 'Сумма больше, чем можно запросить.');
  });

  test('a new project without money sources says who should add them', () async {
    final director = Client(handler);
    final contractor = Client(handler);
    expect((await director.login('a.director', password)).status, 200);
    expect((await contractor.login('a.contractor', password)).status, 200);
    final created = await director.send('POST', '/api/projects', json: {
      'name': 'Без источников',
      'address': 'Ташкент, новый',
    });
    expect(created.status, 201, reason: created.raw);
    final projectId = created.body!['id'] as String;
    final firms = await director.send('GET', '/api/contractor-firms');
    final firmId = (firms.body!['firms'] as List).cast<Map<String, dynamic>>().first['id'] as String;
    expect((await director.send('POST', '/api/projects/$projectId/budget/import', json: {
      'contractorFirmId': firmId,
      'csv': '01,Фундамент,hard,use,100.00',
    })).status, 201);
    final users = await director.send('GET', '/api/company/users');
    final contractorId = (users.body!['users'] as List).cast<Map<String, dynamic>>()
        .firstWhere((user) => user['login'] == 'a.contractor')['id'];
    expect((await director.send('POST', '/api/projects/$projectId/members', json: {
      'userId': contractorId,
      'role': 'contractor',
      'contractorFirmId': firmId,
    })).status, 201);
    final loan = await director.send('GET', '/api/projects/$projectId/loan');
    expect(loan.body!['sources'], isEmpty);
    final itemId = (loan.body!['lines'] as List).cast<Map<String, dynamic>>().first['id'] as String;

    final directorTry = await director.send('POST', '/api/draws', json: {
      'projectId': projectId,
      'name': 'Черновик застройщика',
    });
    expect(directorTry.status, 201, reason: directorTry.raw);
    final directorId = directorTry.body!['id'] as String;
    final directorCard = await director.send('GET', '/api/draws/$directorId');
    final requirements = (directorCard.body!['requirements'] as List).cast<Map<String, dynamic>>();
    expect((await director.send('PATCH', '/api/draws/$directorId', json: {
      'signedName': 'Директор',
      'lines': [
        {
          'budgetItemId': itemId,
          'requested': '40.00',
          'retainageWithheld': '0.00',
          'retainageReleased': '0.00',
          'storedMaterials': '0.00',
        },
      ],
      'requirements': [
        for (final item in requirements)
          if (item['required'] == true) {'itemId': item['item_id'], 'status': 'attached'},
      ],
    })).status, 200);
    final directorRejected = await director.send('POST', '/api/draws/$directorId/submit');
    expect(directorRejected.status, 409, reason: directorRejected.raw);
    expect(
      directorRejected.body!['message'],
      'На объекте ещё нет источников денег. Добавьте источник в бюджете объекта, затем отправьте транш.',
    );

    final contractorTry = await contractor.send('POST', '/api/draws', json: {
      'projectId': projectId,
      'name': 'Черновик подрядчика',
    });
    expect(contractorTry.status, 201, reason: contractorTry.raw);
    final contractorDraw = contractorTry.body!['id'] as String;
    final contractorCard = await contractor.send('GET', '/api/draws/$contractorDraw');
    final contractorRequirements = (contractorCard.body!['requirements'] as List).cast<Map<String, dynamic>>();
    expect((await contractor.send('PATCH', '/api/draws/$contractorDraw', json: {
      'signedName': 'Подрядчик',
      'lines': [
        {
          'budgetItemId': itemId,
          'requested': '20.00',
          'retainageWithheld': '0.00',
          'retainageReleased': '0.00',
          'storedMaterials': '0.00',
        },
      ],
      'requirements': [
        for (final item in contractorRequirements)
          if (item['required'] == true) {'itemId': item['item_id'], 'status': 'attached'},
      ],
    })).status, 200);
    final contractorRejected = await contractor.send('POST', '/api/draws/$contractorDraw/submit');
    expect(contractorRejected.status, 409, reason: contractorRejected.raw);
    expect(
      contractorRejected.body!['message'],
      'Источники денег задаёт застройщик в бюджете объекта. Попросите добавить источник, затем отправьте транш.',
    );
  });
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
    return send('POST', '/api/auth/login', json: {
      'login': login,
      'password': password,
    });
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
    _takeCookies(response.headersAll['set-cookie'] ?? const []);
    final raw = await response.readAsString();
    Map<String, dynamic>? body;
    if (raw.isNotEmpty && raw.startsWith('{')) {
      body = (jsonDecode(raw) as Map).map((key, value) => MapEntry(key.toString(), value));
      if (body['csrfToken'] is String) csrf = body['csrfToken'] as String;
    }
    return Call(response.statusCode, body, raw);
  }

  void _takeCookies(List<String> lines) {
    for (final line in lines) {
      final first = line.split(';').first;
      final separator = first.indexOf('=');
      if (separator <= 0) continue;
      cookies[first.substring(0, separator).trim()] = first.substring(separator + 1).trim();
      if (first.startsWith('ibuild_csrf=')) csrf = first.substring(separator + 1).trim();
    }
  }
}

class Call {
  Call(this.status, this.body, this.raw);
  final int status;
  final Map<String, dynamic>? body;
  final String raw;
}
