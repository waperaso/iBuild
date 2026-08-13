import 'package:test/test.dart';

import '../lib/src/ai/lead_scoring_engine.dart';
import '../lib/src/store.dart';
import 'test_fixtures.dart';

void main() {
  group('LeadScoringEngine.score', () {
    late Store store;
    final engine = LeadScoringEngine();

    setUp(() => store = createTestStore());

    test('a specific, urgent, fresh off-plan lead scores hot', () {
      final lead = <String, dynamic>{
        'id': 'lead-hot-1',
        'intent': 'buy_offplan',
        'status': 'new',
        'unitId': 'unit-test-sale',
        'preferredAt': DateTime.now()
            .add(const Duration(days: 2))
            .toIso8601String(),
        'message':
            'Здравствуйте! Хочу купить срочно, интересует именно эта квартира для семьи.',
        'createdAt': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
      };
      final result = engine.score(lead, store, persist: false);
      expect(result.band, LeadBand.hot);
      expect(result.score, greaterThanOrEqualTo(70));
      expect(
        result.reasons,
        containsAll([
          'highIntent',
          'offplanInterest',
          'specificUnit',
          'preferredTimeSet',
          'urgentKeyword',
        ]),
      );
    });

    test('a vague, stalled, unresponded lead scores warm', () {
      final lead = <String, dynamic>{
        'id': 'lead-warm-1',
        'intent': 'viewing',
        'status': 'new',
        'message': 'hi',
        'createdAt': DateTime.now()
            .subtract(const Duration(hours: 25))
            .toIso8601String(),
      };
      final result = engine.score(lead, store, persist: false);
      expect(result.band, LeadBand.warm);
      expect(
        result.reasons,
        containsAll([
          'viewingRequested',
          'slaBreach',
          'noResponse24h',
          'lowSpecificity',
        ]),
      );
    });

    test('an old, quietly-contacted, unspecific lead scores cold', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 10));
      final lead = <String, dynamic>{
        'id': 'lead-cold-1',
        'intent': 'other',
        'status': 'contacted',
        'message': 'hi',
        'createdAt': createdAt.toIso8601String(),
        'lastContactAt': createdAt.toIso8601String(),
      };
      final result = engine.score(lead, store, persist: false);
      expect(result.band, LeadBand.cold);
      expect(result.reasons, contains('lowSpecificity'));
      expect(result.reasons, contains('stalled'));
    });

    test('persist:true (the default) writes ai* fields onto the lead map', () {
      final lead = <String, dynamic>{
        'id': 'lead-persist-1',
        'intent': 'rent',
        'status': 'new',
        'message': 'looking for something to rent',
        'createdAt': DateTime.now().toIso8601String(),
      };
      expect(lead['aiScore'], isNull);
      final result = engine.score(lead, store);
      expect(lead['aiScore'], result.score);
      expect(lead['aiBand'], result.band);
      expect(lead['aiReasons'], result.reasons);
      expect(lead['aiScoredAt'], isNotNull);
    });

    test('repeat contact from the same phone number scores a bonus', () {
      final phone = '+998900000001';
      store.leads.add({
        'id': 'lead-repeat-a',
        'intent': 'buy',
        'status': 'lost',
        'contactPhone': phone,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String(),
      });
      final lead = {
        'id': 'lead-repeat-b',
        'intent': 'buy',
        'status': 'new',
        'contactPhone': phone,
        'createdAt': DateTime.now().toIso8601String(),
      };
      final result = engine.score(lead, store, persist: false);
      expect(result.reasons, contains('repeatContact'));
    });
  });

  group('LeadScoringEngine.metrics', () {
    test('produces the documented aggregate shape', () {
      final store = createTestStore();
      final engine = LeadScoringEngine();
      final metrics = engine.metrics(store.leads, store);
      expect(
        metrics.keys,
        containsAll([
          'leadVolume',
          'byBand',
          'perManager',
          'responseSla',
          'funnel',
          'conversion',
        ]),
      );
      expect(metrics['byBand'], isA<Map>());
      expect(metrics['funnel'], isA<Map>());
      expect(metrics['conversion'], isA<List>());
    });
  });

  group('CrmQueryEngine', () {
    test('validates node ids and returns the root menu', () {
      final store = createTestStore();
      final engine = CrmQueryEngine(LeadScoringEngine());
      expect(engine.isValidNode('root'), isTrue);
      expect(engine.isValidNode('hotLeads'), isTrue);
      expect(engine.isValidNode('madeUpNode'), isFalse);

      final data = engine.handle(
        node: 'root',
        params: const {},
        leadsInScope: store.leads,
        projectsInScope: store.projects,
        store: store,
      );
      expect(data['node'], 'root');
      expect(data['options'], isNotEmpty);
      expect(data['breadcrumb'], isNotEmpty);
    });

    test('byProject lists in-scope projects with lead cards', () {
      final store = createTestStore();
      final engine = CrmQueryEngine(LeadScoringEngine());
      final data = engine.handle(
        node: 'byProject',
        params: const {},
        leadsInScope: store.leads,
        projectsInScope: store.projects,
        store: store,
      );
      expect(data['node'], 'byProject');
      expect((data['cards'] as List), isNotEmpty);
    });

    test('every advertised node answers with its own id and a breadcrumb', () {
      final store = createTestStore();
      final engine = CrmQueryEngine(LeadScoringEngine());
      final projectId = store.projects.first['id'];
      const projectNodes = {
        'projectMenu',
        'projectHot',
        'projectNoResponse48h',
        'projectNewToday',
        'projectFunnel',
        'projectDemand',
      };

      for (final node in [
        'root',
        'hotLeads',
        'whatNext',
        'needsResponse',
        'unassigned',
        'todaySummary',
        'byProject',
        'byManager',
        'analytics',
        'weekSummary',
        'conversion',
        'demand',
        'byImportance',
        ...projectNodes,
      ]) {
        expect(engine.isValidNode(node), isTrue, reason: node);
        final data = engine.handle(
          node: node,
          params: projectNodes.contains(node) ? {'projectId': projectId} : {},
          leadsInScope: store.leads,
          projectsInScope: store.projects,
          store: store,
        );
        expect(data['node'], node, reason: node);
        expect(data['breadcrumb'], isNotEmpty, reason: node);
        expect(data['messageCode'], isNotEmpty, reason: node);
      }
    });

    test('byManager cards drill into that manager only', () {
      final store = createTestStore();
      final engine = CrmQueryEngine(LeadScoringEngine());
      final owner = store.leads.firstWhere(
        (l) => l['ownerUserId'] != null,
        orElse: () => <String, dynamic>{},
      )['ownerUserId'];

      final managers = engine.handle(
        node: 'byManager',
        params: const {},
        leadsInScope: store.leads,
        projectsInScope: store.projects,
        store: store,
      );
      expect(
        (managers['cards'] as List).every((c) => c['type'] == 'manager'),
        isTrue,
      );

      if (owner == null) return;
      final owned = engine.handle(
        node: 'managerLeads',
        params: {'userId': owner},
        leadsInScope: store.leads,
        projectsInScope: store.projects,
        store: store,
      );
      expect(owned['node'], 'managerLeads');
      expect((owned['cards'] as List), isA<List>());
    });

    test('an empty workspace answers with flagged sample cards', () {
      final store = createTestStore();
      final engine = CrmQueryEngine(LeadScoringEngine());
      final data = engine.handle(
        node: 'hotLeads',
        params: const {},
        leadsInScope: const [],
        projectsInScope: const [],
        store: store,
      );
      expect(data['isExample'], isTrue);
      expect(data['messageCode'], 'crmBot.example.message');
      final cards = (data['cards'] as List).cast<Map>();
      expect(cards, isNotEmpty);
      // Sample leads must not offer actions — there is nothing to act on.
      expect(cards.every((c) => (c['actions'] as List).isEmpty), isTrue);
      expect(cards.every((c) => c['leadId'] == null), isTrue);
    });

    test('a menu node stays a menu when there is no data to sample', () {
      final store = createTestStore();
      final engine = CrmQueryEngine(LeadScoringEngine());
      final data = engine.handle(
        node: 'root',
        params: const {},
        leadsInScope: const [],
        projectsInScope: const [],
        store: store,
      );
      expect(data['isExample'], isNull);
      expect(data['options'], isNotEmpty);
    });

    test('real data never gets the example flag', () {
      final store = createTestStore();
      final engine = CrmQueryEngine(LeadScoringEngine());
      final data = engine.handle(
        node: 'hotLeads',
        params: const {},
        leadsInScope: store.leads,
        projectsInScope: store.projects,
        store: store,
      );
      expect(data['isExample'], isNull);
    });
  });
}
