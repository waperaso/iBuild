import 'dart:convert';
import 'dart:io';

import 'package:ibuild_server/ibuild_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const password = 'Pilot-2026-demo';
const testDatabaseUrl =
    'postgres://ibuild:ibuild@localhost:5433/ibuild_test?sslmode=disable';

DateTime tashkent(int month, int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, month, day, hour, minute).subtract(const Duration(hours: 5));

void main() {
  group('bank working time', () {
    test('a weekend does not count', () {
      // Friday 17:00 to Monday 10:00 in Tashkent: one hour on each side.
      expect(bankWorkingMinutes(tashkent(10, 30, 17), tashkent(11, 2, 10), {}), 120);
    });

    test('a holiday does not count', () {
      expect(bankWorkingMinutes(tashkent(10, 30, 17), tashkent(11, 3, 10), {'2026-11-02'}), 120);
    });

    test('before and after hours do not count', () {
      expect(bankWorkingMinutes(tashkent(10, 28, 6), tashkent(10, 28, 22), {}), 540);
      expect(bankWorkingMinutes(tashkent(10, 28, 19), tashkent(10, 29, 8), {}), 0);
    });

    test('time at the developer is left out of the stage', () {
      final start = tashkent(10, 26, 9);
      final counted = [
        BankInterval(start, tashkent(10, 26, 13)),
        BankInterval(tashkent(10, 27, 9), tashkent(10, 27, 11)),
      ];
      final minutes = bankStageMinutes(counted, start, tashkent(10, 28, 9), {});
      expect(minutes, 360);
      final elapsed = bankElapsedOf(minutes);
      expect([elapsed.days, elapsed.hours], [0, 6]);
      expect(bankElapsedOf(540 + 130).days, 1);
      expect(bankElapsedOf(540 + 130).hours, 2);
    });
  });

  group('a real draw becomes a bank tranche', () {
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

    Future<Call> dev(Client client, String method, String path,
        [Map<String, dynamic>? json, String? key]) {
      return client.send(method, path,
          json: json, csrf: true, headers: key == null ? const {} : {'idempotency-key': key});
    }

    Future<List<List<Object?>>> rows(String sql, [Map<String, Object?> params = const {}]) async {
      final result = await db.owner.execute(Sql.named(sql), parameters: params);
      return [for (final row in result) row.toList()];
    }

    test('an applied migration that was edited stops the start', () async {
      final copy = await Directory.systemTemp.createTemp('ibuild-migrations');
      try {
        for (final file in Directory('migrations').listSync().whereType<File>()) {
          file.copySync('${copy.path}/${file.uri.pathSegments.last}');
        }
        await db.migrate(copy.path);
        final edited = File('${copy.path}/023_bank_colleagues.sql');
        edited.writeAsStringSync('${edited.readAsStringSync()}\n-- changed after the fact\n');
        await expectLater(db.migrate(copy.path), throwsA(isA<StateError>()));
      } finally {
        await copy.delete(recursive: true);
      }
    });

    test('the whole way: submit, rules, inspection, decision, write-back, journal', () async {
      final director = await signIn('a.director');
      final tech = await signIn('a.tech');
      final specialist = await signIn('a.observer');

      final created = await dev(director, 'POST', '/api/projects',
          {'name': 'Кредит Тест', 'address': 'Ташкент, тест'});
      expect(created.status, 201);
      final projectId = created.body!['id'] as String;
      final users = (await dev(director, 'GET', '/api/company/users')).body!['users'] as List;
      String userId(String login) => users
          .cast<Map<String, dynamic>>()
          .firstWhere((u) => u['login'] == login)['id'] as String;
      await dev(director, 'POST', '/api/projects/$projectId/members',
          {'userId': userId('a.tech'), 'role': 'tech'});
      await dev(director, 'POST', '/api/projects/$projectId/members',
          {'userId': userId('a.observer'), 'role': 'observer'});

      final firms = (await dev(director, 'GET', '/api/contractor-firms')).body!['firms'] as List;
      final firmId = (firms.first as Map)['id'] as String;
      expect(
          (await dev(director, 'PATCH', '/api/contractor-firms/$firmId',
                  {'insuranceUntil': '2026-01-01', 'licenseUntil': '2026-01-01'}))
              .status,
          200);
      expect(
          (await dev(director, 'POST', '/api/projects/$projectId/budget/import', {
            'contractorFirmId': firmId,
            'csv': '03,Бетон,hard,use,600.00\n05,Отделка,soft,use,400.00',
          }))
              .status,
          201);
      final source = await dev(director, 'POST', '/api/projects/$projectId/sources',
          {'name': 'Кредитная линия', 'kind': 'loan', 'amount': '1000.00'});
      final loan = await dev(director, 'GET', '/api/projects/$projectId/loan');
      final uses = (loan.body!['lines'] as List)
          .cast<Map<String, dynamic>>()
          .where((line) => line['budget_side'] == 'use')
          .toList();
      final concrete = uses.firstWhere((line) => line['title'] == 'Бетон');
      final finish = uses.firstWhere((line) => line['title'] == 'Отделка');

      final bankRows = await rows('SELECT bank_id::text FROM project_facilities LIMIT 1');
      await rows('''
        INSERT INTO project_facilities (project_id, bank_id, developer_name, credit_limit, issued_amount)
        VALUES (@p::uuid, @b::uuid, 'Тест', 5000.00, 0)
      ''', {'p': projectId, 'b': bankRows.first.first});

      final draw = await dev(director, 'POST', '/api/draws', {'projectId': projectId, 'name': 'Транш 1'});
      final drawId = draw.body!['id'] as String;
      final requirements =
          ((await dev(director, 'GET', '/api/draws/$drawId')).body!['requirements'] as List)
              .cast<Map<String, dynamic>>();
      expect(
          (await dev(director, 'PATCH', '/api/draws/$drawId', {
            'signedName': 'Директор',
            'lines': [
              {
                'budgetItemId': concrete['id'],
                'requested': '600.00',
                'retainageWithheld': '100.00',
                'retainageReleased': '0.00',
                'storedMaterials': '50.00',
              },
              {
                'budgetItemId': finish['id'],
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
                if (item['required'] == true) {'itemId': item['item_id'], 'status': 'attached'},
            ],
          }))
              .status,
          200);
      final payable = await dev(director, 'POST', '/api/draws/$drawId/payables', {
        'budgetItemId': concrete['id'],
        'firmId': firmId,
        'number': 'СЧ-7',
        'amount': '500.00',
        'waiver': 'missing',
      });
      expect(payable.status, 201);

      // 1. Submit: the tranche appears at the bank and waits for the expert.
      expect((await dev(director, 'POST', '/api/draws/$drawId/submit')).status, 200);
      final tranche = await rows(
        'SELECT id::text, stage, signal, problems_label FROM bank_tranches WHERE request_id = @r::uuid',
        {'r': drawId},
      );
      expect(tranche, hasLength(1));
      final id = tranche.first[0]! as String;
      expect(tranche.first[1], 'inspection');
      expect(
        (await rows(
          "SELECT status FROM bank_approval_steps WHERE tranche_id = @t::uuid AND code = 'expert'",
          {'t': id},
        ))
            .first
            .first,
        'pending',
      );
      expect(tranche.first[3], isNot(''));
      expect(
          (await rows(
                  'SELECT count(*) FROM bank_tranche_clock WHERE tranche_id = @t::uuid AND ended_at IS NULL',
                  {'t': id}))
              .first
              .first,
          1);
      // A repeated sync does not create a second tranche.
      await bankSyncRequest(db, drawId);
      expect(
          (await rows('SELECT count(*) FROM bank_tranches WHERE request_id = @r::uuid', {'r': drawId}))
              .first
              .first,
          1);

      // 2. The inspection of the expert: the tranche goes to the specialist, the rules speak.
      final report = await dev(tech, 'POST', '/api/projects/$projectId/inspections', {
        'requestId': drawId,
        'scheduledOn': '2026-10-20',
        'gateCode': '12',
        'note': 'ok',
        'lines': [
          {'budgetItemId': concrete['id'], 'percent': '40.00', 'recommend': '400.00'},
          {'budgetItemId': finish['id'], 'percent': '10.00', 'recommend': '200.00'},
        ],
      });
      expect(report.status, 201);
      expect(
          (await rows('SELECT stage FROM bank_tranches WHERE id = @t::uuid', {'t': id})).first.first,
          'specialist');
      expect(
        (await rows(
          "SELECT status FROM bank_approval_steps WHERE tranche_id = @t::uuid AND code = 'expert'",
          {'t': id},
        ))
            .first
            .first,
        'done',
      );
      final checks = {
        for (final row in await rows(
            'SELECT code, level, passed FROM bank_checks WHERE tranche_id = @t::uuid', {'t': id}))
          row[0]! as String: row,
      };
      expect(checks['certificate']![1], 'block');
      expect(checks['certificate']![2], false);
      expect(checks['above_confirmed']![1], 'warning');
      expect(checks['subcontractor']![1], 'warning');
      expect(checks['payable_waiver']![1], 'warning');
      expect(checks['passed_inspection']![2], true);
      final lines = {
        for (final row in await rows('''
          SELECT title, to_char(requested, 'FM990.00'), to_char(confirmed, 'FM990.00'),
                 to_char(to_issue, 'FM990.00')
          FROM bank_tranche_lines WHERE tranche_id = @t::uuid
        ''', {'t': id}))
          row[0]! as String: row,
      };
      expect(lines['Бетон']![1], '500.00');
      expect(lines['Бетон']![2], '400.00');
      expect(lines['Бетон']![3], '0.00'); // blocked by the missing certificate
      expect(lines['Отделка']![2], '200.00');
      expect(lines['Отделка']![3], '200.00');

      // 3. The bank decides: the developer gets the reasons on the draw.
      final decision = await dev(specialist, 'POST', '/api/bank/tranches/$id/decision',
          {'kind': 'partial', 'note': 'Доработайте материалы'}, 'bridge-key-0001');
      expect(decision.status, 200, reason: jsonEncode(decision.body));
      final comments = await rows(
          'SELECT body FROM draw_comments WHERE request_id = @r::uuid ORDER BY created_at',
          {'r': drawId});
      expect(comments.map((c) => c.first.toString()).join('|'), contains('Банк согласовал'));
      expect(comments.length, greaterThanOrEqualTo(2));

      // 4. Every step left a trace: who, what, when.
      final actions = (await rows(
              'SELECT action FROM bank_audit_events WHERE tranche_id = @t::uuid ORDER BY created_at, id',
              {'t': id}))
          .map((r) => r.first)
          .toList();
      expect(actions, containsAllInOrder(['tranche_created', 'inspection_reported', 'decision']));

      // 5. The same tranche is readable with the card of the bank.
      final card = await specialist.send('GET', '/api/bank/tranches/$id');
      expect(card.status, 200);
    });

    test('backfill closes only expert steps that are already past inspection', () async {
      final banks = await rows('''
        SELECT c.id::text, (
          SELECT v.id::text FROM bank_rule_versions v
          WHERE v.bank_id = c.id ORDER BY v.version DESC LIMIT 1
        )
        FROM companies c
        JOIN bank_profiles p ON p.company_id = c.id
        ORDER BY c.name
      ''');
      expect(banks.length, greaterThanOrEqualTo(2));
      final bankA = banks[0][0]! as String;
      final bankB = banks[1][0]! as String;
      var rulesA = banks[0][1] as String?;
      var rulesB = banks[1][1] as String?;
      Future<String> rulesFor(String bank, String? existing) async {
        if (existing != null) return existing;
        final created = await rows('''
          INSERT INTO bank_rule_versions (bank_id, version, effective_from, snapshot)
          VALUES (@bank::uuid, 1, DATE '2026-11-01', '{}'::jsonb)
          RETURNING id::text
        ''', {'bank': bank});
        return created.first.first! as String;
      }
      rulesA = await rulesFor(bankA, rulesA);
      rulesB = await rulesFor(bankB, rulesB);
      final company = (await rows("SELECT company_id::text FROM projects WHERE name = 'ЖК Навои'")).first.first! as String;
      final director = (await rows("SELECT id::text FROM users WHERE login = 'a.director'")).first.first! as String;
      final item = (await rows('''
        SELECT id::text FROM budget_items
        WHERE project_id = (SELECT id FROM projects WHERE name = 'ЖК Навои')
        LIMIT 1
      ''')).first.first! as String;

      Future<String> project(String name) async {
        final created = await rows('''
          INSERT INTO projects (company_id, name, address)
          VALUES (@company::uuid, @name, 'Ташкент')
          RETURNING id::text
        ''', {'company': company, 'name': name});
        return created.first.first! as String;
      }

      Future<String> draw(String projectId, String status, String payment) async {
        final created = await rows('''
          INSERT INTO funding_requests (
            project_id, budget_item_id, contractor_user_id, author_user_id,
            amount, description, status, draw_name, requested_amount, payment_number, paid_on
          ) VALUES (
            @project::uuid, @item::uuid, @user::uuid, @user::uuid,
            100000.00, '', @status, @name, 100000.00, @payment, DATE '2026-11-06'
          )
          RETURNING id::text
        ''', {
          'project': projectId,
          'item': item,
          'user': director,
          'status': status,
          'name': 'Backfill $status $projectId',
          'payment': payment,
        });
        return created.first.first! as String;
      }

      Future<String> tranche({
        required String projectId,
        required String bankId,
        required String rulesId,
        required int number,
        required String stage,
        required String entered,
        String? requestId,
        required String issue,
      }) async {
        final created = await rows('''
          INSERT INTO bank_tranches (
            project_id, bank_id, rules_version_id, tranche_no, stage, stage_label,
            sla_days, requested_amount, confirmed_amount, issue_amount,
            stage_entered_at, request_id
          ) VALUES (
            @project::uuid, @bank::uuid, @rules::uuid, @no, @stage, @stage,
            1, @issue::numeric, @issue::numeric, @issue::numeric,
            @entered::timestamptz, @request::uuid
          )
          RETURNING id::text
        ''', {
          'project': projectId,
          'bank': bankId,
          'rules': rulesId,
          'no': number,
          'stage': stage,
          'issue': issue,
          'entered': entered,
          'request': requestId,
        });
        return created.first.first! as String;
      }

      Future<void> expertStep(String trancheId, String status, String label, String? decided) async {
        await rows('''
          INSERT INTO bank_approval_steps (
            tranche_id, code, position, status, required_approvals, actor_label, decided_at
          ) VALUES (
            @tranche::uuid, 'expert', 1, @status, 1, @label, @decided::timestamptz
          )
        ''', {
          'tranche': trancheId,
          'status': status,
          'label': label,
          'decided': decided,
        });
      }

      final projectA = await project('Backfill A');
      final projectB = await project('Backfill B');
      final paidRequest = await draw(projectA, 'paid', 'PP-KEEP');
      final waitingRequest = await draw(projectA, 'submitted', '');
      final paid = await tranche(
        projectId: projectA,
        bankId: bankA,
        rulesId: rulesA,
        number: 9101,
        stage: 'payout',
        entered: '2026-11-06 18:00:00+00',
        requestId: paidRequest,
        issue: '100000.00',
      );
      await rows('''
        INSERT INTO bank_tranche_clock (tranche_id, stage, started_at, ended_at, paused)
        VALUES (
          @tranche::uuid, 'inspection',
          TIMESTAMPTZ '2026-11-06 10:00:00+00',
          TIMESTAMPTZ '2026-11-06 12:00:00+00',
          false
        )
      ''', {'tranche': paid});
      await expertStep(paid, 'pending', '', null);
      await rows('''
        INSERT INTO bank_approval_steps (tranche_id, code, position, status, required_approvals, actor_label)
        VALUES
          (@tranche::uuid, 'specialist', 2, 'done', 1, 'QA Specialist'),
          (@tranche::uuid, 'sign', 5, 'pending', 1, '')
      ''', {'tranche': paid});
      await rows('''
        INSERT INTO bank_decisions (
          tranche_id, kind, round, issue_amount, returned_amount, note, user_id, actor_label
        ) VALUES (
          @tranche::uuid, 'partial', 1, 100000.00, 0, 'KEEP-DECISION', @user::uuid, 'QA Specialist'
        )
      ''', {'tranche': paid, 'user': director});

      final waiting = await tranche(
        projectId: projectA,
        bankId: bankA,
        rulesId: rulesA,
        number: 9102,
        stage: 'inspection',
        entered: '2026-11-06 09:00:00+00',
        requestId: waitingRequest,
        issue: '50.00',
      );
      await expertStep(waiting, 'pending', '', null);

      final named = await tranche(
        projectId: projectA,
        bankId: bankA,
        rulesId: rulesA,
        number: 9103,
        stage: 'specialist',
        entered: '2026-11-05 08:00:00+00',
        issue: '70.00',
      );
      await expertStep(named, 'pending', 'Эксперт Иванов', null);

      final already = await tranche(
        projectId: projectA,
        bankId: bankA,
        rulesId: rulesA,
        number: 9104,
        stage: 'specialist',
        entered: '2026-11-04 08:00:00+00',
        issue: '80.00',
      );
      await expertStep(already, 'done', 'А. Каримов', '2026-10-23 12:30:00+00');

      final otherPaid = await tranche(
        projectId: projectB,
        bankId: bankB,
        rulesId: rulesB,
        number: 9101,
        stage: 'payout',
        entered: '2026-11-02 08:00:00+00',
        issue: '222.22',
      );
      await expertStep(otherPaid, 'pending', '', null);
      final otherWaiting = await tranche(
        projectId: projectB,
        bankId: bankB,
        rulesId: rulesB,
        number: 9102,
        stage: 'inspection',
        entered: '2026-11-02 09:00:00+00',
        issue: '15.00',
      );
      await expertStep(otherWaiting, 'pending', '', null);

      final closed = await rows('SELECT close_stuck_expert_steps()');
      expect(closed.first.first, 3);

      Future<List<Object?>> step(String trancheId) async {
        final found = await rows('''
          SELECT status, actor_label, decided_at
          FROM bank_approval_steps
          WHERE tranche_id = @tranche::uuid AND code = 'expert'
        ''', {'tranche': trancheId});
        return found.single;
      }

      final paidStep = await step(paid);
      expect(paidStep[0], 'done');
      expect(paidStep[1], 'Осмотр зафиксирован');
      expect((paidStep[2]! as DateTime).toUtc(), DateTime.utc(2026, 11, 6, 12));
      expect((await step(waiting))[0], 'pending');
      final namedStep = await step(named);
      expect(namedStep[0], 'done');
      expect(namedStep[1], 'Эксперт Иванов');
      expect((namedStep[2]! as DateTime).toUtc(), DateTime.utc(2026, 11, 5, 8));
      final kept = await step(already);
      expect(kept[0], 'done');
      expect(kept[1], 'А. Каримов');
      expect((kept[2]! as DateTime).toUtc(), DateTime.utc(2026, 10, 23, 12, 30));
      expect((await step(otherPaid))[0], 'done');
      expect((await step(otherWaiting))[0], 'pending');

      expect(
        (await rows("SELECT status FROM bank_approval_steps WHERE tranche_id = @t::uuid AND code = 'sign'", {'t': paid})).single.first,
        'pending',
      );
      expect((await rows('SELECT stage, issue_amount::text FROM bank_tranches WHERE id = @t::uuid', {'t': paid})).single, ['payout', '100000.00']);
      expect((await rows('SELECT stage, issue_amount::text FROM bank_tranches WHERE id = @t::uuid', {'t': otherPaid})).single, ['payout', '222.22']);
      expect((await rows('SELECT stage, issue_amount::text FROM bank_tranches WHERE id = @t::uuid', {'t': waiting})).single, ['inspection', '50.00']);
      expect((await rows('SELECT payment_number, status FROM funding_requests WHERE id = @t::uuid', {'t': paidRequest})).single, ['PP-KEEP', 'paid']);
      expect((await rows('SELECT note, issue_amount::text FROM bank_decisions WHERE tranche_id = @t::uuid', {'t': paid})).single, ['KEEP-DECISION', '100000.00']);

      final events = await rows('''
        SELECT tranche_id::text, bank_id::text, action, detail ->> 'reason', detail ->> 'previous'
        FROM bank_audit_events
        WHERE action = 'expert_step_closed'
        ORDER BY tranche_id::text
      ''');
      expect(events.map((row) => row[0]).toSet(), {paid, named, otherPaid});
      expect(events.map((row) => row[2]).toSet(), {'expert_step_closed'});
      expect(events.every((row) => row[3] == 'backfill' && row[4] == 'pending'), isTrue);
      expect(events.where((row) => row[1] == bankA).length, 2);
      expect(events.where((row) => row[1] == bankB).length, 1);

      expect((await rows('SELECT close_stuck_expert_steps()')).first.first, 0);
      expect(
        (await rows("SELECT count(*) FROM bank_audit_events WHERE action = 'expert_step_closed'")).first.first,
        3,
      );
      expect((await step(paid))[1], 'Осмотр зафиксирован');
      expect((await step(waiting))[0], 'pending');
      expect((await rows('SELECT payment_number FROM funding_requests WHERE id = @t::uuid', {'t': paidRequest})).single.first, 'PP-KEEP');
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
