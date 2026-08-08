// Track A.3 (Documents API) and A.4 (Photo Reports API) coverage: upload,
// listing, moderator review, approve-gating, and the
// `progressPercent` -> `projects.constructionProgress` side-effect.
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
  group('Documents API', () {
    late Store store;
    late Handler handler;
    late String adminToken;
    late String ownerToken;
    late String developerId;

    setUp(() async {
      store = Store();
      store.ensureUser(phone: '+998901234567', role: 'system_admin');
      handler = createHandler(store);
      adminToken = await _signIn(handler, '+998901234567');

      ownerToken = await _signIn(handler, '+998907001234');
      final ownerMe = await handler(_get('/v1/users/me', token: ownerToken));
      final ownerId = (await _decode(ownerMe))['data']['id'] as String;
      final developer = store.registerDeveloper(
        ownerUserId: ownerId,
        name: 'Doc Test Devco',
        legalName: 'OOO Doc Test Devco',
        inn: '301200001',
        phone: '+998907001234',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent',
        directorFullName: 'Director',
        directorPinfl: '30101200000001',
        uboDeclared: true,
      );
      store.submitDeveloperForReview(ownerId);
      developerId = developer['id'] as String;
      // Deliberately *not* promoted to residence_admin here: that role only
      // exists after approval, and approval itself requires these documents
      // to already be accepted, so every test in this group exercises the
      // realistic pre-approval caller (still `pending`) uploading against
      // their own application.
    });

    tearDown(() => store.dispose());

    test(
      'a pending applicant (not yet residence_admin) can upload documents '
      'against their own application',
      () async {
        final response = await handler(
          _post('/v1/developers/me/documents', {
            'type': 'license',
            'fileUrl': 'https://example.com/license.pdf',
          }, token: ownerToken),
        );
        expect(
          response.statusCode,
          201,
          reason:
              'document upload must work before approval — approval itself '
              'requires all 4 documents already accepted, so gating upload '
              'on residence_admin would make approval impossible',
        );
      },
    );

    test(
      'POST /v1/developers/me/documents uploads a document, and it shows '
      'up in GET /v1/developers/me/documents',
      () async {
        final response = await handler(
          _post('/v1/developers/me/documents', {
            'type': 'license',
            'fileUrl': 'https://example.com/license.pdf',
          }, token: ownerToken),
        );
        expect(response.statusCode, 201);
        final json = await _decode(response);
        expect(json['data']['type'], 'license');
        expect(json['data']['fileUrl'], 'https://example.com/license.pdf');
        expect(json['data']['status'], 'pending');

        final list = await handler(
          _get('/v1/developers/me/documents', token: ownerToken),
        );
        expect(list.statusCode, 200);
        final listJson = await _decode(list);
        expect((listJson['data'] as List).length, 1);
      },
    );

    test('POST /v1/developers/me/documents rejects an invalid type', () async {
      final response = await handler(
        _post('/v1/developers/me/documents', {
          'type': 'not-a-real-type',
          'fileUrl': 'https://example.com/x.pdf',
        }, token: ownerToken),
      );
      expect(response.statusCode, 422);
    });

    test(
      'GET /v1/platform/developers/:id/documents lets a moderator view a '
      'specific developer\'s documents',
      () async {
        await handler(
          _post('/v1/developers/me/documents', {
            'type': 'license',
            'fileUrl': 'https://example.com/license.pdf',
          }, token: ownerToken),
        );
        final response = await handler(
          _get(
            '/v1/platform/developers/$developerId/documents',
            token: adminToken,
          ),
        );
        expect(response.statusCode, 200);
        final json = await _decode(response);
        expect((json['data'] as List).length, 1);
      },
    );

    test(
      'PATCH /v1/platform/documents/:id lets a moderator accept or reject, '
      'and requires rejectReason when rejecting',
      () async {
        final upload = await handler(
          _post('/v1/developers/me/documents', {
            'type': 'license',
            'fileUrl': 'https://example.com/license.pdf',
          }, token: ownerToken),
        );
        final docId = (await _decode(upload))['data']['id'] as String;

        final missingReason = await handler(
          _patch('/v1/platform/documents/$docId', {
            'status': 'rejected',
          }, token: adminToken),
        );
        expect(missingReason.statusCode, 422);

        final rejected = await handler(
          _patch('/v1/platform/documents/$docId', {
            'status': 'rejected',
            'rejectReason': 'Blurry scan',
          }, token: adminToken),
        );
        expect(rejected.statusCode, 200);
        final rejectedJson = await _decode(rejected);
        expect(rejectedJson['data']['status'], 'rejected');
        expect(rejectedJson['data']['rejectReason'], 'Blurry scan');

        final accepted = await handler(
          _patch('/v1/platform/documents/$docId', {
            'status': 'accepted',
          }, token: adminToken),
        );
        expect(accepted.statusCode, 200);
        expect((await _decode(accepted))['data']['status'], 'accepted');
      },
    );

    test(
      'PATCH /v1/platform/developers/:id/approve is gated on all 4 '
      'required document types being accepted',
      () async {
        // No documents at all yet — must fail.
        final noDocs = await handler(
          _patch(
            '/v1/platform/developers/$developerId/approve',
            const {},
            token: adminToken,
          ),
        );
        expect(noDocs.statusCode, 422);

        // Upload + accept 3 of the 4 required types — still must fail.
        final threeOfFour = kRequiredDocumentTypes.take(3);
        for (final type in threeOfFour) {
          final upload = await handler(
            _post('/v1/developers/me/documents', {
              'type': type,
              'fileUrl': 'https://example.com/$type.pdf',
            }, token: ownerToken),
          );
          final docId = (await _decode(upload))['data']['id'] as String;
          await handler(
            _patch('/v1/platform/documents/$docId', {
              'status': 'accepted',
            }, token: adminToken),
          );
        }
        final stillMissing = await handler(
          _patch(
            '/v1/platform/developers/$developerId/approve',
            const {},
            token: adminToken,
          ),
        );
        expect(stillMissing.statusCode, 422);

        // Accept the 4th required type — approval must now succeed.
        final lastType = kRequiredDocumentTypes.last;
        final upload = await handler(
          _post('/v1/developers/me/documents', {
            'type': lastType,
            'fileUrl': 'https://example.com/$lastType.pdf',
          }, token: ownerToken),
        );
        final docId = (await _decode(upload))['data']['id'] as String;
        await handler(
          _patch('/v1/platform/documents/$docId', {
            'status': 'accepted',
          }, token: adminToken),
        );

        final approve = await handler(
          _patch(
            '/v1/platform/developers/$developerId/approve',
            const {},
            token: adminToken,
          ),
        );
        expect(approve.statusCode, 200);
        final approveJson = await _decode(approve);
        expect(approveJson['data']['verificationStatus'], 'approved');
      },
    );

    test(
      'GET /v1/developers/:id/verification is public and reports '
      '"missing" for required types with no uploaded document yet',
      () async {
        // No auth header at all — must still succeed.
        final response = await handler(
          _get('/v1/developers/$developerId/verification'),
        );
        expect(response.statusCode, 200);
        final json = await _decode(response);
        expect(json['data']['developerId'], developerId);
        expect(json['data']['verificationStatus'], isNotNull);

        final docs = (json['data']['documents'] as List)
            .cast<Map<String, dynamic>>();
        expect(docs.length, kRequiredDocumentTypes.length);
        expect(
          docs.map((d) => d['type']).toSet(),
          kRequiredDocumentTypes,
        );
        for (final d in docs) {
          expect(d['status'], 'missing');
        }
      },
    );

    test(
      'GET /v1/developers/:id/verification reflects real per-document '
      'statuses without leaking fileUrl or rejectReason',
      () async {
        final licenseUpload = await handler(
          _post('/v1/developers/me/documents', {
            'type': 'license',
            'fileUrl': 'https://example.com/license.pdf',
          }, token: ownerToken),
        );
        final licenseId = (await _decode(licenseUpload))['data']['id']
            as String;
        await handler(
          _patch('/v1/platform/documents/$licenseId', {
            'status': 'accepted',
          }, token: adminToken),
        );

        final permitUpload = await handler(
          _post('/v1/developers/me/documents', {
            'type': 'construction_permit',
            'fileUrl': 'https://example.com/permit.pdf',
          }, token: ownerToken),
        );
        final permitId = (await _decode(permitUpload))['data']['id']
            as String;
        await handler(
          _patch('/v1/platform/documents/$permitId', {
            'status': 'rejected',
            'rejectReason': 'Blurry scan',
          }, token: adminToken),
        );

        final response = await handler(
          _get('/v1/developers/$developerId/verification'),
        );
        expect(response.statusCode, 200);
        final body = await response.readAsString();
        // Neither the rejected file's URL nor its reject reason may leak
        // into the public summary.
        expect(body.contains('license.pdf'), isFalse);
        expect(body.contains('permit.pdf'), isFalse);
        expect(body.contains('Blurry scan'), isFalse);
        expect(body.contains('fileUrl'), isFalse);
        expect(body.contains('rejectReason'), isFalse);
        expect(body.contains('uploadedBy'), isFalse);

        final json = jsonDecode(body) as Map<String, dynamic>;
        final docs = (json['data']['documents'] as List)
            .cast<Map<String, dynamic>>();
        final byType = {for (final d in docs) d['type'] as String: d};
        expect(byType['license']?['status'], 'accepted');
        expect(byType['construction_permit']?['status'], 'rejected');
        expect(byType['land_rights']?['status'], 'missing');
        expect(byType['project_declaration']?['status'], 'missing');
        expect(byType.length, 4);
        for (final d in docs) {
          expect(d.keys.toSet(), {'type', 'status'});
        }
      },
    );
  });

  group('Photo Reports API', () {
    late Store store;
    late Handler handler;
    late String ownerToken;
    late String projectId;

    setUp(() async {
      store = Store();
      handler = createHandler(store);

      ownerToken = await _signIn(handler, '+998907005678');
      final ownerMe = await handler(_get('/v1/users/me', token: ownerToken));
      final ownerId = (await _decode(ownerMe))['data']['id'] as String;
      final developer = store.registerDeveloper(
        ownerUserId: ownerId,
        name: 'Photo Test Devco',
        legalName: 'OOO Photo Test Devco',
        inn: '301200002',
        phone: '+998907005678',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent',
        directorFullName: 'Director',
        directorPinfl: '30101200000002',
        uboDeclared: true,
      );
      store.submitDeveloperForReview(ownerId);
      store.setDeveloperVerification(developer['id'] as String, 'approved');
      final project = store.createProjectForOwner(
        ownerUserId: ownerId,
        input: {'name': 'Photo Towers', 'district': 'Chilanzar'},
      )!;
      projectId = project['id'] as String;
      // Refresh so the token's live-looked-up user reflects the
      // residence_admin role granted by setDeveloperVerification.
      ownerToken = await _signIn(handler, '+998907005678');
    });

    tearDown(() => store.dispose());

    test(
      'POST /v1/admin/projects/:id/photo-reports uploads a report and '
      'updates projects.constructionProgress when progressPercent is given',
      () async {
        final response = await handler(
          _post('/v1/admin/projects/$projectId/photo-reports', {
            'url': 'https://example.com/foundation.jpg',
            'takenAt': '2026-01-15',
            'progressPercent': 35,
          }, token: ownerToken),
        );
        expect(response.statusCode, 201);
        final json = await _decode(response);
        expect(json['data']['photoUrl'], 'https://example.com/foundation.jpg');
        expect(json['data']['takenAt'], '2026-01-15');
        expect(json['data']['progressPercent'], 35);

        final project = await handler(
          _get('/v1/admin/projects/$projectId', token: ownerToken),
        );
        final projectJson = await _decode(project);
        expect(projectJson['data']['constructionProgress'], 35);
      },
    );

    test(
      'GET /v1/projects/:id/photo-reports lists entries newest-first',
      () async {
        await handler(
          _post('/v1/admin/projects/$projectId/photo-reports', {
            'url': 'https://example.com/jan.jpg',
            'takenAt': '2026-01-01',
          }, token: ownerToken),
        );
        await handler(
          _post('/v1/admin/projects/$projectId/photo-reports', {
            'url': 'https://example.com/mar.jpg',
            'takenAt': '2026-03-01',
          }, token: ownerToken),
        );
        await handler(
          _post('/v1/admin/projects/$projectId/photo-reports', {
            'url': 'https://example.com/feb.jpg',
            'takenAt': '2026-02-01',
          }, token: ownerToken),
        );

        final response = await handler(
          _get('/v1/projects/$projectId/photo-reports', token: ownerToken),
        );
        expect(response.statusCode, 200);
        final json = await _decode(response);
        final items = (json['data'] as List).cast<Map<String, dynamic>>();
        expect(items.length, 3);
        expect(
          items.map((r) => r['takenAt']),
          ['2026-03-01', '2026-02-01', '2026-01-01'],
        );
      },
    );

    test('DELETE /v1/admin/photo-reports/:id removes an entry', () async {
      final upload = await handler(
        _post('/v1/admin/projects/$projectId/photo-reports', {
          'url': 'https://example.com/oops.jpg',
        }, token: ownerToken),
      );
      final reportId = (await _decode(upload))['data']['id'] as String;

      final deleted = await handler(
        _delete('/v1/admin/photo-reports/$reportId', token: ownerToken),
      );
      expect(deleted.statusCode, 200);

      final list = await handler(
        _get('/v1/projects/$projectId/photo-reports', token: ownerToken),
      );
      final listJson = await _decode(list);
      expect(listJson['data'], isEmpty);
    });

    test(
      'POST /v1/admin/projects/:id/photo-reports rejects a missing url',
      () async {
        final response = await handler(
          _post(
            '/v1/admin/projects/$projectId/photo-reports',
            const {},
            token: ownerToken,
          ),
        );
        expect(response.statusCode, 422);
      },
    );

    test(
      'a report leaving the project within 15 points of its own schedule '
      'raises no alert',
      () async {
        store.updateProject(projectId, {'plannedProgress': 50});
        await handler(
          _post('/v1/admin/projects/$projectId/photo-reports', {
            'url': 'https://example.com/frame.jpg',
            'progressPercent': 36,
          }, token: ownerToken),
        );
        expect(
          store.adminNotifications().where(
            (n) => n['type'] == 'progress_deviation',
          ),
          isEmpty,
          reason:
              'a 14-point gap is routine site variance — escalating it would '
              'bury the alerts that do warrant an inspector',
        );
      },
    );

    test(
      'a report putting the project more than 15 points behind its own '
      'schedule raises a critical alert for the platform admin',
      () async {
        store.updateProject(projectId, {'plannedProgress': 50});
        await handler(
          _post('/v1/admin/projects/$projectId/photo-reports', {
            'url': 'https://example.com/pit.jpg',
            'progressPercent': 20,
          }, token: ownerToken),
        );
        final alerts = store
            .adminNotifications()
            .where((n) => n['type'] == 'progress_deviation')
            .toList();
        expect(alerts.length, 1);
        expect(alerts.single['severity'], 'critical');
        expect(alerts.single['projectId'], projectId);
        expect(alerts.single['body'], contains('30%'));
      },
    );

    test('a project with no filed schedule is never flagged', () async {
      await handler(
        _post('/v1/admin/projects/$projectId/photo-reports', {
          'url': 'https://example.com/pit.jpg',
          'progressPercent': 2,
        }, token: ownerToken),
      );
      expect(
        store.adminNotifications().where(
          (n) => n['type'] == 'progress_deviation',
        ),
        isEmpty,
      );
    });
  });
}
