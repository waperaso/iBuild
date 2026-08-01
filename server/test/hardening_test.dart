import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../lib/src/app.dart';
import '../lib/src/rate_limiter.dart';
import '../lib/src/static_files.dart';
import '../lib/src/store.dart';

/// Regression tests for the audit fixes: malformed-body handling, catalogue
/// filter semantics, pagination bounds, review rating validation, static-file
/// traversal, and rate-limiter memory/spoofing behaviour.
Future<Map<String, dynamic>> _decode(Response response) async =>
    jsonDecode(await response.readAsString()) as Map<String, dynamic>;

Request _get(String path, {String? token}) => Request(
  'GET',
  Uri.parse('http://localhost$path'),
  headers: {if (token != null) 'authorization': 'Bearer $token'},
);

Request _rawPost(String path, String body, {String? token}) => Request(
  'POST',
  Uri.parse('http://localhost$path'),
  body: body,
  headers: {
    'content-type': 'application/json',
    if (token != null) 'authorization': 'Bearer $token',
  },
);

Request _post(String path, Map<String, dynamic> body, {String? token}) =>
    _rawPost(path, jsonEncode(body), token: token);

Future<String> _signIn(
  Handler handler, {
  String phone = '+998901234567',
}) async {
  final send = await handler(_post('/v1/auth/otp/send', {'phone': phone}));
  final requestId = (await _decode(send))['data']['requestId'] as String;
  final verify = await handler(
    _post('/v1/auth/otp/verify', {'requestId': requestId, 'code': '123456'}),
  );
  return (await _decode(verify))['data']['accessToken'] as String;
}

/// Seed developers carry no `ownerUserId`, so tests that need an owned
/// developer org register one against a real signed-in user.
Map<String, dynamic> _registerDeveloper(Store store, String ownerUserId) =>
    store.registerDeveloper(
      ownerUserId: ownerUserId,
      name: 'Test Dev',
      legalName: 'Test Dev LLC',
      inn: '123456789',
      phone: '+998901234567',
      accountKind: 'company',
      legalForm: 'LLC',
      legalAddress: 'Tashkent',
      directorFullName: 'Director Name',
      directorPinfl: '12345678901234',
      uboDeclared: true,
    );

