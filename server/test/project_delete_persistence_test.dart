// Live-DB regression for "admin deleted complexes come back after restart".
//
// Gated the same way as `pg_persistence_integration_test.dart` — set DB_*
// in the process environment (not `.env`) to exercise against a scratch DB:
//
//   $env:DB_HOST="localhost"; $env:DB_NAME="ibuild_test"; ...
//   dart test test/project_delete_persistence_test.dart
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/src/db/database.dart';
import '../lib/src/db/pg_config.dart';
import '../lib/src/db/pg_persistence.dart';

void main() {
  final config = PgConfig.fromEnv(Platform.environment);

  group('project delete persistence + RLS write isolation', () {
    if (config == null) {
      test('skipped — set DB_HOST to run against a real database', () {
        markTestSkipped('DB_HOST is not set');
      });
      return;
    }

    late Database db;
    late PgPersistence persistence;

    setUpAll(() async {
      db = Database(config);
      await db.connect();
      await db.migrate();
      persistence = PgPersistence(db);
      await persistence.setRequestContext(role: 'service');
    });

    tearDownAll(() async {
      await db.close();
    });

    test('needsCatalogueSeed stays false after wipe once seeded', () async {
      await persistence.markCatalogueSeeded();
      // Even with zero projects, we must NOT want to re-seed.
      expect(await persistence.needsCatalogueSeed(), isFalse);
    });

    test(
      'deleteProject removes the row; ordinary_user cannot delete published',
      () async {
        final id = 'prj-del-test-${DateTime.now().microsecondsSinceEpoch}';
        await persistence.setRequestContext(role: 'service');

        await persistence.upsertDeveloper({
          'id': 'dev-del-test',
          'name': 'Del Test Dev',
          'logoUrl': null,
          'rating': 0.0,
          'projectsCount': 0,
          'phone': '+998900000001',
          'agentName': 'Agent',
          'agentPhone': '+998900000002',
          'agentAvatarUrl': null,
          'legalName': null,
          'inn': null,
          'website': null,
          'verificationStatus': 'approved',
          'rejectionReason': null,
          'ownerUserId': null,
          'createdAt': null,
          'accountKind': null,
          'legalForm': null,
          'registrationNumber': null,
          'okedCode': null,
          'legalAddress': null,
          'officeAddress': null,
          'region': null,
          'email': null,
          'description': null,
          'brandColor': null,
          'coverImageUrl': null,
          'directorFullName': null,
          'directorPinfl': null,
          'directorPassport': null,
          'directorPhone': null,
          'directorEmail': null,
          'uboDeclared': false,
          'uboFullName': null,
          'constructionLicense': null,
          'profileComplete': false,
        });

        await persistence.saveProject({
          'id': id,
          'name': 'Delete Me',
          'type': 'residential',
          'status': 'construction',
          'district': 'Chilanzar',
          'address': 'Test 1',
          'lat': 41.3,
          'lng': 69.2,
          'description': 'desc',
          'amenities': const <String>[],
          'tags': const <String>[],
          'priceMin': 0,
          'priceMax': 0,
          'rentMin': null,
          'rentMax': null,
          'constructionProgress': 0,
          'completionDate': null,
          'rating': 0,
          'availableUnits': 0,
          'totalUnits': 0,
          'isFeatured': false,
          'isPublished': true,
          'moderationStatus': 'approved',
          'moderationNote': null,
          'developer': {
            'id': 'dev-del-test',
            'name': 'Del Test Dev',
            'logoUrl': null,
            'rating': 0.0,
            'projectsCount': 0,
            'phone': '+998900000001',
            'agentName': 'Agent',
            'agentPhone': '+998900000002',
            'agentAvatarUrl': null,
          },
        });

        // Public/ordinary role must NOT be able to DELETE published rows
        // (regression for the 0012 FOR ALL USING hole).
        await persistence.setRequestContext(
          userId: 'buyer-rls',
          role: 'ordinary_user',
        );
        final blocked = await db.execute(
          Sql.named('DELETE FROM projects WHERE id = @id'),
          parameters: {'id': TypedValue(Type.text, id)},
        );
        expect(blocked.affectedRows, 0);

        await persistence.setRequestContext(role: 'service');
        final stillThere = await db.execute(
          Sql.named('SELECT 1 FROM projects WHERE id = @id'),
          parameters: {'id': TypedValue(Type.text, id)},
        );
        expect(stillThere, isNotEmpty);

        // Service-path delete (what Store.deleteProject awaits) must stick.
        await persistence.deleteProject(id);
        final gone = await db.execute(
          Sql.named('SELECT 1 FROM projects WHERE id = @id'),
          parameters: {'id': TypedValue(Type.text, id)},
        );
        expect(gone, isEmpty);

        // Simulate "restart load": row must not reappear from DB.
        await persistence.setRequestContext(role: 'service');
        final loaded = await persistence.loadAllProjects();
        expect(loaded.any((p) => p['id'] == id), isFalse);
      },
    );
  });
}
