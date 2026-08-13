import 'package:test/test.dart';

import '../lib/src/ai/smart_search_engine.dart';
import '../lib/src/store.dart';
import 'test_fixtures.dart';

void main() {
  group('SmartSearchParser', () {
    test('parses a Russian query (rooms, district, unit kind, price)', () {
      final c = SmartSearchParser.parse(
        '2 комнатная квартира в Юнусабаде до 60000\$',
      );
      expect(c.rooms, {2});
      expect(c.unitKind, 'apartment');
      expect(c.district, 'Yunusabad');
      expect(c.priceMax, 60000);
      expect(c.currency, 'USD');
      expect(c.unrecognized, isEmpty);
    });

    test(
      'parses an Uzbek query (rooms, district, unit kind, not-first-floor)',
      () {
        final c = SmartSearchParser.parse(
          "3 xonali xonadon Chilanzarda birinchi qavat emas",
        );
        expect(c.rooms, {3});
        expect(c.unitKind, 'apartment');
        expect(c.district, 'Chilanzar');
        expect(c.notFirstFloor, true);
        expect(c.unrecognized, isEmpty);
      },
    );

    test(
      'parses an English query (rooms, deal type, district, not-last-floor, price)',
      () {
        final c = SmartSearchParser.parse(
          '2 room apartment for rent in Yunusabad, not last floor, up to 800\$',
        );
        expect(c.rooms, {2});
        expect(c.unitKind, 'apartment');
        expect(c.dealType, 'rent');
        expect(c.district, 'Yunusabad');
        expect(c.notLastFloor, true);
        expect(c.priceMax, 800);
        expect(c.currency, 'USD');
        expect(c.unrecognized, isEmpty);
      },
    );

    test('recognizes studio as room count 0', () {
      final c = SmartSearchParser.parse('студия в Мирабаде');
      expect(c.rooms, {0});
      expect(c.district, 'Mirabad');
    });

    test('recognizes commercial unit kind; parking words are an amenity', () {
      expect(SmartSearchParser.parse('офис в аренду').unitKind, 'commercial');
      // There is no parking inventory, so «паркинг» is a home *with* parking
      // instead of a unit-kind filter that can never match anything.
      final c = SmartSearchParser.parse('parking spot');
      expect(c.unitKind, isNull);
      expect(c.amenities, {'parking'});
    });

    test('reads colloquial room names in all three languages', () {
      expect(SmartSearchParser.parse('Двушка').rooms, {2});
      expect(SmartSearchParser.parse('трёшка недорого').rooms, {3});
      expect(SmartSearchParser.parse('однушка в аренду').rooms, {1});
      expect(SmartSearchParser.parse('ikki xonali uy').rooms, {2});
      expect(SmartSearchParser.parse('two bedroom flat').rooms, {2});
      expect(SmartSearchParser.parse('3к квартира').rooms, {3});
    });

    test('reads room ranges and open-ended room counts', () {
      expect(SmartSearchParser.parse('2-3 комнатная').rooms, {2, 3});
      expect(SmartSearchParser.parse('от 3 комнат').rooms, {3, 4, 5});
      expect(SmartSearchParser.parse('2 или 4 комнаты').rooms, {2, 4});
    });

    test('reads soft preferences that carry no threshold', () {
      final c = SmartSearchParser.parse('просторная квартира подешевле повыше');
      expect(c.areaPreference, 'large');
      expect(c.pricePreference, 'cheap');
      expect(c.floorPreference, 'high');
      expect(c.unrecognized, isEmpty);
    });

    test('reads price ranges, magnitudes and currencies', () {
      expect(SmartSearchParser.parse('от 80 до 120 тысяч').priceMin, 80000);
      expect(SmartSearchParser.parse('от 80 до 120 тысяч').priceMax, 120000);
      expect(SmartSearchParser.parse('100-150k').priceMax, 150000);
      final uzs = SmartSearchParser.parse("900 mln so'm gacha");
      expect(uzs.priceMax, 900000000);
      expect(uzs.currency, 'UZS');
    });

    test('a room count is not mistaken for a budget', () {
      expect(SmartSearchParser.parse('2 комнатная квартира').priceMax, isNull);
      expect(SmartSearchParser.parse('до 5 к').priceMax, 5000);
      expect(SmartSearchParser.parse('5к квартира').rooms, {5});
    });

    test('maps the city centre to a district and the city itself to none', () {
      expect(SmartSearchParser.parse('квартира в центре').district, 'Mirabad');
      final city = SmartSearchParser.parse('квартира в Ташкенте');
      expect(city.district, isNull);
      expect(city.unrecognized, isEmpty);
    });

    test('resolves declensions and Latin/Cyrillic spellings alike', () {
      expect(
        SmartSearchParser.parse('kvartira Chilonzorda').district,
        'Chilanzar',
      );
      expect(
        SmartSearchParser.parse('квартиру в чиланзаре').unitKind,
        'apartment',
      );
      expect(SmartSearchParser.parse('уй Yunusobodda').district, 'Yunusabad');
    });

    test('a typo is corrected and reported, not silently swallowed', () {
      final parsed = SmartSearchParser.analyze('кваритра в юнусабаде');
      expect(parsed.constraints.unitKind, 'apartment');
      expect(parsed.constraints.district, 'Yunusabad');
      expect(parsed.autocorrections, hasLength(1));
      expect(parsed.autocorrections.single.from, 'кваритра');
      expect(parsed.autocorrections.single.to, 'квартира');
    });

    test('recovers a query typed on the wrong keyboard layout', () {
      final parsed = SmartSearchParser.analyze('rdfhnbhf d xbkfypfht');
      expect(parsed.constraints.unitKind, 'apartment');
      expect(parsed.constraints.district, 'Chilanzar');
      expect(
        parsed.autocorrections.map((a) => a.to),
        // The locative form is its own alias now, so the correction reports
        // the exact spelling that matched.
        containsAll(['квартира', 'чиланзаре']),
      );
    });

    test('a word with no dictionary hit is reported, never guessed', () {
      final parsed = SmartSearchParser.analyze('фывапр');
      expect(parsed.constraints.constraintCount, 0);
      expect(parsed.constraints.unrecognized, ['фывапр']);
      expect(parsed.suggestions, isEmpty);
      expect(parsed.meaningfulTokens, ['фывапр']);
    });

    test('a truncated word becomes a suggestion instead of a match', () {
      final parsed = SmartSearchParser.analyze('якк');
      expect(parsed.constraints.constraintCount, 0);
      expect(parsed.constraints.unrecognized, isEmpty);
      expect(parsed.suggestions, hasLength(1));
      expect(parsed.suggestions.single.target.kind, SearchTermKind.district);
    });

    test('intent and filler words never count as unknown', () {
      final parsed = SmartSearchParser.analyze(
        'Здравствуйте, подскажите пожалуйста варианты квартир для семьи',
      );
      expect(parsed.constraints.unitKind, 'apartment');
      expect(parsed.constraints.unrecognized, isEmpty);
    });
  });

  group('SmartSearchParser v3 — negation', () {
    test('«без ремонта» excludes the amenity instead of requiring it', () {
      final c = SmartSearchParser.parse('без ремонта');
      expect(c.excludedAmenities, {'renovation'});
      expect(c.amenities, isEmpty);
      expect(c.softAmenities, isEmpty);
      expect(c.constraintCount, greaterThan(0));
      expect(c.unrecognized, isEmpty);
    });

    test('«квартира без мебели в Чиланзаре» parses district and exclusion', () {
      final c = SmartSearchParser.parse('квартира без мебели в Чиланзаре');
      expect(c.unitKind, 'apartment');
      expect(c.district, 'Chilanzar');
      expect(c.excludedAmenities, {'furnished'});
      expect(c.amenities, isEmpty);
      expect(c.unrecognized, isEmpty);
    });

    test('negation works in Uzbek and English too', () {
      expect(
        SmartSearchParser.parse('mebelsiz kvartira').excludedAmenities,
        {'furnished'},
      );
      expect(
        SmartSearchParser.parse('lift yo\'q').excludedAmenities,
        {'elevator'},
      );
      expect(
        SmartSearchParser.parse('apartment without parking').excludedAmenities,
        {'parking'},
      );
      expect(
        SmartSearchParser.parse('no furniture').excludedAmenities,
        {'furnished'},
      );
    });

    test('lexicalized negations map to exclusions', () {
      expect(
        SmartSearchParser.parse('черновая отделка').excludedAmenities,
        {'renovation'},
      );
      expect(
        SmartSearchParser.parse('remontsiz uy').excludedAmenities,
        {'renovation'},
      );
    });

    test('«не первый этаж» still belongs to the floor pass', () {
      final c = SmartSearchParser.parse('квартира не первый этаж');
      expect(c.notFirstFloor, true);
      expect(c.excludedAmenities, isEmpty);
    });

    test('«без» before an unknown word stays unknown, nothing invented', () {
      final c = SmartSearchParser.parse('квартира без посредников');
      expect(c.excludedAmenities, isEmpty);
      expect(c.unrecognized, contains('посредников'));
    });
  });

  group('SmartSearchParser v3 — phrases and n-grams', () {
    test('«в Мирзо Улугбеке» resolves the district with zero unknowns', () {
      final c = SmartSearchParser.parse('в Мирзо Улугбеке');
      expect(c.district, 'Mirzo Ulugbek');
      expect(c.unrecognized, isEmpty);
    });

    test('a double space no longer breaks phrase matching', () {
      final c = SmartSearchParser.parse('мирзо  улугбек');
      expect(c.district, 'Mirzo Ulugbek');
      expect(c.unrecognized, isEmpty);
    });

    test('a one-typo phrase resolves through the n-gram fuzzy retry', () {
      final parsed = SmartSearchParser.analyze('мирзо улугбик');
      expect(parsed.constraints.district, 'Mirzo Ulugbek');
      expect(parsed.constraints.unrecognized, isEmpty);
      expect(
        parsed.autocorrections.map((a) => a.to),
        contains('мирзо улугбек'),
      );
    });

    test('inflected multi-word districts resolve («янги хаёте», uz -da)', () {
      expect(SmartSearchParser.parse('янги хаёте').district, 'Yangihayot');
      expect(
        SmartSearchParser.parse('yangi hayotda kvartira').district,
        'Yangihayot',
      );
      expect(
        SmartSearchParser.parse("mirzo ulug'bekda uy").district,
        'Mirzo Ulugbek',
      );
    });
  });

  group('SmartSearchParser v3 — regression guards', () {
    test('«офис на 5» still does not fabricate a price cap', () {
      final c = SmartSearchParser.parse('офис на 5');
      expect(c.unitKind, 'commercial');
      expect(c.priceMax, isNull);
      expect(c.priceMin, isNull);
    });

    test('«2-комнатная квартира в Чиланзаре» is rooms, not a budget', () {
      final c = SmartSearchParser.parse('2-комнатная квартира в Чиланзаре');
      expect(c.rooms, {2});
      expect(c.district, 'Chilanzar');
      expect(c.priceMax, isNull);
      expect(c.priceMin, isNull);
      expect(c.unrecognized, isEmpty);
    });

    test('area phrases and soft area preferences parse', () {
      final upTo = SmartSearchParser.parse('до 80 квадратов');
      expect(upTo.areaMax, 80);
      final from = SmartSearchParser.parse('от 50 кв м');
      expect(from.areaMin, 50);
      expect(SmartSearchParser.parse('просторная').areaPreference, 'large');
      expect(SmartSearchParser.parse('ixcham uy').areaPreference, 'small');
    });

    test('proximity phrasings resolve to amenities', () {
      expect(
        SmartSearchParser.parse('квартира недалеко от школы').amenities,
        {'school'},
      );
      expect(
        SmartSearchParser.parse('metro yaqinida kvartira').amenities,
        {'metro'},
      );
    });
  });

  group('SmartSearchEngine.run', () {
    late Store store;
    final engine = SmartSearchEngine();

    setUp(() => store = createTestStore());

    test('finds the matching sale apartment and emits real step counts', () {
      final data = engine.run(
        store,
        query: '2 комнатная квартира до 80000\$',
        language: 'ru',
      );

      final totals = data['totals'] as Map<String, dynamic>;
      expect(totals['projectsScanned'], store.publishedProjects.length);
      expect(
        totals['unitsScanned'],
        3,
      ); // 2 in the residential building + 1 office
      expect(totals['unitsMatched'], 1);

      final results = data['results'] as List;
      expect(results, hasLength(1));
      expect(results.first['unitId'], 'unit-test-sale');
      expect((results.first['matchReasons'] as List), contains('priceFit'));

      final steps = (data['steps'] as List)
          .map((s) => (s as Map)['code'])
          .toList();
      expect(steps.first, 'parsing');
      expect(steps.last, 'done');
      // No district was parsed, so district steps must be omitted.
      expect(steps, isNot(contains('scanningDistrict')));
      expect(steps, contains('openingProject'));
      expect(steps, contains('scanningUnits'));
      expect(steps, contains('filteringBooked'));
      expect(steps, contains('rankingPrice'));

      expect(data['understood'], isTrue);
      expect(data['blocked'], isFalse);
      expect(data['suggestions'], isEmpty);
      expect(data['unknownTerms'], isEmpty);
    });

    test('a constraints override skips re-parsing and scopes by district', () {
      final data = engine.run(
        store,
        query: 'irrelevant free text that would not parse to anything',
        language: 'en',
        constraintsOverride: {'district': 'Mirabad'},
      );
      final steps = (data['steps'] as List)
          .map((s) => (s as Map)['code'])
          .toList();
      expect(steps, contains('scanningDistrict'));
      expect(steps, contains('foundInDistrict'));
      final constraints = data['constraints'] as Map<String, dynamic>;
      expect(constraints['district'], 'Mirabad');
      final results = data['results'] as List;
      for (final r in results) {
        expect(r['district'], 'Mirabad');
      }
      // An explicit chip re-run is structured input: it is never blocked.
      expect(data['blocked'], isFalse);
      expect(data['understood'], isTrue);
    });

    test('an unmatched query returns zero results without throwing', () {
      final data = engine.run(
        store,
        query: '10 комнатная квартира до 1\$',
        language: 'ru',
      );
      expect((data['results'] as List), isEmpty);
      expect((data['totals'] as Map)['unitsMatched'], 0);
    });

    test('a query it does not understand is not searched at all', () {
      final data = engine.run(store, query: 'фывапр', language: 'ru');

      expect(data['blocked'], isTrue);
      expect(data['understood'], isFalse);
      expect(data['results'], isEmpty);
      expect(data['unknownTerms'], ['фывапр']);
      final constraints = data['constraints'] as Map<String, dynamic>;
      expect(constraints['unrecognized'], data['unknownTerms']);

      final totals = data['totals'] as Map<String, dynamic>;
      for (final key in [
        'projectsScanned',
        'projectsMatched',
        'unitsScanned',
        'unitsMatched',
        'bookedFiltered',
        'returned',
      ]) {
        expect(totals[key], 0, reason: '$key must stay at zero when blocked');
      }
      expect(totals['elapsedMs'], isA<int>());

      final steps = (data['steps'] as List).cast<Map>();
      expect(steps.map((s) => s['code']), ['parsing', 'noMatchIntent']);
      expect((steps.last['params'] as Map)['terms'], ['фывапр']);
    });

    test('a half-typed word is blocked but answered with "did you mean"', () {
      final data = engine.run(store, query: 'якк', language: 'ru');

      expect(data['blocked'], isTrue);
      final suggestions = (data['suggestions'] as List).cast<Map>();
      expect(suggestions, hasLength(1));
      expect(suggestions.single['term'], 'якк');
      expect(suggestions.single['suggestion'], 'Яккасарай');
      expect(suggestions.single['kind'], 'district');
      expect(suggestions.single['query'], 'Яккасарай');
      expect(suggestions.single['confidence'], greaterThan(0.5));
      expect(data['unknownTerms'], isEmpty);
    });

    test('a resolvable colloquialism is searched, not blocked', () {
      final data = engine.run(store, query: 'Двушка', language: 'ru');
      expect(data['blocked'], isFalse);
      expect(data['understood'], isTrue);
      expect((data['constraints'] as Map)['rooms'], [2]);
    });

    test('an autocorrected query reports what it read instead', () {
      final data = engine.run(
        store,
        query: 'rdfhnbhf в юнусабаде',
        language: 'ru',
      );
      final autocorrected = (data['steps'] as List)
          .cast<Map>()
          .where((s) => s['code'] == 'autocorrected')
          .toList();
      expect(autocorrected, hasLength(1));
      expect((autocorrected.single['params'] as Map)['from'], 'rdfhnbhf');
      expect((autocorrected.single['params'] as Map)['to'], 'квартира');
      expect((data['results'] as List), isNotEmpty);
    });

    test('an amenity nobody offers ranks instead of emptying the page', () {
      final data = engine.run(
        store,
        query: 'квартира с бассейном в Юнусабаде',
        language: 'ru',
      );

      final constraints = data['constraints'] as Map<String, dynamic>;
      expect(constraints['amenities'], isEmpty);
      expect(constraints['softAmenities'], ['pool']);
      expect((data['results'] as List), isNotEmpty);

      final softened = (data['steps'] as List)
          .cast<Map>()
          .where((s) => s['code'] == 'softenedAmenity')
          .toList();
      expect(softened, hasLength(1));
      expect((softened.single['params'] as Map)['amenity'], 'pool');

      final suggestions = (data['suggestions'] as List).cast<Map>();
      expect(suggestions.single['kind'], 'amenity');
      // Nothing to re-spell — the offer is to search without the pool.
      expect(suggestions.single['query'], 'квартира в Юнусабаде');
    });

    test('an amenity the catalogue does offer still filters', () {
      final data = engine.run(
        store,
        query: 'квартира с паркингом',
        language: 'ru',
      );
      expect((data['constraints'] as Map)['amenities'], ['parking']);
      expect((data['constraints'] as Map)['softAmenities'], isEmpty);
    });

    test('«без ремонта» is understood and searched, not blocked', () {
      final data = engine.run(store, query: 'без ремонта', language: 'ru');
      expect(data['blocked'], isFalse);
      expect(data['understood'], isTrue);
      final constraints = data['constraints'] as Map<String, dynamic>;
      expect(constraints['excludedAmenities'], ['renovation']);
      expect(constraints['amenities'], isEmpty);
      // Nothing in the test catalogue lists a renovation amenity, so nothing
      // is filtered out by the exclusion.
      expect((data['results'] as List), isNotEmpty);
      expect(data['unknownTerms'], isEmpty);
    });

    test('an excluded amenity filters out projects that offer it', () {
      // The residential project lists 'Parking'; the business centre does
      // not. «без паркинга» must therefore only return the office unit.
      final data = engine.run(store, query: 'без паркинга', language: 'ru');
      expect(data['blocked'], isFalse);
      final constraints = data['constraints'] as Map<String, dynamic>;
      expect(constraints['excludedAmenities'], ['parking']);
      final results = (data['results'] as List).cast<Map>();
      expect(results.map((r) => r['unitId']), ['unit-test-office']);
    });

    test('excludedAmenities round-trips through a constraints override', () {
      final data = engine.run(
        store,
        query: 'irrelevant',
        language: 'ru',
        constraintsOverride: {
          'excludedAmenities': ['parking'],
        },
      );
      final constraints = data['constraints'] as Map<String, dynamic>;
      expect(constraints['excludedAmenities'], ['parking']);
      final results = (data['results'] as List).cast<Map>();
      expect(results.map((r) => r['unitId']), ['unit-test-office']);
      expect(data['understood'], isTrue);
    });

    test('a single word of a project name no longer matches the project', () {
      final parsed = SmartSearchParser.analyze(
        'developer',
        catalogue: CatalogueVocabulary.fromProjects(store.publishedProjects),
      );
      expect(parsed.constraints.developerName, isNull);
      expect(parsed.constraints.projectName, isNull);
      // The full name still resolves.
      final full = SmartSearchParser.parse(
        'test developer',
        catalogue: CatalogueVocabulary.fromProjects(store.publishedProjects),
      );
      expect(full.developerName, 'Test Developer');
    });

    test('a leftover word downgrades to a hint without blocking', () {
      final data = engine.run(
        store,
        query: 'квартира в юнусабаде якк',
        language: 'ru',
      );
      expect(data['blocked'], isFalse);
      final lowConfidence = (data['steps'] as List)
          .cast<Map>()
          .where((s) => s['code'] == 'lowConfidence')
          .toList();
      expect(lowConfidence, hasLength(1));
      expect((lowConfidence.single['params'] as Map)['count'], 1);
      expect((lowConfidence.single['params'] as Map)['terms'], ['якк']);
    });
  });
}
