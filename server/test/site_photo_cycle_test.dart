import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../lib/src/ai/openai_client.dart';
import '../lib/src/ai/prompt_bundle.dart';
import '../lib/src/app.dart';
import '../lib/src/seed_data.dart';
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

Future<String> _signIn(Handler handler, String phone) async {
  final send = await handler(_post('/v1/auth/otp/send', {'phone': phone}));
  final sendJson = await _decode(send);
  final requestId = sendJson['data']['requestId'] as String;
  final verify = await handler(
    _post('/v1/auth/otp/verify', {'requestId': requestId, 'code': '123456'}),
  );
  return (await _decode(verify))['data']['accessToken'] as String;
}

Future<({String token, String projectId})> _owner(
  Handler handler,
  Store store, {
  required String phone,
  required String inn,
}) async {
  var token = await _signIn(handler, phone);
  final me = await handler(_get('/v1/users/me', token: token));
  final ownerId = (await _decode(me))['data']['id'] as String;
  final developer = store.registerDeveloper(
    ownerUserId: ownerId,
    name: 'Cycle Dev $inn',
    legalName: 'OOO Cycle $inn',
    inn: inn,
    phone: phone,
    accountKind: 'property_developer',
    legalForm: 'ooo',
    legalAddress: 'Tashkent',
    directorFullName: 'Director',
    directorPinfl: '301012${inn}01',
    uboDeclared: true,
  );
  store.submitDeveloperForReview(ownerId);
  store.setDeveloperVerification(developer['id'] as String, 'approved');
  final project = store.createProjectForOwner(
    ownerUserId: ownerId,
    input: {'name': 'Cycle Towers $inn', 'district': 'Chilanzar'},
  )!;
  token = await _signIn(handler, phone);
  return (token: token, projectId: project['id'] as String);
}

