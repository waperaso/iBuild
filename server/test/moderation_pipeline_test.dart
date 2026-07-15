import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../lib/src/app.dart';
import '../lib/src/store.dart';

Future<Map<String, dynamic>> _decode(Response response) async {
  final body = await response.readAsString();
  return jsonDecode(body) as Map<String, dynamic>;
}

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

Request _get(String path, {String? token}) => Request(
  'GET',
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
  group('project publication pipeline', () {
    late Store store;
    late Handler handler;
    late String adminToken;

    setUp(() async {
      store = Store();
      store.ensureUser(phone: '+998901234567', role: 'system_admin');
      handler = createHandler(store);
      adminToken = await _signIn(handler, '+998901234567');
    });

    tearDown(() => store.dispose());

    test('approve moves project to published list with developer name', () async {
      final ownerToken = await _signIn(handler, '+998907009999');
      final ownerMe = await handler(_get('/v1/users/me', token: ownerToken));
      final ownerJson = await _decode(ownerMe);
      final ownerUserId = ownerJson['data']['id'] as String;

      final developer = store.registerDeveloper(
        ownerUserId: ownerUserId,
        name: 'Pipeline Builder',
        legalName: 'OOO Pipeline Builder',
        inn: '301234599',
        phone: '+998907009999',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent',
        directorFullName: 'Director',
        directorPinfl: '30101123456799',
        uboDeclared: true,
      );
      store.submitDeveloperForReview(ownerUserId);
      store.setDeveloperVerification(developer['id'] as String, 'approved');

      final created = store.createProjectForOwner(
        ownerUserId: ownerUserId,
        input: {'name': 'Pipeline Towers', 'district': 'Yunusabad'},
      );
      expect(created, isNotNull);
      final projectId = created!['id'] as String;

      store.submitProjectForReview(projectId);
      expect(store.pendingProjects().map((p) => p['id']), contains(projectId));
      expect(store.publishedProjects.map((p) => p['id']), isNot(contains(projectId)));

      final moderate = await handler(
        _patch('/v1/platform/projects/$projectId/moderate', {
          'decision': 'approve',
        }, token: adminToken),
      );
      expect(moderate.statusCode, 200);
      final moderateJson = await _decode(moderate);
      expect(moderateJson['data']['moderationStatus'], 'approved');
      expect(moderateJson['data']['isPublished'], isTrue);
      expect(
        (moderateJson['data']['developer'] as Map)['name'],
        'Pipeline Builder',
      );

      final published = await handler(
        _get('/v1/platform/projects/published', token: adminToken),
      );
      final publishedJson = await _decode(published);
      final items = (publishedJson['data'] as List).cast<Map<String, dynamic>>();
      expect(items.map((p) => p['id']), contains(projectId));
      final row = items.firstWhere((p) => p['id'] == projectId);
      expect(row['isPublished'], isTrue);
      expect((row['developer'] as Map)['name'], 'Pipeline Builder');

      final ownerProjects = await handler(
        _get('/v1/developers/me/projects', token: ownerToken),
      );
      expect(ownerProjects.statusCode, 200);
      final ownerProjectsJson = await _decode(ownerProjects);
      final ownerItems =
          (ownerProjectsJson['data'] as List).cast<Map<String, dynamic>>();
      expect(ownerItems, isNotEmpty);
      expect(ownerItems.first['isPublished'], isTrue);
      expect((ownerItems.first['developer'] as Map)['name'], 'Pipeline Builder');
    });

    test('owner can unpublish, republish, and delete own project', () async {
      final ownerToken = await _signIn(handler, '+998907007777');
      final ownerMe = await handler(_get('/v1/users/me', token: ownerToken));
      final ownerJson = await _decode(ownerMe);
      final ownerUserId = ownerJson['data']['id'] as String;

      final developer = store.registerDeveloper(
        ownerUserId: ownerUserId,
        name: 'Owner Actions Builder',
        legalName: 'OOO Owner Actions',
        inn: '301234577',
        phone: '+998907007777',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent',
        directorFullName: 'Director',
        directorPinfl: '30101123456777',
        uboDeclared: true,
      );
      store.submitDeveloperForReview(ownerUserId);
      store.setDeveloperVerification(developer['id'] as String, 'approved');
      store.activateSubscription(ownerUserId);

      final created = store.createProjectForOwner(
        ownerUserId: ownerUserId,
        input: {'name': 'Owner Actions Towers', 'district': 'Chilanzar'},
      );
      final projectId = created!['id'] as String;
      store.addBuilding(projectId, {'name': 'A', 'floors': 3});
      store.submitProjectForReview(projectId);
      await handler(
        _patch('/v1/platform/projects/$projectId/moderate', {
          'decision': 'approve',
        }, token: adminToken),
      );

      final unpublish = await handler(
        _post('/v1/admin/projects/$projectId/unpublish', {}, token: ownerToken),
      );
      expect(unpublish.statusCode, 200);
      final unpublishJson = await _decode(unpublish);
      expect(unpublishJson['data']['isPublished'], isFalse);
      expect(unpublishJson['data']['moderationStatus'], 'approved');

      final publish = await handler(
        _post('/v1/admin/projects/$projectId/publish', {}, token: ownerToken),
      );
      expect(publish.statusCode, 200);
      final publishJson = await _decode(publish);
      expect(publishJson['data']['isPublished'], isTrue);

      final deleted = await handler(
        Request(
          'DELETE',
          Uri.parse('http://localhost/v1/admin/projects/$projectId'),
          headers: {'authorization': 'Bearer $ownerToken'},
        ),
      );
      expect(deleted.statusCode, 200);
      expect(store.projectById(projectId), isNull);
    });

    test(
      'approved project with priced sale units appears in B2C mode=buy feed',
      () async {
        final ownerToken = await _signIn(handler, '+998907008888');
        final ownerMe = await handler(_get('/v1/users/me', token: ownerToken));
        final ownerJson = await _decode(ownerMe);
        final ownerUserId = ownerJson['data']['id'] as String;

        final developer = store.registerDeveloper(
          ownerUserId: ownerUserId,
          name: 'Buy Feed Builder',
          legalName: 'OOO Buy Feed',
          inn: '301234588',
          phone: '+998907008888',
          accountKind: 'property_developer',
          legalForm: 'ooo',
          legalAddress: 'Tashkent',
          directorFullName: 'Director',
          directorPinfl: '30101123456788',
          uboDeclared: true,
        );
        store.submitDeveloperForReview(ownerUserId);
        store.setDeveloperVerification(developer['id'] as String, 'approved');

        final created = store.createProjectForOwner(
          ownerUserId: ownerUserId,
          input: {'name': 'Buy Feed Towers', 'district': 'Mirzo Ulugbek'},
        );
        expect(created, isNotNull);
        final projectId = created!['id'] as String;
        expect(created['priceMin'], isNull);

        final building = store.addBuilding(projectId, {'name': 'A', 'floors': 5});
        final unit = store.addUnit(projectId, {
          'buildingId': building['id'],
          'number': '101',
          'dealType': 'sale',
          'status': 'available',
          'price': 120000,
          'rooms': 2,
          'areaTotal': 65,
        });
        expect(unit, isNotNull);
        expect(created['priceMin'], 120000);
        expect(created['priceMax'], 120000);

        store.submitProjectForReview(projectId);
        final moderate = await handler(
          _patch('/v1/platform/projects/$projectId/moderate', {
            'decision': 'approve',
          }, token: adminToken),
        );
        expect(moderate.statusCode, 200);

        final buyFeed = await handler(_get('/v1/projects?mode=buy'));
        expect(buyFeed.statusCode, 200);
        final buyJson = await _decode(buyFeed);
        final items = (buyJson['data'] as List).cast<Map<String, dynamic>>();
        expect(items.map((p) => p['id']), contains(projectId));
        final row = items.firstWhere((p) => p['id'] == projectId);
        expect(row['priceMin'], 120000);
        expect(row['isPublished'], isTrue);
      },
    );

    test('resubmitting developer application keeps the same developer id', () {
      final developer = store.registerDeveloper(
        ownerUserId: 'usr-resubmit',
        name: 'First Name',
        legalName: 'OOO First',
        inn: '301234588',
        phone: '+998907008888',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent',
        directorFullName: 'Director',
        directorPinfl: '30101123456788',
        uboDeclared: true,
      );
      final originalId = developer['id'] as String;
      store.setDeveloperVerification(originalId, 'approved');
      final project = store.createProjectForOwner(
        ownerUserId: 'usr-resubmit',
        input: {'name': 'Resubmit Towers'},
      );
      expect(project, isNotNull);

      store.setDeveloperVerification(originalId, 'rejected', rejectionReason: 'fix');
      final updated = store.registerDeveloper(
        ownerUserId: 'usr-resubmit',
        name: 'Updated Name',
        legalName: 'OOO Updated',
        inn: '301234588',
        phone: '+998907008888',
        accountKind: 'property_developer',
        legalForm: 'ooo',
        legalAddress: 'Tashkent 2',
        directorFullName: 'Director',
        directorPinfl: '30101123456788',
        uboDeclared: true,
      );

      expect(updated['id'], originalId);
      expect(updated['name'], 'Updated Name');
      final ownerProjects = store.projectsForDeveloperOwner('usr-resubmit');
      expect(ownerProjects, hasLength(1));
      expect((ownerProjects.first['developer'] as Map)['name'], 'Updated Name');
    });
  });
}
