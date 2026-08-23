import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../lib/src/app.dart';
import '../lib/src/env_loader.dart';
import '../lib/src/store.dart';
import 'test_fixtures.dart';

Future<Map<String, dynamic>> _decode(Response response) async {
  final body = await response.readAsString();
  return jsonDecode(body) as Map<String, dynamic>;
}

void main() {
  late Store store;
  late Handler handler;
  late String demoToken;

  setUp(() {
    store = createTestStore();
    handler = createHandler(store);
    final result = store.createDemoSession(profile: 'b2b_platform');
    demoToken = result.accessToken!;
  });

  tearDown(() => store.dispose());

  test('demo platform users returns live admin data', () async {
    store.ensureUser(phone: '+998901234567', role: 'system_admin');

    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/platform/users'),
        headers: {'authorization': 'Bearer $demoToken'},
      ),
    );
    expect(response.statusCode, 200);
    final json = await _decode(response);
    final phones = (json['data'] as List)
        .map((u) => (u as Map)['phone'])
        .join(' ');
    expect(phones, contains('+998901234567'));
  });

  test('demo cannot delete users (write blocked)', () async {
    final response = await handler(
      Request(
        'DELETE',
        Uri.parse('http://localhost/v1/platform/users/real-user-id'),
        headers: {'authorization': 'Bearer $demoToken'},
      ),
    );
    expect(response.statusCode, 403);
    final json = await _decode(response);
    expect(json['error']['code'], 'DEMO_READ_ONLY');
  });

  test('demo can read admin project detail for any project', () async {
    final project = store.publishedProjects.first;
    final id = project['id'] as String;

    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/admin/projects/$id'),
        headers: {'authorization': 'Bearer $demoToken'},
      ),
    );
    expect(response.statusCode, 200);
    final json = await _decode(response);
    expect(json['data']['id'], id);
  });

  test('demo cannot patch admin project (write blocked)', () async {
    final project = store.publishedProjects.first;
    final id = project['id'] as String;

    final response = await handler(
      Request(
        'PATCH',
        Uri.parse('http://localhost/v1/admin/projects/$id'),
        headers: {
          'authorization': 'Bearer $demoToken',
          'content-type': 'application/json',
        },
        body: jsonEncode({'name': 'Hacked'}),
      ),
    );
    expect(response.statusCode, 403);
    final json = await _decode(response);
    expect(json['error']['code'], 'DEMO_READ_ONLY');
  });

  test('demo platform analytics returns live totals plus overlay counts',
      () async {
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/platform/analytics'),
        headers: {'authorization': 'Bearer $demoToken'},
      ),
    );
    expect(response.statusCode, 200);
    final json = await _decode(response);
    expect(json['data'], isA<Map>());
    expect(json['data']['demo'], isNot(true));
    expect(
      json['data']['leadsTotal'] as int,
      greaterThan(store.leads.length),
    );
    expect(json['data']['publishedProjects'], store.publishedProjects.length);
  });

  test('demo platform leads include placeholders bound to live projects',
      () async {
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/platform/leads'),
        headers: {'authorization': 'Bearer $demoToken'},
      ),
    );
    expect(response.statusCode, 200);
    final json = await _decode(response);
    final items = (json['data'] as List).cast<Map>();
    final placeholders = items
        .where((l) => l['isDemoPlaceholder'] == true)
        .toList();
    expect(placeholders, isNotEmpty);
    // Two demo leads per published project.
    expect(
      placeholders.length,
      store.publishedProjects.length * 2,
    );
    final byProject = <String, int>{};
    for (final lead in placeholders) {
      final id = lead['projectId'] as String;
      byProject[id] = (byProject[id] ?? 0) + 1;
    }
    for (final count in byProject.values) {
      expect(count, 2);
    }
    final liveIds = store.publishedProjects.map((p) => p['id']).toSet();
    for (final lead in placeholders) {
      expect(liveIds, contains(lead['projectId']));
      expect(lead['aiBand'], isIn(['hot', 'warm', 'cold']));
    }
  });

  test('real admin does not see demo CRM placeholders', () async {
    store.ensureUser(phone: '+998901234567', role: 'system_admin');
    final adminToken = await _signIn(handler);

    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/platform/leads'),
        headers: {'authorization': 'Bearer $adminToken'},
      ),
    );
    expect(response.statusCode, 200);
    final json = await _decode(response);
    final items = (json['data'] as List).cast<Map>();
    expect(items.every((l) => l['isDemoPlaceholder'] != true), isTrue);
    expect(json['meta']['total'], store.leads.length);
  });

  test('demo CRM assistant sees the same overlay leads', () async {
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/ai/crm/leads?limit=100'),
        headers: {'authorization': 'Bearer $demoToken'},
      ),
    );
    expect(response.statusCode, 200);
    final json = await _decode(response);
    final leads = (json['data']['leads'] as List).cast<Map>();
    expect(
      leads.where((l) => l['isDemoPlaceholder'] == true),
      isNotEmpty,
    );
  });

  test('demo lead events for an overlay id do not 404', () async {
    final leadsRes = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/platform/leads'),
        headers: {'authorization': 'Bearer $demoToken'},
      ),
    );
    final leads = ((await _decode(leadsRes))['data'] as List).cast<Map>();
    final overlayId = leads.firstWhere(
      (l) => l['isDemoPlaceholder'] == true,
    )['id'] as String;

    final events = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/admin/leads/$overlayId/events'),
        headers: {'authorization': 'Bearer $demoToken'},
      ),
    );
    expect(events.statusCode, 200);
    final json = await _decode(events);
    expect(json['data'], isNotEmpty);
  });

  test('demo tickets, notifications, reviews and rentals are placeholders',
      () async {
    Future<List<Map>> fetch(String path) async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost$path'),
          headers: {'authorization': 'Bearer $demoToken'},
        ),
      );
      expect(response.statusCode, 200, reason: path);
      return ((await _decode(response))['data'] as List).cast<Map>();
    }

    expect(
      (await fetch('/v1/platform/tickets'))
          .where((t) => t['isDemoPlaceholder'] == true),
      isNotEmpty,
    );
    expect(
      (await fetch('/v1/platform/notifications'))
          .where((n) => n['isDemoPlaceholder'] == true),
      isNotEmpty,
    );
    expect(
      (await fetch('/v1/platform/reviews/pending'))
          .where((r) => r['isDemoPlaceholder'] == true && r['status'] == 'flagged'),
      isNotEmpty,
    );
    expect(
      (await fetch('/v1/platform/rental-listings/pending'))
          .where((r) => r['isDemoPlaceholder'] == true),
      isNotEmpty,
    );
    expect(
      (await fetch('/v1/platform/developers/pending'))
          .where((d) => d['isDemoPlaceholder'] == true),
      isNotEmpty,
    );
    expect(
      (await fetch('/v1/platform/audit-log'))
          .where((a) => a['isDemoPlaceholder'] == true),
      isNotEmpty,
    );
  });

  test('real admin lists stay empty of overlay ids', () async {
    store.ensureUser(phone: '+998901234567', role: 'system_admin');
    final adminToken = await _signIn(handler);

    Future<List<Map>> fetch(String path) async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost$path'),
          headers: {'authorization': 'Bearer $adminToken'},
        ),
      );
      expect(response.statusCode, 200, reason: path);
      return ((await _decode(response))['data'] as List).cast<Map>();
    }

    for (final path in [
      '/v1/platform/tickets',
      '/v1/platform/notifications',
      '/v1/platform/reviews/pending',
      '/v1/platform/rental-listings/pending',
      '/v1/platform/developers/pending',
      '/v1/platform/users',
    ]) {
      expect(
        (await fetch(path)).every((row) => row['isDemoPlaceholder'] != true),
        isTrue,
        reason: path,
      );
    }
  });

  test('demo KYC documents for an overlay developer do not 404', () async {
    final pending = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/platform/developers/pending'),
        headers: {'authorization': 'Bearer $demoToken'},
      ),
    );
    final items = ((await _decode(pending))['data'] as List).cast<Map>();
    final overlay = items.firstWhere((d) => d['isDemoPlaceholder'] == true);
    final docs = await handler(
      Request(
        'GET',
        Uri.parse(
          'http://localhost/v1/platform/developers/${overlay['id']}/documents',
        ),
        headers: {'authorization': 'Bearer $demoToken'},
      ),
    );
    expect(docs.statusCode, 200);
    final json = await _decode(docs);
    expect(json['data'], isNotEmpty);
  });

  test('residence demo is NestOne admin with CRM placeholders', () async {
    final result = store.createDemoSession(profile: 'b2b_residence');
    final token = result.accessToken!;
    expect(result.user!['name'], 'NestOne Admin');
    expect(result.user!['role'], 'residence_admin');

    final meDev = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/developers/me'),
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    expect(meDev.statusCode, 200);
    final org = (await _decode(meDev))['data'] as Map;
    expect(org['canPublish'], isTrue);
    expect((org['subscription'] as Map?)?['status'], 'active');

    final projectsRes = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/developers/me/projects'),
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    expect(projectsRes.statusCode, 200);
    final projects = ((await _decode(projectsRes))['data'] as List).cast<Map>();
    expect(projects, isNotEmpty);
    final projectId = projects.first['id'] as String;

    final leadsRes = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/admin/projects/$projectId/leads'),
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    expect(leadsRes.statusCode, 200);
    final leads = ((await _decode(leadsRes))['data'] as List).cast<Map>();
    final placeholders =
        leads.where((l) => l['isDemoPlaceholder'] == true).toList();
    expect(placeholders.length, greaterThanOrEqualTo(2));

    final analyticsRes = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/admin/projects/$projectId/analytics'),
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    expect(analyticsRes.statusCode, 200);
    final analytics = (await _decode(analyticsRes))['data'] as Map;
    expect(analytics['leadsTotal'] as int, greaterThanOrEqualTo(2));

    final platformLeads = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/platform/leads'),
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    expect(platformLeads.statusCode, 403);
  });

  test('POST /v1/auth/demo is blocked when DEMO_LOGIN_ENABLED=false', () async {
    setAppEnvTestOverrides({'DEMO_LOGIN_ENABLED': 'false'});
    addTearDown(() {
      setAppEnvTestOverrides(null);
    });
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/v1/auth/demo'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'profile': 'b2b_platform'}),
      ),
    );
    expect(response.statusCode, 403);
    expect((await _decode(response))['error']['code'], 'FORBIDDEN');
  });

  test('POST /v1/auth/demo stays off in production without explicit enable',
      () async {
    setAppEnvTestOverrides({
      'APP_ENV': 'production',
      'DEMO_LOGIN_ENABLED': '',
    });
    addTearDown(() {
      setAppEnvTestOverrides(null);
    });
    expect(demoLoginEnabled, isFalse);
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/v1/auth/demo'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'profile': 'b2b_platform'}),
      ),
    );
    expect(response.statusCode, 403);
  });
}

Future<String> _signIn(
  Handler handler, {
  String phone = '+998901234567',
}) async {
  final send = await handler(
    Request(
      'POST',
      Uri.parse('http://localhost/v1/auth/otp/send'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    ),
  );
  final sendJson = await _decode(send);
  final requestId = sendJson['data']['requestId'] as String;
  final verify = await handler(
    Request(
      'POST',
      Uri.parse('http://localhost/v1/auth/otp/verify'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'requestId': requestId, 'code': '123456'}),
    ),
  );
  final verifyJson = await _decode(verify);
  return verifyJson['data']['accessToken'] as String;
}