void main() {
  late Store store;
  late Handler handler;

  setUp(() {
    store = Store();
    handler = createHandler(store);
  });

  tearDown(() => store.dispose());

  test('GET cycle without a row lazy-creates awaiting_a', () async {
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110001',
      inn: '301210001',
    );
    final response = await handler(
      _get(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle',
        token: owner.token,
      ),
    );
    expect(response.statusCode, 200);
    final data = (await _decode(response))['data'] as Map;
    expect(data['status'], 'awaiting_a');
    expect(data['canUploadA'], isTrue);
    expect(data['canUploadB'], isFalse);
    expect(data.containsKey('vendorCall'), isFalse);
  });

  test('POST A then B too early; after due_at B stubs inspector', () async {
    store.ensureUser(phone: '+998901234567', role: 'system_admin');
    final adminToken = await _signIn(handler, '+998901234567');
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110002',
      inn: '301210002',
    );

    final postA = await handler(
      _post(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle/photo-a',
        {
          'url': 'https://example.com/a.jpg',
          'takenAt': DateTime.now().toUtc().toIso8601String(),
          'progressPercent': 20,
        },
        token: owner.token,
      ),
    );
    expect(postA.statusCode, 201);
    final afterA = (await _decode(postA))['data'] as Map;
    expect(afterA['status'], 'waiting');
    expect(afterA['canUploadB'], isFalse);

    final tooEarly = await handler(
      _post(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle/photo-b',
        {'url': 'https://example.com/b.jpg', 'takenAt': '2026-01-02'},
        token: owner.token,
      ),
    );
    expect(tooEarly.statusCode, 422);
    expect((await _decode(tooEarly))['error']['code'], 'TOO_EARLY');

    final cycle = store.sitePhotoCycleForProject(owner.projectId)!;
    cycle['dueAt'] = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 1))
        .toIso8601String();
    cycle['status'] = 'waiting';

    final postB = await handler(
      _post(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle/photo-b',
        {'url': 'https://example.com/b.jpg', 'takenAt': '2026-01-20'},
        token: owner.token,
      ),
    );
    expect(postB.statusCode, 201);
    final afterB = (await _decode(postB))['data'] as Map;
    expect(afterB['status'], anyOf('analyzing', 'inspector'));
    await store.awaitPendingVerifyJobs();
    final afterJob = await handler(
      _get(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle',
        token: owner.token,
      ),
    );
    final afterBDone = (await _decode(afterJob))['data'] as Map;
    expect(afterBDone['status'], 'inspector');
    expect(
      ((afterBDone['result'] as Map)['flags'] as List),
      contains('images_unavailable'),
    );
    expect(store.vendorAiCalls, isNotEmpty);
    expect(store.vendorAiCalls.first['verdict'], 'images_unavailable');
    expect(store.inspectorReviews, isNotEmpty);

    final ownerGet = await handler(
      _get(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle',
        token: owner.token,
      ),
    );
    expect(
      ((await _decode(ownerGet))['data'] as Map).containsKey('vendorCall'),
      isFalse,
    );

    final adminGet = await handler(
      _get(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle',
        token: adminToken,
      ),
    );
    final adminJson = (await _decode(adminGet))['data'] as Map;
    expect(adminJson['vendorCall'], isNotNull);
    expect(adminJson['stubVerdict'], 'images_unavailable');
    expect(jsonEncode(adminJson), isNot(contains('sk-')));

    expect(
      (await handler(
        _get(
          '/v1/admin/projects/${owner.projectId}/site-photo-cycle/vendor-calls',
          token: owner.token,
        ),
      )).statusCode,
      403,
    );
    final vendorAdmin = await handler(
      _get(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle/vendor-calls',
        token: adminToken,
      ),
    );
    expect(vendorAdmin.statusCode, 200);
    expect(jsonEncode(await _decode(vendorAdmin)), isNot(contains('sk-')));

    expect(
      (await handler(
        _get('/v1/platform/site-photo-cycles', token: owner.token),
      )).statusCode,
      403,
    );
    final list = await handler(
      _get('/v1/platform/site-photo-cycles', token: adminToken),
    );
    expect(list.statusCode, 200);
    final rows = ((await _decode(list))['data'] as List).cast<Map>();
    expect(rows.any((r) => r['projectId'] == owner.projectId), isTrue);
  });

  test('foreign residence admin cannot read or write the cycle', () async {
    final a = await _owner(
      handler,
      store,
      phone: '+998907110003',
      inn: '301210003',
    );
    final b = await _owner(
      handler,
      store,
      phone: '+998907110004',
      inn: '301210004',
    );
    expect(
      (await handler(
        _get(
          '/v1/admin/projects/${a.projectId}/site-photo-cycle',
          token: b.token,
        ),
      )).statusCode,
      403,
    );
    expect(
      (await handler(
        _post(
          '/v1/admin/projects/${a.projectId}/site-photo-cycle/photo-a',
          {'url': 'https://example.com/x.jpg'},
          token: b.token,
        ),
      )).statusCode,
      403,
    );
  });

  test('demo token cannot POST photo A', () async {
    final demo = store.createDemoSession(profile: 'b2b_platform');
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110005',
      inn: '301210005',
    );
    final response = await handler(
      _post(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle/photo-a',
        {'url': 'https://example.com/demo.jpg'},
        token: demo.accessToken,
      ),
    );
    expect(response.statusCode, 403);
    expect((await _decode(response))['error']['code'], 'DEMO_READ_ONLY');
  });

  test('residence demo stages empty NestOne cycle', () {
    store.createDemoSession(profile: 'b2b_residence');
    final cycle = store.sitePhotoCycleForProject(
      'prj-nestone',
      includeDemoEphemeral: true,
    );
    expect(cycle, isNotNull);
    expect(cycle!['status'], 'awaiting_a');
    expect(cycle['demoEphemeral'], isTrue);
    expect(cycle['photoAId'], isNull);
    expect(cycle['photoBId'], isNull);
  });

  test('POST unlock advances waiting to awaiting_b', () async {
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110015',
      inn: '301210015',
    );
    final cycle = store.ensureSitePhotoCycle(
      owner.projectId,
      intervalMinutes: kSitePhotoDemoIntervalMinutes,
    );
    final takenAt = DateTime.now().toUtc();
    final report = store.addPhotoReport(
      projectId: owner.projectId,
      photoUrl: 'https://example.com/a.jpg',
      takenAt: takenAt,
      takenAtIsManual: true,
      uploadedBy: 'test',
      cycleId: cycle['id'] as String,
      role: 'baseline_a',
    );
    store.attachPhotoA(
      cycleId: cycle['id'] as String,
      reportId: report['id'] as String,
      takenAt: takenAt,
    );
    expect(store.sitePhotoCycleForProject(owner.projectId)!['status'], 'waiting');

    final response = await handler(
      _post(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle/unlock',
        const {},
        token: owner.token,
      ),
    );
    expect(response.statusCode, 200);
    final data = (await _decode(response))['data'] as Map;
    expect(data['status'], 'awaiting_b');
    expect(data['canUploadB'], isTrue);
    expect(data['canUnlockFollowUp'], isFalse);
  });

  test('POST unlock rejects production 14-day waiting cycles', () async {
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110016',
      inn: '301210016',
    );
    final cycle = store.ensureSitePhotoCycle(owner.projectId);
    final takenAt = DateTime.now().toUtc();
    final report = store.addPhotoReport(
      projectId: owner.projectId,
      photoUrl: 'https://example.com/a.jpg',
      takenAt: takenAt,
      takenAtIsManual: true,
      uploadedBy: 'test',
      cycleId: cycle['id'] as String,
      role: 'baseline_a',
    );
    store.attachPhotoA(
      cycleId: cycle['id'] as String,
      reportId: report['id'] as String,
      takenAt: takenAt,
    );
    expect(store.sitePhotoCycleForProject(owner.projectId)!['status'], 'waiting');
    expect(
      store.sitePhotoCycleForProject(owner.projectId)!['intervalMinutes'],
      isNull,
    );

    final response = await handler(
      _post(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle/unlock',
        const {},
        token: owner.token,
      ),
    );
    expect(response.statusCode, 403);
    expect((await _decode(response))['error']['code'], 'FORBIDDEN');
  });

  test('demo residence can POST photo-a then photo-b on NestOne', () async {
    final demo = store.createDemoSession(profile: 'b2b_residence');
    final first = await handler(
      _post(
        '/v1/admin/projects/prj-nestone/site-photo-cycle/photo-a',
        {'userLanguage': 'ru'},
        token: demo.accessToken,
      ),
    );
    expect(first.statusCode, 201);
    final afterA = (await _decode(first))['data'] as Map;
    expect(afterA['status'], 'awaiting_b');
    expect(afterA['canUploadB'], isTrue);
    expect(afterA['photoB'], isNull);
    expect((afterA['photoA'] as Map)['photoUrl'], contains(kSitePhotoDemoAFile));

    final second = await handler(
      _post(
        '/v1/admin/projects/prj-nestone/site-photo-cycle/photo-b',
        {'userLanguage': 'ru'},
        token: demo.accessToken,
      ),
    );
    expect(second.statusCode, 201);
    final afterB = (await _decode(second))['data'] as Map;
    expect(afterB['status'], 'analyzing');
    expect(afterB['canUploadB'], isFalse);
    expect((afterB['photoB'] as Map)['photoUrl'], contains(kSitePhotoDemoBFile));
    expect(afterB['reuploadLockedUntil'], isNotNull);
    expect(afterB['userLanguage'], 'ru');
    await store.awaitPendingVerifyJobs();
  });

  test('demo residence can pick alternate bundled sample for photo-a', () async {
    final demo = store.createDemoSession(profile: 'b2b_residence');
    final response = await handler(
      _post(
        '/v1/admin/projects/prj-nestone/site-photo-cycle/photo-a',
        {'userLanguage': 'ru', 'sampleFile': 'nestone.png'},
        token: demo.accessToken,
      ),
    );
    expect(response.statusCode, 201);
    final afterA = (await _decode(response))['data'] as Map;
    expect((afterA['photoA'] as Map)['photoUrl'], contains('nestone.png'));
  });

  test('demo staging does not mutate live NestOne cycle', () {
    final before = store.sitePhotoCycleForProject('prj-nestone');
    final beforeId = before?['id'];
    final beforeStatus = before?['status'];
    store.createDemoSession(profile: 'b2b_residence');
    final live = store.sitePhotoCycleForProject('prj-nestone');
    expect(live?['id'], beforeId);
    expect(live?['status'], beforeStatus);
    expect(live?['demoEphemeral'], isNot(true));
    final demo = store.sitePhotoCycleForProject(
      'prj-nestone',
      includeDemoEphemeral: true,
    );
    expect(demo, isNotNull);
    expect(demo!['demoEphemeral'], isTrue);
    expect(demo['status'], 'awaiting_a');
    expect(demo['photoAId'], isNull);
  });

  test('demo GET does not inject intervalMinutes onto live cycles', () async {
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110017',
      inn: '301210017',
    );
    store.ensureSitePhotoCycle(owner.projectId);
    final demo = store.createDemoSession(profile: 'b2b_platform');
    final response = await handler(
      _get(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle',
        token: demo.accessToken,
      ),
    );
    // Platform demo may manage any project; must not create a fast interval.
    expect(response.statusCode, anyOf(200, 403, 404));
    if (response.statusCode == 200) {
      final data = (await _decode(response))['data'] as Map;
      expect(data['intervalMinutes'], isNull);
    }
    expect(
      store.sitePhotoCycleForProject(owner.projectId)?['intervalMinutes'],
      isNull,
    );
  });

  test('prompt bundle hashes the on-disk stub without secrets', () {
    final bundle = loadPromptBundle(
      systemFileOverride:
          'lib/src/ai/prompts/construction_verify/v0.system.txt',
    );
    expect(bundle.systemText, contains('PROMPT_NOT_SHIPPED'));
    expect(bundle.isShipped, isFalse);
    expect(bundle.sha256hex.length, 64);
  });

  test('after B the developer sees a result card, not vendor hashes', () async {
    store.ensureUser(phone: '+998901234567', role: 'system_admin');
    final adminToken = await _signIn(handler, '+998901234567');
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110006',
      inn: '301210006',
    );
    final cycleId = await _reachInspector(
      handler,
      store,
      owner: owner,
    );
    final ownerGet = await handler(
      _get(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle',
        token: owner.token,
      ),
    );
    final data = (await _decode(ownerGet))['data'] as Map;
    expect(data['status'], 'inspector');
    expect(data.containsKey('vendorCall'), isFalse);
    expect(data['result'], isA<Map>());
    expect((data['result'] as Map)['verdict'], 'needs_review');
    expect(data['verifyExport'], isA<Map>());
    expect(jsonEncode(data['verifyExport']), isNot(contains('Fingerprint')));
    expect(jsonEncode(data['verifyExport']), isNot(contains('Phash')));
    expect(jsonEncode(data), isNot(contains('sk-')));
    expect(jsonEncode(data), isNot(contains('data:image')));

    expect(
      (await handler(
        _post(
          '/v1/platform/site-photo-cycles/$cycleId/confirm',
          const {},
          token: owner.token,
        ),
      )).statusCode,
      403,
    );

    final demo = store.createDemoSession(profile: 'b2b_platform');
    expect(
      (await handler(
        _post(
          '/v1/platform/site-photo-cycles/$cycleId/confirm',
          const {},
          token: demo.accessToken,
        ),
      )).statusCode,
      403,
    );

    final confirm = await handler(
      _post(
        '/v1/platform/site-photo-cycles/$cycleId/confirm',
        const {},
        token: adminToken,
      ),
    );
    expect(confirm.statusCode, 200);
    final confirmed = (await _decode(confirm))['data'] as Map;
    expect(confirmed['status'], 'confirmed');
    expect(confirmed['govNotifiedAt'], isNotNull);
    expect((confirmed['result'] as Map)['verdict'], 'confirm');
    expect(
      store.auditLog.any((e) => e['action'] == 'gov.notify.stub'),
      isTrue,
    );
  });

  test('GET result includes structured AI report fields', () async {
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110016',
      inn: '301210016',
    );
    await _reachInspector(handler, store, owner: owner);
    final cycle = store.sitePhotoCycleForProject(owner.projectId)!;
    final stored = Map<String, dynamic>.from(cycle['lastResult'] as Map);
    stored['overallConclusion'] = 'Развёрнутый вывод для инспектора.';
    stored['photoFindings'] = [
      {'role': 'a', 'stage': 'Каркас', 'description': 'Описание A.'},
      {'role': 'b', 'stage': 'Отделка', 'description': 'Описание B.'},
    ];
    stored['risks'] = [
      {
        'description': 'Разный ракурс',
        'level': 'medium',
        'normReference': null,
        'recommendation': 'Переснять из одной точки.',
      },
    ];
    stored['recommendations'] = ['Запросить повторную съёмку.'];
    cycle['lastResult'] = stored;

    final get = await handler(
      _get(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle',
        token: owner.token,
      ),
    );
    final result = (await _decode(get))['data']['result'] as Map;
    expect(result['overallConclusion'], 'Развёрнутый вывод для инспектора.');
    expect(result['photoFindings'], hasLength(2));
    expect((result['risks'] as List).first, containsPair('level', 'medium'));
    expect(result['recommendations'], ['Запросить повторную съёмку.']);
  });

  test('system admin can overturn an inspector cycle', () async {
    store.ensureUser(phone: '+998901234567', role: 'system_admin');
    final adminToken = await _signIn(handler, '+998901234567');
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110007',
      inn: '301210007',
    );
    final cycleId = await _reachInspector(handler, store, owner: owner);
    final overturn = await handler(
      _post(
        '/v1/platform/site-photo-cycles/$cycleId/overturn',
        const {},
        token: adminToken,
      ),
    );
    expect(overturn.statusCode, 200);
    expect((await _decode(overturn))['data']['status'], 'rejected');
  });

  test('vision is not called while the prompt is not shipped', () async {
    final fake = _ThrowingVisionClient();
    store = Store();
    handler = createHandler(store, openAiClient: fake);
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110008',
      inn: '301210008',
    );
    await _reachInspector(handler, store, owner: owner);
    expect(fake.calls, 0);
    expect(store.vendorAiCalls.first['verdict'], 'images_unavailable');
  });

  test('grace window marks cycle missed and blocks late B', () async {
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110009',
      inn: '301210009',
    );
    final postA = await handler(
      _post(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle/photo-a',
        {
          'url': 'https://example.com/a.jpg',
          'takenAt': DateTime.now().toUtc().toIso8601String(),
        },
        token: owner.token,
      ),
    );
    expect(postA.statusCode, 201);
    final cycle = store.sitePhotoCycleForProject(owner.projectId)!;
    cycle['dueAt'] = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 2))
        .toIso8601String();
    cycle['windowEndAt'] = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 1))
        .toIso8601String();
    cycle['status'] = 'awaiting_b';

    final lateB = await handler(
      _post(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle/photo-b',
        {'url': 'https://example.com/b.jpg', 'takenAt': '2026-01-20'},
        token: owner.token,
      ),
    );
    expect(lateB.statusCode, 422);
    expect((await _decode(lateB))['error']['code'], 'WINDOW_CLOSED');
    expect(cycle['status'], 'missed');
  });

  test('confirm opens a fresh awaiting_a cycle for the project', () async {
    store.ensureUser(phone: '+998901234567', role: 'system_admin');
    final adminToken = await _signIn(handler, '+998901234567');
    final owner = await _owner(
      handler,
      store,
      phone: '+998907110010',
      inn: '301210010',
    );
    final cycleId = await _reachInspector(handler, store, owner: owner);
    final confirm = await handler(
      _post(
        '/v1/platform/site-photo-cycles/$cycleId/confirm',
        const {},
        token: adminToken,
      ),
    );
    expect(confirm.statusCode, 200);
    final next = await handler(
      _get(
        '/v1/admin/projects/${owner.projectId}/site-photo-cycle',
        token: owner.token,
      ),
    );
    final data = (await _decode(next))['data'] as Map;
    expect(data['status'], 'awaiting_a');
    expect(data['id'], isNot(cycleId));
    expect(data['canUploadA'], isFalse);
    expect(data['reuploadLockedUntil'], isNotNull);
  });
}

