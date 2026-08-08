// Integration test against a real PostgreSQL instance.
// Skips when DB_* env is unset. Use a scratch DB (e.g. ibuild_test), not primary ibuild:
//
//   $env:DB_HOST = "localhost"; $env:DB_PORT = "5433"
//   $env:DB_NAME = "ibuild_test"; $env:DB_USER = "postgres"
//   $env:DB_PASSWORD = "postgres"; $env:DB_SSL = "false"
//   dart test test/pg_persistence_integration_test.dart
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/src/db/database.dart';
import '../lib/src/db/pg_config.dart';
import '../lib/src/db/pg_persistence.dart';
import '../lib/src/seed_data.dart';

void main() {
  // Gate on real environment variables only (not the auto-loaded `.env`
  // file), so `dart test` never silently runs against the dev database.
  final config = PgConfig.fromEnv(Platform.environment);

  group('PostgreSQL persistence (live)', () {
    if (config == null) {
      test(
        'skipped — set DB_HOST (and friends) to run against a real database',
        () {
          markTestSkipped('DB_HOST is not set');
        },
      );
      return;
    }

    late Database db;
    late PgPersistence persistence;

    setUpAll(() async {
      db = Database(config);
      await db.connect();
      await db.migrate();
      persistence = PgPersistence(db);
    });

    tearDownAll(() async {
      await db.close();
    });

    test('migrate() is idempotent', () async {
      // Re-running must not throw or duplicate schema_migrations rows.
      await db.migrate();
      final rows = await db.execute('SELECT version FROM schema_migrations');
      final versions = rows.map((r) => r.first as String).toList();
      expect(versions.toSet().length, versions.length);
    });

    test('isEmpty() reflects the projects table row count', () async {
      final empty = await persistence.isEmpty();
      final rows = await db.execute('SELECT COUNT(*) FROM projects');
      final count = rows.first.first as int;
      expect(empty, count == 0);
    });

    test(
      'seedFrom() + loadAllProjects() reproduces the nested seed shape',
      () async {
        if (!await persistence.isEmpty()) {
          markTestSkipped(
            'projects table is not empty; skipping to avoid mutating '
            'existing data (run against a fresh scratch database to '
            'exercise this)',
          );
          return;
        }

        final seed = buildProjectsSeed();
        if (seed.isEmpty) {
          await persistence.seedFrom(seed);
          expect(await persistence.isEmpty(), isTrue);
          return;
        }

        await persistence.seedFrom(seed);

        expect(await persistence.isEmpty(), isFalse);

        final loaded = await persistence.loadAllProjects();
        expect(loaded.length, seed.length);

        final original = seed.first;
        final reloaded = loaded.firstWhere((p) => p['id'] == original['id']);

        expect(reloaded['name'], original['name']);
        expect(reloaded['district'], original['district']);
        expect(reloaded['developer']['name'], original['developer']['name']);
        expect(
          (reloaded['gallery'] as List).length,
          (original['gallery'] as List).length,
        );
        expect(
          (reloaded['buildings'] as List).length,
          (original['buildings'] as List).length,
        );

        final originalUnits = [
          for (final b in (original['buildings'] as List).cast<Map>())
            ...(b['units'] as List).cast<Map>(),
        ];
        final reloadedUnits = [
          for (final b in (reloaded['buildings'] as List).cast<Map>())
            ...(b['units'] as List).cast<Map>(),
        ];
        expect(reloadedUnits.length, originalUnits.length);

        final firstUnit = reloadedUnits.first;
        expect((firstUnit['media'] as List), isNotEmpty);

        final withOffers = seed
            .where((p) => (p['offers'] as List).isNotEmpty)
            .first;
        final reloadedWithOffers = loaded.firstWhere(
          (p) => p['id'] == withOffers['id'],
        );
        expect(
          (reloadedWithOffers['offers'] as List).length,
          (withOffers['offers'] as List).length,
        );
      },
    );

    test(
      'saveLead() + updateLeadStatus() + loadAllLeads() round-trip',
      () async {
        // leads.project_id has an FK since 0014 — use a real project when
        // the catalogue is present, otherwise skip.
        final projectRows = await db.execute(
          'SELECT id, name FROM projects LIMIT 1',
        );
        if (projectRows.isEmpty) {
          markTestSkipped('no projects to attach a lead to');
          return;
        }
        final projectId = projectRows.first.toColumnMap()['id'] as String;
        final projectName = projectRows.first.toColumnMap()['name'] as String;
        final leadId = 'lead-itest-${DateTime.now().microsecondsSinceEpoch}';
        final lead = {
          'id': leadId,
          'number': 'LD-ITEST-1',
          'projectId': projectId,
          'projectName': projectName,
          'unitId': null,
          'unitLabel': null,
          'intent': 'callback',
          'status': 'new',
          'contactPhone': '+998901234567',
          'message': 'integration test lead',
          'preferredAt': null,
          'createdAt': DateTime.now().toIso8601String(),
        };

        try {
          await persistence.saveLead(lead);
          var leads = await persistence.loadAllLeads();
          expect(leads.any((l) => l['id'] == leadId), isTrue);

          await persistence.updateLeadStatus(leadId, 'contacted');
          leads = await persistence.loadAllLeads();
          final reloaded = leads.firstWhere((l) => l['id'] == leadId);
          expect(reloaded['status'], 'contacted');
        } finally {
          await persistence.setRequestContext(role: 'service');
          await db.execute(
            Sql.named('DELETE FROM leads WHERE id = @id'),
            parameters: {'id': TypedValue(Type.text, leadId)},
          );
        }
      },
    );

    test('saveUnitStatus() write-through updates the units table', () async {
      if (await persistence.isEmpty()) {
        markTestSkipped('no seeded units to update in an empty database');
        return;
      }
      final rows = await db.execute('SELECT id, status FROM units LIMIT 1');
      final unitId = rows.first.toColumnMap()['id'] as String;
      final currentStatus = rows.first.toColumnMap()['status'] as String;
      final nextStatus = currentStatus == 'available'
          ? 'reserved'
          : 'available';

      await persistence.saveUnitStatus(unitId, nextStatus);
      final updated = await db.execute(
        Sql.named('SELECT status FROM units WHERE id = @id'),
        parameters: {'id': TypedValue(Type.text, unitId)},
      );
      expect(updated.first.first, nextStatus);

      // Restore, so re-running this test suite stays idempotent.
      await persistence.saveUnitStatus(unitId, currentStatus);
    });
  });
}
