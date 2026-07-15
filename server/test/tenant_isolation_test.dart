// Track A.5: proves that a residence admin for one developer can never
// read or mutate another developer's projects/buildings/units/leads/media/
// offers/photo-reports through the `/v1/admin/*` surface — the in-memory
// counterpart to the RLS policies added in migrations/0012_rls_core_tables.sql
// (which give the same guarantee at the database layer once PostgreSQL
// persistence is enabled). See `_canManageProject()` in admin_routes.dart,
// which every route below is guarded by.
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../lib/src/app.dart';
import '../lib/src/store.dart';

Future<Map<String, dynamic>> _decode(Response response) async {
  final body = await response.readAsString();
  return jsonDecode(body) as Map<String, dynamic>;
}

Request _get(String path, {String? token}) => Request(
  'GET',
  Uri.parse('http://localhost$path'),
  headers: {if (token != null) 'authorization': 'Bearer $token'},
);

Request _post(String path, Map<String, dynamic> body, {String? token}) =>
    Request(
      'POST',
      Uri.parse('http://localhost$path'),
      body: jsonEncode(body),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      },
    );

Request _patch(String path, Map<String, dynamic> body, {String? token}) =>
    Request(
      'PATCH',
      Uri.parse('http://localhost$path'),
      body: jsonEncode(body),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      },
    );

Request _put(String path, Map<String, dynamic> body, {String? token}) =>
    Request(
      'PUT',
      Uri.parse('http://localhost$path'),
      body: jsonEncode(body),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      },
    );

Request _delete(String path, {String? token}) => Request(
  'DELETE',
  Uri.parse('http://localhost$path'),
  headers: {if (token != null) 'authorization': 'Bearer $token'},
);

Future<String> _signIn(Handler handler, String phone) async {
  final send = await handler(_post('/v1/auth/otp/send', {'phone': phone}));
  final sendJson = await _decode(send);
  final requestId = sendJson['data']['requestId'] as String;
  final verify = await handler(
    _post('/v1/auth/otp/verify', {'requestId': requestId, 'code': '123456'}),
  );
  final verifyJson = await _decode(verify);
  return verifyJson['data']['accessToken'] as String;
}