Future<String> _reachInspector(
  Handler handler,
  Store store, {
  required ({String token, String projectId}) owner,
}) async {
  final postA = await handler(
    _post(
      '/v1/admin/projects/${owner.projectId}/site-photo-cycle/photo-a',
      {
        'url': 'https://example.com/a.jpg',
        'takenAt': DateTime.now().toUtc().toIso8601String(),
        'progressPercent': 20,
      },
      token: owner.token,
    ),
  );
  expect(postA.statusCode, 201);
  final cycle = store.sitePhotoCycleForProject(owner.projectId)!;
  cycle['dueAt'] = DateTime.now()
      .toUtc()
      .subtract(const Duration(hours: 1))
      .toIso8601String();
  cycle['status'] = 'waiting';
  final postB = await handler(
    _post(
      '/v1/admin/projects/${owner.projectId}/site-photo-cycle/photo-b',
      {'url': 'https://example.com/b.jpg', 'takenAt': '2026-01-20'},
      token: owner.token,
    ),
  );
  expect(postB.statusCode, 201);
  expect(
    (await _decode(postB))['data']['status'],
    anyOf('analyzing', 'inspector'),
  );
  await store.awaitPendingVerifyJobs();
  final done = await handler(
    _get(
      '/v1/admin/projects/${owner.projectId}/site-photo-cycle',
      token: owner.token,
    ),
  );
  expect((await _decode(done))['data']['status'], 'inspector');
  return cycle['id'] as String;
}

class _ThrowingVisionClient extends OpenAiClient {
  int calls = 0;

  @override
  bool get isConfigured => true;

  @override
  bool get isVisionEnabled => true;

  @override
  Future<String> completeWithImages({
    required String systemPrompt,
    required String userText,
    required List<String> imageDataUrls,
    int maxTokens = 1200,
    double temperature = 0.0,
    Duration timeout = OpenAiClient.visionTimeout,
  }) async {
    calls++;
    throw StateError('vision must not run while the prompt is not shipped');
  }

  @override
  Future<String> completeWithImageFiles({
    required String systemPrompt,
    required String userText,
    required List<OpenAiImageFile> images,
    int maxTokens = 1200,
    double temperature = 0.0,
    Duration timeout = OpenAiClient.visionTimeout,
  }) async {
    calls++;
    throw StateError('vision must not run while the prompt is not shipped');
  }
}
