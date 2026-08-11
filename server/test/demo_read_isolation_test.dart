import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../lib/src/app.dart';
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

  test('demo platform analytics returns live totals', () async {
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
  });
}