void main() {
  group('Tenant isolation: cross-developer admin access is blocked', () {
    late Store store;
    late Handler handler;
    late String ownerAToken;
    late String ownerAId;
    late String projectAId;
    late String projectBId;
    late String buildingBId;
    late String unitBId;
    late String leadBId;
    late String photoReportBId;

    setUp(() async {
      store = Store();
      handler = createHandler(store);

      // --- Developer A + a project of their own (the "attacker's" tenant). --
      final ownerAToken0 = await _signIn(handler, '+998901111001');
      final ownerAMe = await handler(_get('/v1/users/me', token: ownerAToken0));
      ownerAId = (await _decode(ownerAMe))['data']['id'] as String;
      final devA = store.registerDeveloper(
        ownerUserId: ownerAId,
        name: 'Itest Devco A',
        legalName: 'OOO Itest Devco A',
        inn: '301100001',
        phone: '+998901111001',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent',
        directorFullName: 'Director A',
        directorPinfl: '30101100000001',
        uboDeclared: true,
      );
      store.submitDeveloperForReview(ownerAId);
      store.setDeveloperVerification(devA['id'] as String, 'approved');
      final projectA = store.createProjectForOwner(
        ownerUserId: ownerAId,
        input: {'name': 'Devco A Towers', 'district': 'Yunusabad'},
      )!;
      projectAId = projectA['id'] as String;
      // Re-sign-in so the token's live-looked-up user reflects the fresh
      // `residence_admin` role granted by setDeveloperVerification above.
      ownerAToken = await _signIn(handler, '+998901111001');

      // --- Developer B + a fully-populated project (the "victim" tenant). ---
      final ownerBToken = await _signIn(handler, '+998901111002');
      final ownerBMe = await handler(_get('/v1/users/me', token: ownerBToken));
      final ownerBId = (await _decode(ownerBMe))['data']['id'] as String;
      final devB = store.registerDeveloper(
        ownerUserId: ownerBId,
        name: 'Itest Devco B',
        legalName: 'OOO Itest Devco B',
        inn: '301100002',
        phone: '+998901111002',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent',
        directorFullName: 'Director B',
        directorPinfl: '30101100000002',
        uboDeclared: true,
      );
      store.submitDeveloperForReview(ownerBId);
      store.setDeveloperVerification(devB['id'] as String, 'approved');
      final projectB = store.createProjectForOwner(
        ownerUserId: ownerBId,
        input: {'name': 'Devco B Towers', 'district': 'Mirzo Ulugbek'},
      )!;
      projectBId = projectB['id'] as String;
      final buildingB = store.addBuilding(projectBId, {'name': 'Block B1'});
      buildingBId = buildingB['id'] as String;
      final unitB = store.addUnit(projectBId, {'buildingId': buildingBId})!;
      unitBId = unitB['id'] as String;
      final leadB = store.createLead({
        'projectId': projectBId,
        'intent': 'callback',
        'consent': true,
      });
      leadBId = leadB['id'] as String;
      final photoReportB = store.addPhotoReport(
        projectId: projectBId,
        photoUrl: 'https://example.com/b.jpg',
        takenAt: DateTime.now(),
        takenAtIsManual: false,
        uploadedBy: ownerBId,
      );
      photoReportBId = photoReportB['id'] as String;
    });

    tearDown(() => store.dispose());

    test(
      'every /v1/admin/* route scoped to another developer\'s resources '
      'returns 403/404, never that developer\'s data',
      () async {
        final probes = <String, Future<Response> Function()>{
          'GET /v1/admin/projects/:id': () async =>
              handler(_get('/v1/admin/projects/$projectBId', token: ownerAToken)),
          'PATCH /v1/admin/projects/:id': () async => handler(
            _patch('/v1/admin/projects/$projectBId', {
              'name': 'hijacked',
            }, token: ownerAToken),
          ),
          'DELETE /v1/admin/projects/:id': () async => handler(
            _delete('/v1/admin/projects/$projectBId', token: ownerAToken),
          ),
          'POST /v1/admin/projects/:id/unpublish': () async => handler(
            _post(
              '/v1/admin/projects/$projectBId/unpublish',
              const {},
              token: ownerAToken,
            ),
          ),
          'POST /v1/admin/projects/:id/publish': () async => handler(
            _post(
              '/v1/admin/projects/$projectBId/publish',
              const {},
              token: ownerAToken,
            ),
          ),
          'POST /v1/admin/projects/:id/submit-for-review': () async => handler(
            _post(
              '/v1/admin/projects/$projectBId/submit-for-review',
              const {},
              token: ownerAToken,
            ),
          ),
          'POST /v1/admin/projects/:id/buildings': () async => handler(
            _post('/v1/admin/projects/$projectBId/buildings', {
              'name': 'hijacked block',
            }, token: ownerAToken),
          ),
          'POST /v1/admin/projects/:id/units': () async => handler(
            _post('/v1/admin/projects/$projectBId/units', {
              'buildingId': buildingBId,
            }, token: ownerAToken),
          ),
          'PATCH /v1/admin/units/:uid': () async => handler(
            _patch('/v1/admin/units/$unitBId', {
              'status': 'sold',
            }, token: ownerAToken),
          ),
          'POST /v1/admin/units/:uid/media': () async => handler(
            _post('/v1/admin/units/$unitBId/media', {
              'url': 'https://example.com/hijacked.jpg',
            }, token: ownerAToken),
          ),
          'POST /v1/admin/projects/:id/photo-reports': () async => handler(
            _post('/v1/admin/projects/$projectBId/photo-reports', {
              'url': 'https://example.com/hijacked.jpg',
            }, token: ownerAToken),
          ),
          'DELETE /v1/admin/photo-reports/:id': () async => handler(
            _delete(
              '/v1/admin/photo-reports/$photoReportBId',
              token: ownerAToken,
            ),
          ),
          'GET /v1/admin/projects/:id/offers': () async => handler(
            _get('/v1/admin/projects/$projectBId/offers', token: ownerAToken),
          ),
          'PUT /v1/admin/projects/:id/offers': () async => handler(
            _put('/v1/admin/projects/$projectBId/offers', {
              'offers': [],
            }, token: ownerAToken),
          ),
          'GET /v1/admin/projects/:id/analytics': () async => handler(
            _get(
              '/v1/admin/projects/$projectBId/analytics',
              token: ownerAToken,
            ),
          ),
          'GET /v1/admin/projects/:id/leads': () async => handler(
            _get('/v1/admin/projects/$projectBId/leads', token: ownerAToken),
          ),
          'PATCH /v1/admin/leads/:lid': () async => handler(
            _patch('/v1/admin/leads/$leadBId', {
              'status': 'contacted',
            }, token: ownerAToken),
          ),
          'PATCH /v1/admin/leads/:lid ownerUserId': () async => handler(
            _patch('/v1/admin/leads/$leadBId', {
              'ownerUserId': ownerAId,
            }, token: ownerAToken),
          ),
          'POST /v1/admin/leads/:lid/transfer': () async => handler(
            _post('/v1/admin/leads/$leadBId/transfer', {
              'toUserId': ownerAId,
            }, token: ownerAToken),
          ),
          'GET /v1/admin/leads/:lid/events': () async => handler(
            _get('/v1/admin/leads/$leadBId/events', token: ownerAToken),
          ),
        };

        for (final entry in probes.entries) {
          final response = await entry.value();
          expect(
            response.statusCode == 403 || response.statusCode == 404,
            isTrue,
            reason:
                '${entry.key} should return 403/404 for a cross-developer '
                'caller, got ${response.statusCode}',
          );
          final json = await _decode(response);
          expect(
            json['success'],
            isFalse,
            reason: '${entry.key} leaked a success envelope cross-developer',
          );
        }

        // Ground truth: developer B's data must be completely untouched by
        // every write attempt above.
        expect(store.projectById(projectBId)!['name'], 'Devco B Towers');
        expect(store.unitById(unitBId)!.unit['status'], 'available');
        expect(store.leadById(leadBId)!['status'], 'new');
        expect(store.leadById(leadBId)!['ownerUserId'], isNull);
        expect(store.photoReportById(photoReportBId), isNotNull);
      },
    );

    test(
      'sanity: the same route shapes succeed for the developer\'s own '
      'project',
      () async {
        final response = await handler(
          _get('/v1/admin/projects/$projectAId', token: ownerAToken),
        );
        expect(response.statusCode, 200);
        final json = await _decode(response);
        expect(json['data']['id'], projectAId);
      },
    );
  });
}
