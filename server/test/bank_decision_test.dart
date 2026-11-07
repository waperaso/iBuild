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

  Future<void> reset() async {
    await db.truncateAll();
    await seedDemo(db, password);
    await ensureBankCabinet(db, password);
  }

  setUpAll(() async {
    await _ensureTestDatabase();
    lock = await Connection.openFromUrl(testDatabaseUrl);
    await lock.execute('SELECT pg_advisory_lock(424242)');
    db = await AppDatabase.open(testDatabaseUrl);
    await db.migrate('migrations');
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

  Future<Map<String, dynamic>> card(Client client) async {
    final queue = await client.send('GET', '/api/bank/queue?tab=all');
    final items = (queue.body!['items'] as List).cast<Map<String, dynamic>>();
    final navoi = items.firstWhere((item) => item['projectName'] == 'ЖК Навои');
    final call = await client.send('GET', '/api/bank/tranches/${navoi['id']}');
    expect(call.status, 200);
    return call.body!;
  }

  Map<String, dynamic> line(Map<String, dynamic> card, String title) =>
      (card['lines'] as List).cast<Map<String, dynamic>>().firstWhere((l) => l['title'] == title);

  Map<String, dynamic> openCheck(Map<String, dynamic> card, String code) =>
      ((card['checks'] as Map)['open'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((c) => c['code'] == code);

  const plateTitle = 'Фундаментная плита';
  const rebarTitle = 'Арматура A500C и бетон на площадке';
  var keyCounter = 0;
  String nextKey() => 'test-key-${++keyCounter}-aaaaaaaa';

  Future<Call> post(Client client, String path, Map<String, dynamic> json, {String? key}) {
    return client.send(
      'POST',
      path,
      json: json,
      csrf: true,
      headers: key == null ? const {} : {'idempotency-key': key},
    );
  }

  Future<Call> decide(Client client, String id, String kind, {String note = '', String? key}) {
    return post(client, '/api/bank/tranches/$id/decision', {'kind': kind, 'note': note}, key: key ?? nextKey());
  }

  Future<Call> vote(Client client, String id, String vote, {String comment = ''}) {
    return post(client, '/api/bank/tranches/$id/approval', {'vote': vote, 'comment': comment});
  }

  Future<Map<String, dynamic>> approval(Client client, String id) async {
    final call = await client.send('GET', '/api/bank/tranches/$id/approval');
    expect(call.status, 200);
    return call.body!;
  }

  Map<String, dynamic> step(Map<String, dynamic> approval, String code) =>
      (approval['steps'] as List).cast<Map<String, dynamic>>().firstWhere((s) => s['code'] == code);

  group('evidence, choice, requests and waivers', () {
    late Client specialist;
    late String id;

    setUpAll(() async {
      await reset();
      specialist = await signIn('a.observer');
      id = (await card(specialist))['id'] as String;
    });

    test('the card carries the evidence of the expert for a line', () async {
      final current = await card(specialist);
      final plate = line(current, plateTitle);
      final expert = plate['expert'] as Map<String, dynamic>;
      expect(expert['name'], 'А. Каримов');
      expect(expert['signedOn'], '23.10.2026');
      expect(expert['riskFlag'], true);
      expect(expert['previousPercent'], '26');
      expect(expert['recommended'], '867900000.00');
      final formula = plate['formula'] as Map<String, dynamic>;
      expect(formula['gross'], '1488000000.00');
      expect(formula['issuedBefore'], '620100000.00');
      expect((plate['photos'] as List).length, 3);
      expect(((plate['payments'] as List).single as Map)['amount'], '620100000.00');
      final rebar = line(current, rebarTitle);
      expect(rebar['blocked'], true);
      expect(((rebar['documents'] as List).first as Map)['state'], 'missing');
      expect((current['permissions'] as Map)['canDecide'], true);
    });

    test('requested above confirmed is refused, withhold is counted and undone', () async {
      final plate = line(await card(specialist), plateTitle);
      final path = '/api/bank/tranches/$id/lines/${plate['id']}/choice';
      final denied = await post(specialist, path, {'choice': 'requested'});
      expect(denied.status, 409);
      expect(denied.body!['error'], 'above_confirmed');
      expect((await post(specialist, path, {'choice': 'nonsense'})).status, 400);

      final withheld = await post(specialist, path, {'choice': 'withhold'});
      expect(withheld.status, 200);
      final after = withheld.body!['card'] as Map<String, dynamic>;
      expect(line(after, plateTitle)['toIssue'], '0.00');
      expect((after['totals'] as Map)['issue'], '856000000.00');

      final back = await post(specialist, path, {'choice': 'confirmed'});
      expect(((back.body!['card'] as Map)['totals'] as Map)['issue'], '1723900000.00');
    });

    test('a blocked line cannot be paid until the check is accepted', () async {
      final rebar = line(await card(specialist), rebarTitle);
      final denied = await post(
        specialist,
        '/api/bank/tranches/$id/lines/${rebar['id']}/choice',
        {'choice': 'confirmed'},
      );
      expect(denied.status, 409);
      expect(denied.body!['error'], 'blocked');
    });

    test('requests are written to the check, other checks cannot be requested', () async {
      final current = await card(specialist);
      final certificate = openCheck(current, 'certificate');
      final forecast = openCheck(current, 'forecast');
      final subcontractor = openCheck(current, 'subcontractor');
      expect(certificate['actions'], ['request_document', 'waive']);
      expect(forecast['actions'], ['request_schedule']);

      final sent = await post(specialist, '/api/bank/tranches/$id/checks/${certificate['id']}/request', {});
      expect(sent.status, 200);
      final checked = openCheck(sent.body!['card'] as Map<String, dynamic>, 'certificate');
      expect((checked['requested'] as Map)['kind'], 'document');
      final schedule = await post(specialist, '/api/bank/tranches/$id/checks/${forecast['id']}/request', {});
      expect(((openCheck(schedule.body!['card'] as Map<String, dynamic>, 'forecast'))['requested'] as Map)['kind'], 'schedule');
      final nothing = await post(specialist, '/api/bank/tranches/$id/checks/${subcontractor['id']}/request', {});
      expect(nothing.status, 409);
    });

    test('only the specialist changes anything and the token is required', () async {
      final current = await card(specialist);
      final plate = line(current, plateTitle);
      final head = await signIn('a.head1');
      final path = '/api/bank/tranches/$id/lines/${plate['id']}/choice';
      expect((await post(head, path, {'choice': 'withhold'})).status, 403);
      final noToken = await specialist.send('POST', path, json: {'choice': 'withhold'});
      expect(noToken.status, 403);
      final other = await signIn('b.observer');
      expect((await post(other, path, {'choice': 'withhold'})).status, 404);
    });

    test('a waiver needs a reason and a comment, stays in the card and cannot be repeated', () async {
      final current = await card(specialist);
      final above = openCheck(current, 'above_confirmed');
      final path = '/api/bank/tranches/$id/checks/${above['id']}/waive';
      expect((await post(specialist, path, {'reason': 'other', 'comment': '  '})).status, 400);
      expect((await post(specialist, path, {'reason': 'bad', 'comment': 'x'})).status, 400);
      final ok = await post(specialist, path, {'reason': 'fixed_elsewhere', 'comment': 'Объём учтён в другой статье'});
      expect(ok.status, 200);
      final after = ok.body!['card'] as Map<String, dynamic>;
      final waived = ((after['checks'] as Map)['open'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((c) => c['code'] == 'above_confirmed');
      expect((waived['waiver'] as Map)['by'], 'Д. Рахимов');
      expect(waived['actions'], isEmpty);
      expect(after['waivedCount'], 1);
      expect((await post(specialist, path, {'reason': 'other', 'comment': 'ещё раз'})).status, 409);
      final forecast = openCheck(after, 'forecast');
      final denied = await post(
        specialist,
        '/api/bank/tranches/$id/checks/${forecast['id']}/waive',
        {'reason': 'other', 'comment': 'нельзя'},
      );
      expect(denied.body!['error'], 'not_waivable');
    });
  });

  group('the decision', () {
    late Client specialist;
    late String id;

    setUp(() async {
      await reset();
      specialist = await signIn('a.observer');
      id = (await card(specialist))['id'] as String;
    });

    test('a partial decision moves the tranche to approval and is idempotent', () async {
      expect((await decide(specialist, id, 'partial', key: 'short')).status, 400);
      final noKey = await specialist.send(
        'POST',
        '/api/bank/tranches/$id/decision',
        json: {'kind': 'partial'},
        csrf: true,
      );
      expect(noKey.status, 400);

      final first = await decide(specialist, id, 'partial', key: 'same-key-0001');
      expect(first.status, 200);
      final moved = first.body!['card'] as Map<String, dynamic>;
      expect(moved['stage'], 'approval');
      final decision = moved['decision'] as Map<String, dynamic>;
      expect(decision['kind'], 'partial');
      expect(decision['issueAmount'], '1723900000.00');
      expect(decision['returnedAmount'], '536100000.00');
      final lines = (decision['returnLines'] as List).cast<Map<String, dynamic>>();
      expect(lines.map((l) => l['amount']).toList(), ['112100000.00', '64000000.00', '360000000.00']);
      expect(lines.last['reason'], 'Нет сертификата соответствия на арматуру (ГС п. 3.5)');
      expect((moved['permissions'] as Map)['canDecide'], false);

      final again = await decide(specialist, id, 'partial', key: 'same-key-0001');
      expect(again.status, 200);
      final count = await db.pool.execute(
        Sql.named('SELECT count(*) FROM bank_decisions WHERE tranche_id = @id::uuid'),
        parameters: {'id': id},
      );
      expect(count.first[0], 1);

      final other = await decide(specialist, id, 'return_all', note: 'иначе', key: 'same-key-0001');
      expect(other.status, 409);
      expect(other.body!['error'], 'key_reused');
      final fresh = await decide(specialist, id, 'partial', key: 'same-key-0002');
      expect(fresh.status, 409);
      expect(fresh.body!['error'], 'wrong_stage');
    });

    test('return all, suspend and resume need a reason and keep the tranche with the developer', () async {
      expect((await decide(specialist, id, 'return_all')).status, 400);
      final returned = await decide(specialist, id, 'return_all', note: 'Нужен новый комплект');
      expect(returned.status, 200);
      var current = returned.body!['card'] as Map<String, dynamic>;
      expect(current['waitingDeveloper'], true);
      expect((current['totals'] as Map)['issue'], '0.00');
      expect((current['permissions'] as Map)['canDecide'], false);
      expect((await decide(specialist, id, 'partial')).status, 409);

      final resumed = await post(specialist, '/api/bank/tranches/$id/resume', {});
      current = resumed.body!['card'] as Map<String, dynamic>;
      expect(current['waitingDeveloper'], false);
      expect(current['stage'], 'specialist');
      expect((await post(specialist, '/api/bank/tranches/$id/resume', {})).status, 409);

      expect((await decide(specialist, id, 'suspend')).status, 400);
      final paused = await decide(specialist, id, 'suspend', note: 'Нарушение целевого использования');
      current = paused.body!['card'] as Map<String, dynamic>;
      expect(current['fundingPaused'], true);
      expect(current['waitingDeveloper'], true);
      final back = await post(specialist, '/api/bank/tranches/$id/resume', {});
      current = back.body!['card'] as Map<String, dynamic>;
      expect(current['fundingPaused'], false);
    });

    test('a control measure plans an inspection and hands the tranche to the expert', () async {
      final measured = await decide(specialist, id, 'control_measure', note: 'Проверить захватку 3');
      expect(measured.status, 200);
      final current = measured.body!['card'] as Map<String, dynamic>;
      expect(current['stage'], 'inspection');
      final rows = await db.pool.execute(
        Sql.named('SELECT status, expert_label FROM bank_inspections WHERE tranche_id = @id::uuid'),
        parameters: {'id': id},
      );
      expect(rows.single[0], 'planned');
      expect(rows.single[1], 'А. Каримов, эксперт');
    });
  });

  group('approval route', () {
    late Client specialist;
    late String id;

    setUp(() async {
      await reset();
      specialist = await signIn('a.observer');
      id = (await card(specialist))['id'] as String;
    });

    test('no block means no committee, the signature and payment stay outside', () async {
      expect((await decide(specialist, id, 'partial')).status, 200);
      final head = await signIn('a.head1');
      final before = await approval(head, id);
      expect(step(before, 'expert')['status'], 'done');
      expect(step(before, 'specialist')['status'], 'done');
      expect(step(before, 'head')['status'], 'current');
      expect((step(before, 'head')['group'] as Map)['size'], 3);
      expect(step(before, 'committee')['status'], 'skipped');
      expect(step(before, 'committee')['reason'], 'below_threshold');
      expect(step(before, 'sign')['status'], 'waiting');
      expect(step(before, 'payment')['status'], 'waiting');
      expect((before['permissions'] as Map)['canAct'], true);

      final preparer = await approval(specialist, id);
      expect((preparer['permissions'] as Map)['blocker'], 'not_member');
      final denied = await vote(specialist, id, 'approve');
      expect(denied.status, 403);
      expect((await vote(await signIn('a.expert'), id, 'approve')).status, 403);
      expect((await vote(head, id, 'return')).status, 400);

      final done = await vote(head, id, 'approve');
      expect(done.status, 200);
      final after = done.body!['approval'] as Map<String, dynamic>;
      expect(after['stage'], 'payout');
      expect(step(after, 'head')['status'], 'done');
      expect((after['permissions'] as Map)['canAct'], false);
      final late = await vote(await signIn('a.head2'), id, 'approve');
      expect(late.status, 409);
      expect(late.body!['error'], 'not_now');
    });

    test('a waived block brings the committee, three votes decide, leave is excluded', () async {
      final current = await card(specialist);
      final certificate = openCheck(current, 'certificate');
      final waived = await post(
        specialist,
        '/api/bank/tranches/$id/checks/${certificate['id']}/waive',
        {'reason': 'outside_system', 'comment': 'Сертификат получен на бумаге'},
      );
      expect(waived.status, 200);
      final unlocked = waived.body!['card'] as Map<String, dynamic>;
      expect((unlocked['totals'] as Map)['issue'], '2083900000.00');
      expect(line(unlocked, rebarTitle)['blocked'], false);
      expect((await decide(specialist, id, 'partial')).status, 200);

      final head = await signIn('a.head1');
      final route = await approval(head, id);
      expect(step(route, 'committee')['status'], 'pending');
      expect(step(route, 'committee')['reason'], 'waived_block');

      expect((await vote(head, id, 'return')).status, 400);
      final returned = await vote(head, id, 'return', comment: 'Приложите скан сертификата');
      expect(returned.status, 200);
      expect((returned.body!['approval'] as Map)['stage'], 'specialist');
      expect((returned.body!['approval'] as Map)['round'], 2);
      expect(step(returned.body!['approval'] as Map<String, dynamic>, 'head')['votes'], isEmpty);
      expect((await decide(specialist, id, 'partial')).status, 200);

      expect((await vote(await signIn('a.head2'), id, 'approve')).status, 200);
      final committee = await approval(head, id);
      expect(step(committee, 'committee')['status'], 'current');
      expect((step(committee, 'committee')['group'] as Map)['available'], 4);
      expect(step(committee, 'committee')['required'], 3);

      final onLeave = await vote(await signIn('a.committee4'), id, 'approve');
      expect(onLeave.status, 403);
      expect(onLeave.body!['error'], 'on_leave');
      final first = await signIn('a.committee1');
      expect((await vote(first, id, 'approve')).status, 200);
      final repeated = await vote(first, id, 'approve');
      expect(repeated.status, 409);
      expect(repeated.body!['error'], 'voted');
      expect((await vote(await signIn('a.committee2'), id, 'approve')).status, 200);
      expect(((await approval(head, id))['stage']), 'approval');
      final last = await vote(await signIn('a.committee3'), id, 'approve');
      expect((last.body!['approval'] as Map)['stage'], 'payout');
    });

    test('a rejection closes the tranche', () async {
      expect((await decide(specialist, id, 'partial')).status, 200);
      final head = await signIn('a.head1');
      final rejected = await vote(head, id, 'reject', comment: 'Объект не соответствует условиям');
      expect(rejected.status, 200);
      expect((rejected.body!['approval'] as Map)['outcome'], 'rejected');
      final again = await vote(await signIn('a.head2'), id, 'approve');
      expect(again.status, 409);
      expect(again.body!['error'], 'closed');
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
