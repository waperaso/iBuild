// Site-photo-cycle AI result durability: `last_result` / `verify_export`
// must survive a Postgres round-trip. Before migration 0021 these lived in
// process memory only, so every API restart/redeploy silently erased the
// AI verdict and structured report for every cycle already analyzed.
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/src/db/database.dart';
import '../lib/src/db/pg_config.dart';
import '../lib/src/db/pg_persistence.dart';

void main() {
  final config = PgConfig.fromEnv(Platform.environment);

  group('site photo cycle result persistence (live DB)', () {
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

    test('lastResult and verifyExport survive save + reload', () async {
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final projectId = 'prj-spc-$suffix';
      final cycleId = 'spc-$suffix';

      await db.execute(
        Sql.named('''
          INSERT INTO developers (
            id, name, rating, projects_count, phone, agent_name, agent_phone
          )
          VALUES (@devId, 'SPC Test Dev', 0, 0, '+998900000000', 'Agent', '+998900000000')
        '''),
        parameters: {'devId': TypedValue(Type.text, 'dev-spc-$suffix')},
      );
      await db.execute(
        Sql.named('''
          INSERT INTO projects (
            id, developer_id, name, type, status, district, address,
            lat, lng, description, rating
          )
          VALUES (
            @id, @devId, 'SPC Test Project', 'residential', 'draft', 'Test',
            'Test address', 41.3, 69.3, 'Test project', 0
          )
        '''),
        parameters: {
          'id': TypedValue(Type.text, projectId),
          'devId': TypedValue(Type.text, 'dev-spc-$suffix'),
        },
      );

      final lastResult = {
        'verdict': 'needs_review',
        'vendorVerdict': 'reject',
        'confidence': 0.9,
        'sameViewpoint': false,
        'progressDelta': null,
        'flags': ['different_location'],
        'summary': 'Фото A и B показывают разные помещения.',
        'overallConclusion': 'Развёрнутый вывод на русском с деталями.',
        'photoFindings': [
          {'role': 'a', 'stage': 'Каркас', 'description': 'Описание A.'},
          {'role': 'b', 'stage': 'Отделка', 'description': 'Описание B.'},
        ],
        'risks': [
          {
            'description': 'Разные помещения на A и B',
            'level': 'high',
            'normReference': null,
            'recommendation': 'Переснять фото.',
          },
        ],
        'recommendations': ['Переснять фото одного помещения.'],
      };
      final verifyExport = {
        'request': {'photoA': {'id': 'a'}, 'photoB': {'id': 'b'}},
        'response': {'verdict': 'needs_review'},
        'vendor': {'model': 'gpt-4o', 'httpStatus': 200},
      };

      await persistence.saveSitePhotoCycle({
        'id': cycleId,
        'projectId': projectId,
        'intervalDays': 14,
        'graceDays': 3,
        'status': 'inspector',
        'photoAId': null,
        'photoBId': null,
        'dueAt': null,
        'windowEndAt': null,
        'promptVersion': 'construction_verify/v0',
        'vendorJobId': null,
        'lastResult': lastResult,
        'verifyExport': verifyExport,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });

      final reloaded = await persistence.loadAllSitePhotoCycles();
      final cycle = reloaded.firstWhere((c) => c['id'] == cycleId);
      expect(cycle['lastResult'], isNotNull);
      final reloadedResult = cycle['lastResult'] as Map;
      expect(reloadedResult['overallConclusion'], lastResult['overallConclusion']);
      expect(reloadedResult['flags'], ['different_location']);
      final findings = reloadedResult['photoFindings'] as List;
      expect(findings, hasLength(2));
      expect((findings[0] as Map)['role'], 'a');
      final risks = reloadedResult['risks'] as List;
      expect((risks[0] as Map)['level'], 'high');

      expect(cycle['verifyExport'], isNotNull);
      final reloadedExport = cycle['verifyExport'] as Map;
      expect((reloadedExport['vendor'] as Map)['model'], 'gpt-4o');

      // Overwrite with a save that omits both JSON fields (the stub path)
      // and confirm they clear rather than leaving stale data behind.
      await persistence.saveSitePhotoCycle({
        'id': cycleId,
        'projectId': projectId,
        'intervalDays': 14,
        'graceDays': 3,
        'status': 'confirmed',
        'photoAId': null,
        'photoBId': null,
        'dueAt': null,
        'windowEndAt': null,
        'promptVersion': 'construction_verify/v0',
        'vendorJobId': null,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      final cleared = await persistence.loadAllSitePhotoCycles();
      final clearedCycle = cleared.firstWhere((c) => c['id'] == cycleId);
      expect(clearedCycle.containsKey('lastResult'), isFalse);
      expect(clearedCycle.containsKey('verifyExport'), isFalse);

      await db.execute(
        Sql.named('DELETE FROM site_photo_cycles WHERE id = @id'),
        parameters: {'id': TypedValue(Type.text, cycleId)},
      );
      await db.execute(
        Sql.named('DELETE FROM projects WHERE id = @id'),
        parameters: {'id': TypedValue(Type.text, projectId)},
      );
      await db.execute(
        Sql.named('DELETE FROM developers WHERE id = @id'),
        parameters: {'id': TypedValue(Type.text, 'dev-spc-$suffix')},
      );
    });
  });
}
