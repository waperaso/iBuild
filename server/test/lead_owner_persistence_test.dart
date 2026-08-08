// CRM lead owner: filter unit test + live-DB persistence for owner_user_id/events.
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/src/db/database.dart';
import '../lib/src/db/pg_config.dart';
import '../lib/src/db/pg_persistence.dart';
import '../lib/src/store.dart';
import '../lib/src/user_roles.dart';
import 'test_fixtures.dart';

void main() {
  group('filterLeadsByOwner', () {
    final leads = [
      {'id': 'l1', 'ownerUserId': 'u1'},
      {'id': 'l2', 'ownerUserId': null},
      {'id': 'l3', 'ownerUserId': 'u2'},
    ];
    final store = Store();

    test('me returns only current user leads', () {
      final mine = store.filterLeadsByOwner(
        leads,
        ownerFilter: 'me',
        currentUserId: 'u1',
      );
      expect(mine.map((l) => l['id']), ['l1']);
    });

    test('unassigned returns leads without owner', () {
      final open = store.filterLeadsByOwner(
        leads,
        ownerFilter: 'unassigned',
        currentUserId: 'u1',
      );
      expect(open.map((l) => l['id']), ['l2']);
    });
  });

  group('setLeadOwner in-memory', () {
    late Store store;
    late String managerId;
    late String manager2Id;
    late String leadId;

    setUp(() {
      store = createTestStore();
      final manager = store.ensureUser(
        phone: '+998901239999',
        role: 'system_admin',
        name: 'CRM Manager',
      );
      managerId = manager['id'] as String;
      final manager2 = store.ensureUser(
        phone: '+998901239998',
        role: 'residence_admin',
        name: 'CRM Manager 2',
      );
      manager2Id = manager2['id'] as String;
      final project = store.publishedProjects.first;
      final lead = store.createLead({
        'projectId': project['id'],
        'intent': 'callback',
        'consent': true,
      });
      leadId = lead['id'] as String;
    });

    tearDown(() => store.dispose());

    test('assign writes assigned event and syncs display label', () async {
      await store.setLeadOwner(
        leadId,
        ownerUserId: managerId,
        actorUserId: managerId,
      );
      final updated = store.leadById(leadId)!;
      expect(updated['ownerUserId'], managerId);
      expect(updated['assignedManager'], 'CRM Manager');
      final events = store.leadEventsForLead(leadId);
      expect(events.first['type'], 'assigned');
    });

    test('transfer writes transferred event', () async {
      await store.setLeadOwner(
        leadId,
        ownerUserId: managerId,
        actorUserId: managerId,
      );
      await store.transferLead(
        leadId,
        toUserId: manager2Id,
        actorUserId: managerId,
        note: 'handoff',
      );
      final updated = store.leadById(leadId)!;
      expect(updated['ownerUserId'], manager2Id);
      expect(
        store.leadEventsForLead(leadId).any((e) => e['type'] == 'transferred'),
        isTrue,
      );
    });
  });

  final config = PgConfig.fromEnv(Platform.environment);

  group('lead owner persistence (live DB)', () {
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

    test('owner_user_id and lead_events round-trip', () async {
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final managerId = 'usr-crm-$suffix';
      final leadId = 'lead-crm-$suffix';

      await persistence.upsertUser({
        'id': managerId,
        'phone': '+998909${suffix.toString().padLeft(6, '0').substring(0, 6)}',
        'name': 'CRM Owner',
        'role': UserRole.residenceAdmin,
      });

      await persistence.saveLead({
        'id': leadId,
        'number': 'LD-$suffix',
        'projectId': 'prj-crm-$suffix',
        'projectName': 'CRM Test',
        'unitId': null,
        'unitLabel': null,
        'intent': 'buy',
        'status': 'new',
        'contactPhone': '+998901112233',
        'message': 'test',
        'preferredAt': null,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': null,
        'ownerUserId': managerId,
        'assignedManager': 'CRM Owner',
        'notes': null,
        'tags': const <String>[],
        'score': 'warm',
        'lastContactAt': DateTime.now().toIso8601String(),
      });

      await persistence.saveLeadEvent({
        'id': 'lev-$suffix',
        'leadId': leadId,
        'actorUserId': managerId,
        'type': 'assigned',
        'fromUserId': null,
        'toUserId': managerId,
        'detail': null,
        'createdAt': DateTime.now().toIso8601String(),
      });

      final loaded = await persistence.loadAllLeads();
      final lead = loaded.firstWhere((l) => l['id'] == leadId);
      expect(lead['ownerUserId'], managerId);
      expect(lead['assignedManager'], 'CRM Owner');

      final events = await persistence.loadLeadEvents(leadId);
      expect(events, isNotEmpty);
      expect(events.first['type'], 'assigned');

      await db.execute(
        Sql.named('DELETE FROM lead_events WHERE lead_id = @id'),
        parameters: {'id': TypedValue(Type.text, leadId)},
      );
      await db.execute(
        Sql.named('DELETE FROM leads WHERE id = @id'),
        parameters: {'id': TypedValue(Type.text, leadId)},
      );
      await db.execute(
        Sql.named('DELETE FROM users WHERE id = @id'),
        parameters: {'id': TypedValue(Type.text, managerId)},
      );
    });
  });
}