void main() {
  late Store store;
  late Handler handler;

  // `Store()` (not `Store.create()`) keeps these hermetic and in-memory —
  // `create()` would try to reach the PostgreSQL host in server/.env.
  setUp(() {
    store = Store();
    handler = createHandler(store);
  });

  tearDown(() => store.dispose());

  group('malformed request bodies answer with the JSON envelope', () {
    test('syntactically invalid JSON is a 422, not a plain-text 500', () async {
      final response = await handler(
        _rawPost('/v1/auth/otp/send', '{"phone": '),
      );
      expect(response.statusCode, 422);
      final json = await _decode(response);
      expect(json['success'], isFalse);
      expect(json['error']['code'], 'VALIDATION_ERROR');
    });

    test(
      'a JSON array body is rejected rather than crashing the cast',
      () async {
        final response = await handler(
          _rawPost('/v1/auth/otp/send', '[1,2,3]'),
        );
        expect(response.statusCode, 422);
        expect((await _decode(response))['error']['code'], 'VALIDATION_ERROR');
      },
    );

    test('an empty body still reaches per-field validation', () async {
      final response = await handler(_rawPost('/v1/auth/otp/send', ''));
      expect(response.statusCode, 422);
      final json = await _decode(response);
      expect(json['error']['message'], contains('phone'));
    });
  });

  group('catalogue filters', () {
    test('a valid status with no matching projects returns an empty list, '
        'not a 422', () async {
      // `handed_over` is a legitimate stage; filtering by it must work even
      // when the live catalogue happens to contain none.
      for (final status in kAllowedProjectStatuses) {
        final response = await handler(_get('/v1/projects?status=$status'));
        expect(
          response.statusCode,
          200,
          reason: 'status=$status should be accepted',
        );
      }
    });

    test('an unknown status is still rejected', () async {
      final response = await handler(_get('/v1/projects?status=bogus'));
      expect(response.statusCode, 422);
    });

    test('a district added after startup is filterable', () async {
      // The allow-list used to be snapshotted when the handler was built, so
      // anything created later was rejected as an "Invalid district".
      store.projects.add({
        ...Map<String, dynamic>.from(store.projects.first),
        'id': 'prj-late-district',
        'district': 'Zangiota',
        'isPublished': true,
        'moderationStatus': 'approved',
      });
      final response = await handler(_get('/v1/projects?district=zangiota'));
      expect(response.statusCode, 200);
      final json = await _decode(response);
      expect((json['data'] as List), isNotEmpty);
    });

    test('priceMax excludes projects that have no sale price at all', () async {
      final response = await handler(_get('/v1/projects?priceMax=100000000'));
      expect(response.statusCode, 200);
      final items = (await _decode(response))['data'] as List;
      for (final item in items.cast<Map<String, dynamic>>()) {
        expect(
          item['priceMin'] ?? item['priceMax'],
          isNotNull,
          reason: '${item['id']} has no sale price but matched a price filter',
        );
      }
    });

    test(
      'limit is capped so one request cannot pull the whole catalogue',
      () async {
        final response = await handler(_get('/v1/projects?limit=100000'));
        final json = await _decode(response);
        expect(json['meta']['limit'], kMaxPageLimit);
        expect((json['data'] as List).length, lessThanOrEqualTo(kMaxPageLimit));
      },
    );
  });

  group('reviews', () {
    test('out-of-range ratings are rejected', () async {
      final token = await _signIn(handler);
      final projectId = store.publishedProjects.first['id'] as String;
      final response = await handler(
        _post('/v1/projects/$projectId/reviews', {
          'body': 'Nice place',
          'ratingOverall': 99,
        }, token: token),
      );
      expect(response.statusCode, 422);
      expect((await _decode(response))['error']['code'], 'VALIDATION_ERROR');
    });

    test('a valid rating is accepted', () async {
      final token = await _signIn(handler);
      final projectId = store.publishedProjects.first['id'] as String;
      final response = await handler(
        _post('/v1/projects/$projectId/reviews', {
          'body': 'Nice place',
          'ratingOverall': 5,
        }, token: token),
      );
      expect(response.statusCode, 201);
    });

    test(
      'reviews of an unpublished project are not readable anonymously',
      () async {
        final project = store.publishedProjects.first;
        project['isPublished'] = false;
        final response = await handler(
          _get('/v1/projects/${project['id']}/reviews'),
        );
        expect(response.statusCode, 404);
      },
    );
  });

  group('static files', () {
    test('rejects traversal with both separator flavours', () async {
      for (final attempt in [
        '..%2Fpubspec.yaml',
        '..%5Cpubspec.yaml',
        '%2Fetc%2Fpasswd',
      ]) {
        final response = await handler(_get('/v1/static/uploads/$attempt'));
        expect(
          response.statusCode,
          anyOf(403, 404),
          reason: '$attempt must never be served',
        );
      }
    });
  });

  group('session lifetime', () {
    test('logout invalidates the paired refresh token too', () async {
      final send = await handler(
        _post('/v1/auth/otp/send', {'phone': '+998901234567'}),
      );
      final requestId = (await _decode(send))['data']['requestId'] as String;
      final verify = await handler(
        _post('/v1/auth/otp/verify', {
          'requestId': requestId,
          'code': '123456',
        }),
      );
      final tokens = (await _decode(verify))['data'] as Map<String, dynamic>;
      final accessToken = tokens['accessToken'] as String;
      final refreshToken = tokens['refreshToken'] as String;

      final loggedOut = await handler(
        _post('/v1/auth/logout', const {}, token: accessToken),
      );
      expect(loggedOut.statusCode, 200);

      // Before the fix the refresh token outlived logout and could mint a new
      // access token for the rest of its 30-day TTL.
      final refreshed = await handler(
        _post('/v1/auth/refresh', {'refreshToken': refreshToken}),
      );
      expect(refreshed.statusCode, 401);
    });

    test('rotated refresh tokens stay tied to the new access token', () async {
      final send = await handler(
        _post('/v1/auth/otp/send', {'phone': '+998901234567'}),
      );
      final requestId = (await _decode(send))['data']['requestId'] as String;
      final verify = await handler(
        _post('/v1/auth/otp/verify', {
          'requestId': requestId,
          'code': '123456',
        }),
      );
      final first = (await _decode(verify))['data'] as Map<String, dynamic>;

      final rotated = await handler(
        _post('/v1/auth/refresh', {'refreshToken': first['refreshToken']}),
      );
      final second = (await _decode(rotated))['data'] as Map<String, dynamic>;

      await handler(
        _post('/v1/auth/logout', const {}, token: second['accessToken']),
      );
      final reused = await handler(
        _post('/v1/auth/refresh', {'refreshToken': second['refreshToken']}),
      );
      expect(reused.statusCode, 401);
    });
  });

  group('developer verification', () {
    test('rejection takes back the residence_admin role', () async {
      final token = await _signIn(handler, phone: '+998901234567');
      final ownerId =
          (await _decode(
                await handler(_get('/v1/users/me', token: token)),
              ))['data']['id']
              as String;
      final developer = _registerDeveloper(store, ownerId);
      final id = developer['id'] as String;

      store.setDeveloperVerification(id, 'approved');
      final approved = store.allUsers().firstWhere((u) => u['id'] == ownerId);
      expect(approved['role'], 'residence_admin');

      store.setDeveloperVerification(id, 'rejected', rejectionReason: 'nope');
      final rejected = store.allUsers().firstWhere((u) => u['id'] == ownerId);
      // A rejected applicant kept full developer privileges before the fix.
      expect(rejected['role'], 'ordinary_user');
    });
  });

  group('KYC documents', () {
    test('are not reachable through the public static route', () async {
      final response = await handler(_get('/v1/static/uploads/private'));
      expect(response.statusCode, anyOf(403, 404));
    });

    test('the authenticated route rejects anonymous callers', () async {
      final response = await handler(_get('/v1/documents/whatever.pdf'));
      expect(response.statusCode, 401);
    });

    test(
      'a signed-in non-owner cannot read someone else\'s document',
      () async {
        final ownerToken = await _signIn(handler, phone: '+998901234567');
        final ownerId =
            (await _decode(
                  await handler(_get('/v1/users/me', token: ownerToken)),
                ))['data']['id']
                as String;
        final developer = _registerDeveloper(store, ownerId);
        final doc = store.addDocument(
          developerId: developer['id'] as String,
          type: 'passport',
          fileUrl: '/v1/documents/secret.pdf',
          uploadedBy: ownerId,
        );
        expect(doc['fileUrl'], '/v1/documents/secret.pdf');

        final token = await _signIn(handler, phone: '+998907654321');
        final response = await handler(
          _get('/v1/documents/secret.pdf', token: token),
        );
        expect(response.statusCode, anyOf(403, 404));
      },
    );
  });

  group('upload filenames', () {
    test('only known extensions survive sanitisation', () {
      expect(safeExtension('scan.pdf'), 'pdf');
      expect(safeExtension('photo.JPEG'), 'jpeg');
      // Anything we do not recognise — including traversal attempts smuggled
      // through the extension — is stored as an inert .bin.
      expect(safeExtension('shell.php'), 'bin');
      expect(safeExtension('a.../../../etc/passwd'), 'bin');
      expect(safeExtension('noextension'), 'bin');
      expect(safeExtension(null), 'bin');
    });
  });

  group('subscription plan caps', () {
    test('the tier\'s maxProjects allowance is enforced on publish', () async {
      final token = await _signIn(handler, phone: '+998901234567');
      final ownerId =
          (await _decode(
                await handler(_get('/v1/users/me', token: token)),
              ))['data']['id']
              as String;
      final developer = _registerDeveloper(store, ownerId);
      final developerId = developer['id'] as String;
      store.setDeveloperVerification(developerId, 'approved');
      store.activateSubscription(ownerId, planId: 'start');

      final maxProjects =
          store.planForDeveloper(developerId)['maxProjects'] as int;
      expect(maxProjects, greaterThan(0));

      // Fill the allowance exactly.
      final ids = <String>[];
      for (var i = 0; i <= maxProjects; i++) {
        final project = store.createProjectForOwner(
          ownerUserId: ownerId,
          input: {
            'name': 'Project $i',
            'district': 'Yunusobod',
            'address': 'Somewhere $i',
          },
        );
        ids.add(project!['id'] as String);
      }
      for (var i = 0; i < maxProjects; i++) {
        store.updateProject(ids[i], {'isPublished': true});
      }
      expect(store.publishedProjectCount(developerId), maxProjects);

      // One more must be refused rather than silently allowed.
      expect(
        () => store.updateProject(ids[maxProjects], {'isPublished': true}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'PROJECT_LIMIT_REACHED',
          ),
        ),
      );
    });

    test(
      're-publishing an already-live project does not trip its own limit',
      () async {
        final token = await _signIn(handler, phone: '+998901234567');
        final ownerId =
            (await _decode(
                  await handler(_get('/v1/users/me', token: token)),
                ))['data']['id']
                as String;
        final developer = _registerDeveloper(store, ownerId);
        final developerId = developer['id'] as String;
        store.setDeveloperVerification(developerId, 'approved');
        store.activateSubscription(ownerId, planId: 'start');

        final maxProjects =
            store.planForDeveloper(developerId)['maxProjects'] as int;
        final ids = <String>[];
        for (var i = 0; i < maxProjects; i++) {
          final project = store.createProjectForOwner(
            ownerUserId: ownerId,
            input: {
              'name': 'Project $i',
              'district': 'Yunusobod',
              'address': 'Somewhere $i',
            },
          );
          ids.add(project!['id'] as String);
          store.updateProject(ids[i], {'isPublished': true});
        }
        // At the cap, but this one is already counted — it must still succeed.
        expect(
          () => store.updateProject(ids.last, {'isPublished': true}),
          returnsNormally,
        );
      },
    );
  });

  group('calculators', () {
    test(
      'an absurd term is rejected instead of pinning the isolate',
      () async {
        final response = await handler(
          _post('/v1/calculators/mortgage', {
            'price': 1000000000,
            'downPaymentPercent': 0.2,
            'termYears': 2000000000,
            'annualRatePercent': 12,
          }),
        );
        expect(response.statusCode, 422);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test('a realistic term still quotes', () async {
      final response = await handler(
        _post('/v1/calculators/mortgage', {
          'price': 1000000000,
          'downPaymentPercent': 0.2,
          'termYears': 20,
          'annualRatePercent': 12,
        }),
      );
      expect(response.statusCode, 200);
      final quote = (await _decode(response))['data'] as Map<String, dynamic>;
      expect(quote['termMonths'], 240);
      expect(quote['monthlyPayment'], greaterThan(0));
    });
  });

  group('RateLimiter memory bounds', () {
    test('evicts keys instead of growing without limit', () {
      final limiter = RateLimiter(
        1,
        const Duration(milliseconds: 1),
        maxTrackedKeys: 50,
      );
      for (var i = 0; i < 5000; i++) {
        limiter.allow('key-$i');
      }
      // Exact size depends on eviction timing; the invariant is that it stays
      // bounded rather than holding all 5000 keys.
      expect(limiter.debugTrackedKeyCount, lessThanOrEqualTo(50));
    });
  });

  group('clientKeyFor', () {
    test('ignores X-Forwarded-For unless TRUST_PROXY is enabled', () {
      // Default env in tests has no TRUST_PROXY, so a spoofed header must not
      // become the rate-limit bucket.
      final request = Request(
        'POST',
        Uri.parse('http://localhost/v1/auth/otp/send'),
        headers: {'x-forwarded-for': '1.2.3.4'},
      );
      expect(trustProxyHeaders, isFalse);
      expect(clientKeyFor(request), isNot('1.2.3.4'));
    });
  });
}
