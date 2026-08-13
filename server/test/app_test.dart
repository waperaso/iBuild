import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../lib/src/app.dart';
import '../lib/src/rate_limiter.dart';
import '../lib/src/store.dart';
import 'test_fixtures.dart';

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

Future<String> _signIn(
  Handler handler, {
  String phone = '+998901234567',
}) async {
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
  group('PATCH /v1/leads/:id/status', () {
    late Store store;
    late Handler handler;
    late String token;

    setUp(() async {
      store = createTestStore();
      handler = createHandler(store);
      token = await _signIn(handler);
    });

    tearDown(() => store.dispose());

    test('updates an existing lead and returns the envelope', () async {
      final leadId = store.leads.first['id'] as String;
      // Seed leads have no userId — promote caller to system admin via store.
      store.ensureUser(phone: '+998901234567', role: 'system_admin');
      token = await _signIn(handler);
      final response = await handler(
        _patch('/v1/leads/$leadId/status', {
          'status': 'contacted',
        }, token: token),
      );
      expect(response.statusCode, 200);
      final json = await _decode(response);
      expect(json['success'], isTrue);
      expect(json['data']['id'], leadId);
      expect(json['data']['status'], 'contacted');
    });

    test('rejects an unknown status with 422', () async {
      final leadId = store.leads.first['id'] as String;
      store.ensureUser(phone: '+998901234567', role: 'system_admin');
      token = await _signIn(handler);
      final response = await handler(
        _patch('/v1/leads/$leadId/status', {'status': 'bogus'}, token: token),
      );
      expect(response.statusCode, 422);
      final json = await _decode(response);
      expect(json['success'], isFalse);
    });

    test('returns 404 for an unknown lead id', () async {
      store.ensureUser(phone: '+998901234567', role: 'system_admin');
      token = await _signIn(handler);
      final response = await handler(
        _patch('/v1/leads/does-not-exist/status', {
          'status': 'won',
        }, token: token),
      );
      expect(response.statusCode, 404);
    });
  });

  group('GET /v1/projects query validation', () {
    late Store store;
    late Handler handler;

    setUp(() {
      store = createTestStore();
      handler = createHandler(store);
    });

    tearDown(() => store.dispose());

    test('rejects an invalid status with 422', () async {
      final response = await handler(_get('/v1/projects?status=bogus'));
      expect(response.statusCode, 422);
    });

    test('rejects an invalid mode with 422', () async {
      final response = await handler(_get('/v1/projects?mode=bogus'));
      expect(response.statusCode, 422);
    });

    test('accepts a valid status and still returns projects', () async {
      final response = await handler(_get('/v1/projects?status=ready'));
      expect(response.statusCode, 200);
      final json = await _decode(response);
      expect((json['data'] as List).isNotEmpty, isTrue);
    });

    test(
      'mode=rent includes residential complexes with rent units, not just business centres',
      () async {
        final response = await handler(
          _get('/v1/projects?mode=rent&limit=100'),
        );
        expect(response.statusCode, 200);
        final json = await _decode(response);
        final items = (json['data'] as List).cast<Map<String, dynamic>>();
        expect(items.isNotEmpty, isTrue);
        // Konseptsiya §5: rent must span every segment (ЖК/БЦ/стрит-ритейл),
        // not be gated to business_centre the way the original bug did.
        expect(
          items.any((p) => p['type'] == 'residential_complex'),
          isTrue,
          reason: 'rent mode must surface residential rental inventory',
        );
        for (final p in items) {
          expect(p['rentMin'] != null || p['rentMax'] != null, isTrue);
        }
      },
    );

    test(
      'mode=buy only returns projects with sale inventory (developer-primary rule)',
      () async {
        final response = await handler(_get('/v1/projects?mode=buy&limit=100'));
        expect(response.statusCode, 200);
        final json = await _decode(response);
        final items = (json['data'] as List).cast<Map<String, dynamic>>();
        for (final p in items) {
          expect(p['priceMin'] != null || p['priceMax'] != null, isTrue);
        }
      },
    );
  });

  group('calculators', () {
    late Store store;
    late Handler handler;

    setUp(() {
      store = createTestStore();
      handler = createHandler(store);
    });

    tearDown(() => store.dispose());

    test(
      'POST /v1/calculators/mortgage returns a positive monthly payment',
      () async {
        final response = await handler(
          _post('/v1/calculators/mortgage', {
            'price': 50000,
            'downPaymentPercent': 0.2,
            'termYears': 10,
            'annualRatePercent': 18,
          }),
        );
        expect(response.statusCode, 200);
        final json = await _decode(response);
        final data = json['data'] as Map<String, dynamic>;
        expect(data['loanAmount'], 40000);
        expect((data['monthlyPayment'] as num) > 0, isTrue);
      },
    );

    test('POST /v1/calculators/rental-yield computes gross yield', () async {
      final response = await handler(
        _post('/v1/calculators/rental-yield', {
          'price': 60000,
          'monthlyRent': 500,
        }),
      );
      expect(response.statusCode, 200);
      final json = await _decode(response);
      final data = json['data'] as Map<String, dynamic>;
      expect(data['annualRent'], 6000);
      expect(data['grossYieldPercent'], closeTo(10.0, 0.01));
    });
  });

  group('rental listings (owner secondary/primary rent)', () {
    late Store store;
    late Handler handler;
    late String token;

    setUp(() async {
      store = createTestStore();
      handler = createHandler(store);
      token = await _signIn(handler);
    });

    tearDown(() => store.dispose());

    test(
      'owner can submit a listing and it stays hidden until approved',
      () async {
        final create = await handler(
          _post('/v1/rental-listings', {
            'title': 'Sunny 1-room flat',
            'description': 'Near the metro, freshly renovated.',
            'district': 'Yunusabad',
            'address': 'Test st. 1',
            'propertyKind': 'apartment',
            'contactPhone': '+998901112233',
            'rentMonthly': 250,
            'areaTotal': 40,
          }, token: token),
        );
        expect(create.statusCode, 201);
        final created = await _decode(create);
        final id = created['data']['id'] as String;
        expect(created['data']['dealType'], 'rent');
        expect(created['data']['moderationStatus'], 'pending');

        final publicList = await handler(_get('/v1/rental-listings'));
        final publicJson = await _decode(publicList);
        final publicIds = (publicJson['data'] as List)
            .map((l) => l['id'])
            .toList();
        expect(publicIds.contains(id), isFalse);

        store.moderateRentalListing(id, approve: true);
        final afterApproval = await handler(_get('/v1/rental-listings'));
        final afterJson = await _decode(afterApproval);
        final afterIds = (afterJson['data'] as List)
            .map((l) => l['id'])
            .toList();
        expect(afterIds.contains(id), isTrue);
      },
    );
  });

  group('offers include installment fields', () {
    late Store store;
    late Handler handler;

    setUp(() {
      store = createTestStore();
      handler = createHandler(store);
    });

    tearDown(() => store.dispose());

    test(
      'installment offers expose downPaymentPercent/termMonths/interestRate',
      () async {
        final project = store.projects.firstWhere(
          (p) => p['name'] == testResidentialName,
        );
        final response = await handler(
          _get('/v1/projects/${project['id']}/offers'),
        );
        final json = await _decode(response);
        final offers = (json['data'] as List).cast<Map<String, dynamic>>();
        final installment = offers.firstWhere(
          (o) => o['type'] == 'installment',
        );
        expect(installment['downPaymentPercent'], 0.3);
        expect(installment['termMonths'], 24);
        expect(installment['interestRate'], 0.0);
      },
    );

    test('discount offers leave the installment fields null', () async {
      final project = store.projects.firstWhere(
        (p) => p['name'] == testResidentialName,
      );
      final response = await handler(
        _get('/v1/projects/${project['id']}/offers'),
      );
      final json = await _decode(response);
      final offers = (json['data'] as List).cast<Map<String, dynamic>>();
      final discount = offers.firstWhere((o) => o['type'] == 'discount');
      expect(discount['downPaymentPercent'], isNull);
      expect(discount['termMonths'], isNull);
      expect(discount['interestRate'], isNull);
    });
  });

  group('platform admin: offers, lead tags/score, audit log', () {
    late Store store;
    late Handler handler;
    late String adminToken;

    setUp(() async {
      store = createTestStore();
      handler = createHandler(store);
      store.ensureUser(phone: '+998901234567', role: 'system_admin');
      adminToken = await _signIn(handler);
    });

    tearDown(() => store.dispose());

    test('PUT /v1/admin/projects/:id/offers replaces the offer list', () async {
      final projectId = store.projects.first['id'] as String;
      final response = await handler(
        _put('/v1/admin/projects/$projectId/offers', {
          'offers': [
            {'type': 'discount', 'title': '10% early-bird discount'},
          ],
        }, token: adminToken),
      );
      expect(response.statusCode, 200);

      final read = await handler(
        _get('/v1/admin/projects/$projectId/offers', token: adminToken),
      );
      final json = await _decode(read);
      final offers = (json['data'] as List).cast<Map<String, dynamic>>();
      expect(offers.length, 1);
      expect(offers.single['title'], '10% early-bird discount');
    });

    test('PUT offers rejects an unknown offer type with 422', () async {
      final projectId = store.projects.first['id'] as String;
      final response = await handler(
        _put('/v1/admin/projects/$projectId/offers', {
          'offers': [
            {'type': 'bogus', 'title': 'x'},
          ],
        }, token: adminToken),
      );
      expect(response.statusCode, 422);
    });

    test(
      'GET /v1/admin/projects/:id/analytics returns funnel + unit stats',
      () async {
        final projectId = store.projects.first['id'] as String;
        final response = await handler(
          _get('/v1/admin/projects/$projectId/analytics', token: adminToken),
        );
        expect(response.statusCode, 200);
        final json = await _decode(response);
        expect(json['data']['projectId'], projectId);
        expect(json['data']['unitsByStatus'], isNotNull);
        expect(json['data']['leadFunnel'], isNotNull);
      },
    );

    test('PATCH /v1/admin/leads/:id sets tags and score', () async {
      final leadId = store.leads.first['id'] as String;
      final response = await handler(
        _patch('/v1/admin/leads/$leadId', {
          'tags': ['vip', 'mortgage'],
          'score': 'hot',
        }, token: adminToken),
      );
      expect(response.statusCode, 200);
      final json = await _decode(response);
      expect(json['data']['tags'], ['vip', 'mortgage']);
      expect(json['data']['score'], 'hot');
    });

    test(
      'PATCH /v1/admin/leads/:id rejects an invalid score with 422',
      () async {
        final leadId = store.leads.first['id'] as String;
        final response = await handler(
          _patch('/v1/admin/leads/$leadId', {
            'score': 'bogus',
          }, token: adminToken),
        );
        expect(response.statusCode, 422);
      },
    );

    test('GET /v1/platform/audit-log requires system admin', () async {
      final userToken = await _signIn(handler, phone: '+998907654321');
      final response = await handler(
        _get('/v1/platform/audit-log', token: userToken),
      );
      expect(response.statusCode, 403);
    });

    test('GET /v1/platform/audit-log records moderation actions', () async {
      final developer = store.registerDeveloper(
        ownerUserId: 'usr-test-owner',
        name: 'Test Devco',
        legalName: 'OOO Test Devco',
        inn: '301234567',
        phone: '+998907001122',
        accountKind: 'llc',
        legalForm: 'ooo',
        legalAddress: 'Tashkent, Yunusabad',
        directorFullName: 'Test Director',
        directorPinfl: '30101123456789',
        uboDeclared: true,
      );
      for (final type in kRequiredDocumentTypes) {
        final doc = store.addDocument(
          developerId: developer['id'] as String,
          type: type,
          fileUrl: '/v1/static/uploads/$type.pdf',
          uploadedBy: 'usr-test-owner',
        );
        store.reviewDocument(
          doc['id'] as String,
          status: 'accepted',
          reviewedBy: 'usr-admin',
        );
      }
      final approve = await handler(
        _patch(
          '/v1/platform/developers/${developer['id']}/approve',
          const {},
          token: adminToken,
        ),
      );
      expect(approve.statusCode, 200);
      final response = await handler(
        _get('/v1/platform/audit-log', token: adminToken),
      );
      expect(response.statusCode, 200);
      final json = await _decode(response);
      final items = (json['data'] as List).cast<Map<String, dynamic>>();
      expect(items.any((e) => e['action'] == 'developer.approve'), isTrue);
    });

    test('GET /v1/subscription-plans lists Start/Growth/Corporate', () async {
      final response = await handler(_get('/v1/subscription-plans'));
      expect(response.statusCode, 200);
      final json = await _decode(response);
      final ids = (json['data'] as List).map((p) => p['id']).toList();
      expect(ids, containsAll(['start', 'growth', 'corporate']));
    });

    test('PATCH /v1/platform/developers/:id/status walks pending -> in_review '
        '-> rejected, then a resubmission restarts at pending', () async {
      final developer = store.registerDeveloper(
        ownerUserId: 'usr-status-pipeline',
        name: 'Pipeline Devco',
        legalName: 'OOO Pipeline Devco',
        inn: '301234568',
        phone: '+998907001133',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent, Yunusabad',
        directorFullName: 'Pipeline Director',
        directorPinfl: '30101123456790',
        uboDeclared: true,
      );
      final id = developer['id'] as String;
      expect(developer['verificationStatus'], 'draft');
      final submitted = store.submitDeveloperForReview('usr-status-pipeline');
      expect(submitted!['verificationStatus'], 'pending');

      final review = await handler(
        _patch('/v1/platform/developers/$id/status', {
          'status': 'in_review',
        }, token: adminToken),
      );
      expect(review.statusCode, 200);
      final reviewJson = await _decode(review);
      expect(reviewJson['data']['verificationStatus'], 'in_review');

      final decline = await handler(
        _patch('/v1/platform/developers/$id/status', {
          'status': 'rejected',
          'reason': 'Missing construction license',
        }, token: adminToken),
      );
      expect(decline.statusCode, 200);
      final declineJson = await _decode(decline);
      expect(declineJson['data']['verificationStatus'], 'rejected');
      expect(
        declineJson['data']['rejectionReason'],
        'Missing construction license',
      );

      // Resubmission with corrected data restarts the pipeline.
      final resubmitted = store.registerDeveloper(
        ownerUserId: 'usr-status-pipeline',
        name: 'Pipeline Devco',
        legalName: 'OOO Pipeline Devco',
        inn: '301234568',
        phone: '+998907001133',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent, Yunusabad 2',
        directorFullName: 'Pipeline Director',
        directorPinfl: '30101123456790',
        uboDeclared: true,
        constructionLicense: 'LIC-0042',
      );
      expect(resubmitted['verificationStatus'], 'draft');
      expect(resubmitted['constructionLicense'], 'LIC-0042');
      final resubmittedPending = store.submitDeveloperForReview(
        'usr-status-pipeline',
      );
      expect(resubmittedPending!['verificationStatus'], 'pending');
    });

    test(
      'PATCH /v1/platform/developers/:id/status requires a reason to reject',
      () async {
        final developer = store.registerDeveloper(
          ownerUserId: 'usr-status-noreason',
          name: 'NoReason Devco',
          legalName: 'OOO NoReason Devco',
          inn: '301234569',
          phone: '+998907001144',
          accountKind: 'property_developer',
          legalForm: 'ooo',
          legalAddress: 'Tashkent, Chilanzar',
          directorFullName: 'NoReason Director',
          directorPinfl: '30101123456791',
          uboDeclared: true,
        );
        final response = await handler(
          _patch('/v1/platform/developers/${developer['id']}/status', {
            'status': 'rejected',
          }, token: adminToken),
        );
        expect(response.statusCode, 422);
      },
    );

    test(
      'PATCH /v1/platform/developers/:id/status refuses to approve a '
      'developer whose required documents are not all accepted '
      '(the /status shortcut must not bypass the /approve document gate)',
      () async {
        final developer = store.registerDeveloper(
          ownerUserId: 'usr-status-nodocs',
          name: 'NoDocs Devco',
          legalName: 'OOO NoDocs Devco',
          inn: '301234573',
          phone: '+998907001188',
          accountKind: 'property_developer',
          legalForm: 'ooo',
          legalAddress: 'Tashkent',
          directorFullName: 'NoDocs Director',
          directorPinfl: '30101123456795',
          uboDeclared: true,
        );
        final id = developer['id'] as String;
        final response = await handler(
          _patch('/v1/platform/developers/$id/status', {
            'status': 'approved',
          }, token: adminToken),
        );
        expect(response.statusCode, 422);
        expect(
          store.developerById(id)!['verificationStatus'],
          isNot('approved'),
        );

        for (final type in kRequiredDocumentTypes) {
          final doc = store.addDocument(
            developerId: id,
            type: type,
            fileUrl: '/v1/static/uploads/$type.pdf',
            uploadedBy: 'usr-status-nodocs',
          );
          store.reviewDocument(
            doc['id'] as String,
            status: 'accepted',
            reviewedBy: 'usr-admin',
          );
        }
        final approve = await handler(
          _patch('/v1/platform/developers/$id/status', {
            'status': 'approved',
          }, token: adminToken),
        );
        expect(approve.statusCode, 200);
        final approveJson = await _decode(approve);
        expect(approveJson['data']['verificationStatus'], 'approved');
      },
    );

    test(
      'PATCH /v1/platform/developers/:id/status rejects an unknown status',
      () async {
        final developer = store.registerDeveloper(
          ownerUserId: 'usr-status-bogus',
          name: 'Bogus Devco',
          legalName: 'OOO Bogus Devco',
          inn: '301234570',
          phone: '+998907001155',
          accountKind: 'property_developer',
          legalForm: 'ooo',
          legalAddress: 'Tashkent, Mirzo Ulugbek',
          directorFullName: 'Bogus Director',
          directorPinfl: '30101123456792',
          uboDeclared: true,
        );
        final response = await handler(
          _patch('/v1/platform/developers/${developer['id']}/status', {
            'status': 'bogus',
          }, token: adminToken),
        );
        expect(response.statusCode, 422);
      },
    );

    test('GET /v1/platform/developers/pending includes both pending and '
        'in_review applications', () async {
      final a = store.registerDeveloper(
        ownerUserId: 'usr-pending-a',
        name: 'Pending A',
        legalName: 'OOO Pending A',
        inn: '301234571',
        phone: '+998907001166',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent',
        directorFullName: 'Director A',
        directorPinfl: '30101123456793',
        uboDeclared: true,
      );
      store.submitDeveloperForReview('usr-pending-a');
      final b = store.registerDeveloper(
        ownerUserId: 'usr-pending-b',
        name: 'Pending B',
        legalName: 'OOO Pending B',
        inn: '301234572',
        phone: '+998907001177',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent',
        directorFullName: 'Director B',
        directorPinfl: '30101123456794',
        uboDeclared: true,
      );
      store.submitDeveloperForReview('usr-pending-b');
      await handler(
        _patch('/v1/platform/developers/${b['id']}/status', {
          'status': 'in_review',
        }, token: adminToken),
      );
      final response = await handler(
        _get('/v1/platform/developers/pending', token: adminToken),
      );
      expect(response.statusCode, 200);
      final json = await _decode(response);
      final ids = (json['data'] as List).map((d) => d['id']).toList();
      expect(ids, containsAll([a['id'], b['id']]));
    });
  });

  group('account bans', () {
    late Store store;
    late Handler handler;
    late String adminToken;
    late String userToken;
    late String userId;

    setUp(() async {
      store = createTestStore();
      handler = createHandler(store);
      store.ensureUser(phone: '+998901234567', role: 'system_admin');
      adminToken = await _signIn(handler);
      userToken = await _signIn(handler, phone: '+998907654321');
      final me = await _decode(
        await handler(_get('/v1/users/me', token: userToken)),
      );
      userId = me['data']['id'] as String;
    });

    tearDown(() => store.dispose());

    test('PATCH .../ban requires a reason and a bannedByName', () async {
      final missingReason = await handler(
        _patch('/v1/platform/users/$userId/ban', {
          'bannedByName': 'Aziz Karimov',
        }, token: adminToken),
      );
      expect(missingReason.statusCode, 422);

      final missingName = await handler(
        _patch('/v1/platform/users/$userId/ban', {
          'reason': 'Spam leads',
        }, token: adminToken),
      );
      expect(missingName.statusCode, 422);
    });

    test('PATCH .../ban requires system admin', () async {
      final response = await handler(
        _patch('/v1/platform/users/$userId/ban', {
          'reason': 'Spam leads',
          'bannedByName': 'Aziz Karimov',
        }, token: userToken),
      );
      expect(response.statusCode, 403);
    });

    test('banning a user records the reason/name and blocks their actions, '
        'but GET /v1/users/me and logout still work', () async {
      final ban = await handler(
        _patch('/v1/platform/users/$userId/ban', {
          'reason': 'Spam leads',
          'bannedByName': 'Aziz Karimov',
        }, token: adminToken),
      );
      expect(ban.statusCode, 200);
      final banJson = await _decode(ban);
      expect(banJson['data']['banned'], isTrue);
      expect(banJson['data']['banReason'], 'Spam leads');
      expect(banJson['data']['bannedByName'], 'Aziz Karimov');

      // The banned account can still see *why* on its own profile.
      final me = await handler(_get('/v1/users/me', token: userToken));
      expect(me.statusCode, 200);
      final meJson = await _decode(me);
      expect(meJson['data']['banned'], isTrue);
      expect(meJson['data']['banReason'], 'Spam leads');
      expect(meJson['data']['bannedByName'], 'Aziz Karimov');

      // Every other authenticated action is rejected while still signed in.
      final favorites = await handler(
        _get('/v1/users/me/favorites', token: userToken),
      );
      expect(favorites.statusCode, 403);
      final favoritesJson = await _decode(favorites);
      expect(favoritesJson['error']['code'], 'ACCOUNT_BANNED');
      expect(favoritesJson['error']['message'], contains('Aziz Karimov'));
      expect(favoritesJson['error']['message'], contains('Spam leads'));

      // ...but the banned account can still sign out with its live token.
      final logout = await handler(
        _post('/v1/auth/logout', const {}, token: userToken),
      );
      expect(logout.statusCode, 200);

      final auditLog = await handler(
        _get('/v1/platform/audit-log', token: adminToken),
      );
      final auditJson = await _decode(auditLog);
      final items = (auditJson['data'] as List).cast<Map<String, dynamic>>();
      expect(items.any((e) => e['action'] == 'user.ban'), isTrue);
    });

    test('unbanning restores normal access', () async {
      await handler(
        _patch('/v1/platform/users/$userId/ban', {
          'reason': 'Spam leads',
          'bannedByName': 'Aziz Karimov',
        }, token: adminToken),
      );

      final unban = await handler(
        _patch('/v1/platform/users/$userId/unban', const {}, token: adminToken),
      );
      expect(unban.statusCode, 200);
      final unbanJson = await _decode(unban);
      expect(unbanJson['data']['banned'], isFalse);

      final favorites = await handler(
        _get('/v1/users/me/favorites', token: userToken),
      );
      expect(favorites.statusCode, 200);
    });
  });

  group('platform admin account deletion', () {
    late Store store;
    late Handler handler;
    late String adminToken;
    late String secondAdminId;
    late String secondAdminToken;

    setUp(() async {
      store = createTestStore();
      handler = createHandler(store);
      store.ensureUser(phone: '+998901234567', role: 'system_admin');
      adminToken = await _signIn(handler);
      final second = store.ensureUser(
        phone: '+998907654321',
        role: 'system_admin',
      );
      secondAdminId = second['id'] as String;
      secondAdminToken = await _signIn(handler, phone: '+998907654321');
    });

    tearDown(() => store.dispose());

    test('DELETE requires system admin', () async {
      final ordinaryToken = await _signIn(handler, phone: '+998909998877');
      final response = await handler(
        _delete('/v1/platform/users/$secondAdminId', token: ordinaryToken),
      );
      expect(response.statusCode, 403);
    });

    test('DELETE refuses to remove a non-admin account', () async {
      final ordinaryToken = await _signIn(handler, phone: '+998909998877');
      final me = await _decode(
        await handler(_get('/v1/users/me', token: ordinaryToken)),
      );
      final ordinaryId = me['data']['id'] as String;
      final response = await handler(
        _delete('/v1/platform/users/$ordinaryId', token: adminToken),
      );
      expect(response.statusCode, 422);
    });

    test('DELETE refuses to remove your own account', () async {
      final me = await _decode(
        await handler(_get('/v1/users/me', token: adminToken)),
      );
      final selfId = me['data']['id'] as String;
      final response = await handler(
        _delete('/v1/platform/users/$selfId', token: adminToken),
      );
      expect(response.statusCode, 422);
    });

    test('DELETE 404s for an unknown user id', () async {
      final response = await handler(
        _delete('/v1/platform/users/does-not-exist', token: adminToken),
      );
      expect(response.statusCode, 404);
    });

    test('deleting another platform admin removes the account, revokes their '
        'session, and is logged', () async {
      final countBefore = store.systemAdminCount();

      final response = await handler(
        _delete('/v1/platform/users/$secondAdminId', token: adminToken),
      );
      expect(response.statusCode, 200);
      final json = await _decode(response);
      expect(json['data']['deleted'], isTrue);

      // The deleted admin's own (still-live) token no longer resolves.
      final me = await handler(_get('/v1/users/me', token: secondAdminToken));
      expect(me.statusCode, 401);

      final users = await _decode(
        await handler(_get('/v1/platform/users', token: adminToken)),
      );
      final ids = (users['data'] as List).map((u) => u['id']).toList();
      expect(ids, isNot(contains(secondAdminId)));
      expect(store.systemAdminCount(), countBefore - 1);

      final auditLog = await _decode(
        await handler(_get('/v1/platform/audit-log', token: adminToken)),
      );
      final items = (auditLog['data'] as List).cast<Map<String, dynamic>>();
      expect(items.any((e) => e['action'] == 'user.delete'), isTrue);
    });
  });

  group('rate limiting', () {
    late Store store;

    setUp(() {
      store = createTestStore();
    });

    tearDown(() => store.dispose());

    test(
      'POST /v1/leads returns 429 with Retry-After once exhausted',
      () async {
        final handler = createHandler(
          store,
          leadsLimiter: RateLimiter(2, const Duration(minutes: 1)),
        );
        final token = await _signIn(handler);
        final body = {
          'projectId': store.projects.first['id'],
          'intent': 'callback',
          'consent': true,
        };

        final r1 = await handler(_post('/v1/leads', body, token: token));
        final r2 = await handler(_post('/v1/leads', body, token: token));
        final r3 = await handler(_post('/v1/leads', body, token: token));

        expect(r1.statusCode, 201);
        expect(r2.statusCode, 201);
        expect(r3.statusCode, 429);
        expect(r3.headers['Retry-After'], isNotNull);
      },
    );

    test('POST /v1/auth/otp/send returns 429 once exhausted', () async {
      final handler = createHandler(
        store,
        otpLimiter: RateLimiter(1, const Duration(minutes: 5)),
      );
      final body = {'phone': '+998901234567'};

      final r1 = await handler(_post('/v1/auth/otp/send', body));
      final r2 = await handler(_post('/v1/auth/otp/send', body));

      expect(r1.statusCode, 200);
      expect(r2.statusCode, 429);
      expect(r2.headers['Retry-After'], isNotNull);
    });
  });

  group('validation on lead/otp bodies', () {
    late Store store;
    late Handler handler;

    setUp(() {
      store = createTestStore();
      handler = createHandler(store);
    });

    tearDown(() => store.dispose());

    test('POST /v1/leads rejects an invalid contactPhone', () async {
      final token = await _signIn(handler);
      final response = await handler(
        _post('/v1/leads', {
          'projectId': store.projects.first['id'],
          'intent': 'callback',
          'consent': true,
          'contactPhone': 'not-a-phone',
        }, token: token),
      );
      expect(response.statusCode, 422);
    });

    test('POST /v1/leads rejects a submission without consent', () async {
      final token = await _signIn(handler);
      final response = await handler(
        _post('/v1/leads', {
          'projectId': store.projects.first['id'],
          'intent': 'callback',
        }, token: token),
      );
      expect(response.statusCode, 422);
    });

    test('POST /v1/leads requires auth', () async {
      final response = await handler(
        _post('/v1/leads', {
          'projectId': store.projects.first['id'],
          'intent': 'callback',
          'consent': true,
        }),
      );
      expect(response.statusCode, 401);
    });

    test('POST /v1/auth/otp/send rejects a malformed phone', () async {
      final response = await handler(
        _post('/v1/auth/otp/send', {'phone': 'abc'}),
      );
      expect(response.statusCode, 422);
    });

    test('platform admin phone with spaces signs in as system_admin', () async {
      final send = await handler(
        _post('/v1/auth/otp/send', {'phone': '+998 90 330 64 16'}),
      );
      expect(send.statusCode, 200);
      final sendJson = await _decode(send);
      final verify = await handler(
        _post('/v1/auth/otp/verify', {
          'requestId': sendJson['data']['requestId'],
          'code': '123456',
        }),
      );
      expect(verify.statusCode, 200);
      final verifyJson = await _decode(verify);
      expect(verifyJson['data']['user']['phone'], '+998903306416');
      expect(verifyJson['data']['user']['role'], 'system_admin');
    });
  });

  group('admin menu redesign: no admin-owned projects, tickets, CRM', () {
    late Store store;
    late Handler handler;

    setUp(() {
      store = createTestStore();
      handler = createHandler(store);
    });

    tearDown(() => store.dispose());

    test(
      'system admin can no longer create a ЖК project of their own',
      () async {
        store.ensureUser(phone: '+998901234567', role: 'system_admin');
        final token = await _signIn(handler);
        final response = await handler(
          _post('/v1/developers/me/projects', {
            'name': 'Admin Own Project',
          }, token: token),
        );
        expect(response.statusCode, 403);
      },
    );

    test(
      'residence admin without an approved developer profile is still blocked, '
      'but for a different reason than a system admin',
      () async {
        store.ensureUser(phone: '+998901234567', role: 'residence_admin');
        final token = await _signIn(handler);
        final response = await handler(
          _post('/v1/developers/me/projects', {
            'name': 'My Project',
          }, token: token),
        );
        expect(response.statusCode, 403);
        final json = await _decode(response);
        expect(json['error']['message'], contains('developer profile'));
      },
    );

    test(
      'GET /v1/platform/projects lists every ЖК regardless of status for oversight',
      () async {
        store.ensureUser(phone: '+998901234567', role: 'system_admin');
        final token = await _signIn(handler);
        final response = await handler(
          _get('/v1/platform/projects', token: token),
        );
        expect(response.statusCode, 200);
        final json = await _decode(response);
        expect(json['meta']['total'], store.projects.length);
      },
    );

    test('GET /v1/platform/leads exposes the platform-wide CRM', () async {
      store.ensureUser(phone: '+998901234567', role: 'system_admin');
      final token = await _signIn(handler);
      final response = await handler(_get('/v1/platform/leads', token: token));
      expect(response.statusCode, 200);
      final json = await _decode(response);
      expect(json['meta']['total'], store.leads.length);
    });

    test(
      'a user can open a support ticket and a system admin can triage it',
      () async {
        final userToken = await _signIn(handler, phone: '+998907654321');
        final created = await handler(
          _post('/v1/support/tickets', {
            'subject': 'Billing question',
            'message': 'Why was I charged twice?',
            'category': 'billing',
          }, token: userToken),
        );
        expect(created.statusCode, 201);
        final ticketId = (await _decode(created))['data']['id'] as String;

        // The ticket owner sees it in their own list.
        final mine = await _decode(
          await handler(_get('/v1/users/me/tickets', token: userToken)),
        );
        expect(mine['data'].length, 1);

        // A different, non-admin user cannot see or reply to someone else's ticket.
        final otherToken = await _signIn(handler, phone: '+998901112233');
        final forbiddenReply = await handler(
          _post('/v1/support/tickets/$ticketId/replies', {
            'message': 'nope',
          }, token: otherToken),
        );
        expect(forbiddenReply.statusCode, 403);

        store.ensureUser(phone: '+998901234567', role: 'system_admin');
        final adminToken = await _signIn(handler);

        final list = await _decode(
          await handler(_get('/v1/platform/tickets', token: adminToken)),
        );
        expect(list['data'].length, 1);

        final replied = await handler(
          _patch('/v1/platform/tickets/$ticketId', {
            'reply': 'Refund issued, sorry about that!',
            'status': 'resolved',
          }, token: adminToken),
        );
        expect(replied.statusCode, 200);
        final repliedJson = await _decode(replied);
        expect(repliedJson['data']['status'], 'resolved');
        expect((repliedJson['data']['replies'] as List).length, 2);
      },
    );
  });

  group('OTP verify hardening', () {
    late Store store;
    late Handler handler;

    setUp(() {
      store = createTestStore();
      handler = createHandler(store);
    });

    tearDown(() => store.dispose());

    Future<String> requestOtp({String phone = '+998901234567'}) async {
      final send = await handler(_post('/v1/auth/otp/send', {'phone': phone}));
      return (await _decode(send))['data']['requestId'] as String;
    }

    test('otp/send never returns the OTP code as devHint', () async {
      final send = await handler(
        _post('/v1/auth/otp/send', {'phone': '+998901234567'}),
      );
      final json = await _decode(send);
      expect(json['data']['requestId'], isNotNull);
      expect((json['data'] as Map).containsKey('devHint'), isFalse);
    });

    test('invalidates the requestId after the wrong-attempt cap', () async {
      final requestId = await requestOtp();
      // First four wrong codes are plain 401s.
      for (var i = 0; i < 4; i++) {
        final wrong = await handler(
          _post('/v1/auth/otp/verify', {
            'requestId': requestId,
            'code': '000000',
          }),
        );
        expect(wrong.statusCode, 401);
      }
      // The fifth wrong code trips the cap and invalidates the request.
      final capped = await handler(
        _post('/v1/auth/otp/verify', {
          'requestId': requestId,
          'code': '000000',
        }),
      );
      expect(capped.statusCode, 429);
      final cappedJson = await _decode(capped);
      expect(cappedJson['error']['code'], 'TOO_MANY_ATTEMPTS');

      // Even the correct code no longer works: the requestId is gone.
      final correct = await handler(
        _post('/v1/auth/otp/verify', {
          'requestId': requestId,
          'code': '123456',
        }),
      );
      expect(correct.statusCode, 401);
    });

    test(
      'returns 429 once the per-IP verify rate limit is exhausted',
      () async {
        final limited = createHandler(
          store,
          otpVerifyLimiter: RateLimiter(1, const Duration(minutes: 5)),
        );
        final send = await limited(
          _post('/v1/auth/otp/send', {'phone': '+998901234567'}),
        );
        final requestId = (await _decode(send))['data']['requestId'] as String;

        final r1 = await limited(
          _post('/v1/auth/otp/verify', {
            'requestId': requestId,
            'code': '000000',
          }),
        );
        expect(r1.statusCode, 401);
        final r2 = await limited(
          _post('/v1/auth/otp/verify', {
            'requestId': requestId,
            'code': '123456',
          }),
        );
        expect(r2.statusCode, 429);
        expect(r2.headers['Retry-After'], isNotNull);
      },
    );
  });

  group('token refresh: rotation + rate limiting', () {
    late Store store;

    setUp(() => store = Store());
    tearDown(() => store.dispose());

    test(
      'rotates tokens and the old refresh token becomes single-use',
      () async {
        final handler = createHandler(store);
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
        final refreshToken =
            (await _decode(verify))['data']['refreshToken'] as String;

        final refreshed = await handler(
          _post('/v1/auth/refresh', {'refreshToken': refreshToken}),
        );
        expect(refreshed.statusCode, 200);

        // Rotation: reusing the consumed refresh token is rejected.
        final reuse = await handler(
          _post('/v1/auth/refresh', {'refreshToken': refreshToken}),
        );
        expect(reuse.statusCode, 401);
      },
    );

    test('auth/refresh returns 429 once the rate limit is exhausted', () async {
      final handler = createHandler(
        store,
        refreshLimiter: RateLimiter(1, const Duration(minutes: 5)),
      );
      final r1 = await handler(
        _post('/v1/auth/refresh', {'refreshToken': 'not-a-real-token'}),
      );
      expect(r1.statusCode, 401);
      final r2 = await handler(
        _post('/v1/auth/refresh', {'refreshToken': 'not-a-real-token'}),
      );
      expect(r2.statusCode, 429);
      expect(r2.headers['Retry-After'], isNotNull);
    });
  });

  group('unpublished project is not leaked via read sub-routes (IDOR)', () {
    late Store store;
    late Handler handler;
    late String projectId;

    setUp(() {
      store = createTestStore();
      handler = createHandler(store);
      final project = store.projects.first;
      projectId = project['id'] as String;
      project['isPublished'] = false;
      project['moderationStatus'] = 'pending';
    });

    tearDown(() => store.dispose());

    test('anonymous callers get 404 on every read route', () async {
      for (final path in [
        '/v1/projects/$projectId',
        '/v1/projects/$projectId/units',
        '/v1/projects/$projectId/buildings',
        '/v1/projects/$projectId/units/grid',
        '/v1/projects/$projectId/offers',
      ]) {
        final res = await handler(_get(path));
        expect(res.statusCode, 404, reason: path);
      }
    });

    test('a system admin can still read the unpublished project', () async {
      store.ensureUser(phone: '+998901234567', role: 'system_admin');
      final token = await _signIn(handler);
      final res = await handler(
        _get('/v1/projects/$projectId/units', token: token),
      );
      expect(res.statusCode, 200);
    });
  });

  group('WebSocket upgrade requires authentication', () {
    late Store store;
    late Handler handler;

    setUp(() {
      store = createTestStore();
      handler = createHandler(store);
    });

    tearDown(() => store.dispose());

    test('GET /v1/ws without a token is rejected with 401', () async {
      final res = await handler(_get('/v1/ws'));
      expect(res.statusCode, 401);
      final json = await _decode(res);
      expect(json['error']['code'], 'UNAUTHENTICATED');
    });
  });
}
