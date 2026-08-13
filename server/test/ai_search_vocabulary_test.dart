import 'package:test/test.dart';

import '../lib/src/ai/smart_search_engine.dart';
import '../lib/src/store.dart';
import 'test_fixtures.dart';

/// Guards the vocabulary itself rather than the parser's regexes: every
/// phrasing below used to come back as `unrecognized` (or as a sub-0.9 "did
/// you mean") because the surface form simply was not in the dictionary.
void main() {
  group('vocabulary — Russian room declensions', () {
    test('the «N-комнатная» adjective resolves in every case', () {
      expect(SmartSearchParser.parse('трёхкомнатной').rooms, {3});
      expect(SmartSearchParser.parse('пятикомнатной').rooms, {5});
      expect(SmartSearchParser.parse('четырёхкомнатной').rooms, {4});
      expect(SmartSearchParser.parse('однокомнатного').rooms, {1});
      expect(SmartSearchParser.parse('двухкомнатным').rooms, {2});
      expect(SmartSearchParser.parse('шестикомнатная').rooms, {6});
    });

    test('«трёхкомнатных квартир» reports nothing as unknown', () {
      final c = SmartSearchParser.parse('трёхкомнатных квартир');
      expect(c.rooms, {3});
      expect(c.unitKind, 'apartment');
      expect(c.unrecognized, isEmpty);
    });

    test('the numeral in the instrumental is a room count', () {
      expect(SmartSearchParser.parse('с одной комнатой').rooms, {1});
      expect(SmartSearchParser.parse('с двумя комнатами').rooms, {2});
      expect(SmartSearchParser.parse('с тремя комнатами').rooms, {3});
      expect(SmartSearchParser.parse('с четырьмя комнатами').rooms, {4});
      expect(SmartSearchParser.parse('с пятью комнатами').rooms, {5});
      expect(
        SmartSearchParser.parse('квартира с двумя комнатами').unrecognized,
        isEmpty,
      );
    });

    test('colloquial room names decline too', () {
      expect(SmartSearchParser.parse('однушке').rooms, {1});
      expect(SmartSearchParser.parse('двушечку').rooms, {2});
      expect(SmartSearchParser.parse('трёшке').rooms, {3});
      expect(SmartSearchParser.parse('четырёшки').rooms, {4});
      expect(SmartSearchParser.parse('пятерки').rooms, {5});
    });

    test('the genitive infix the digit regex does not spell out', () {
      // The parser's digit pass covers «2-х»/«2х»; «1-но» and «5-ти» are
      // carried by the dictionary instead.
      expect(SmartSearchParser.parse('1-но комнатная').rooms, {1});
      expect(SmartSearchParser.parse('5-ти комнатная').rooms, {5});
      expect(SmartSearchParser.parse('2-ух комнатную').rooms, {2});
    });
  });

  group('vocabulary — Uzbek and English room parity', () {
    test('uz numerals and «xona» suffixes', () {
      expect(SmartSearchParser.parse('uch xona').rooms, {3});
      expect(SmartSearchParser.parse('3 xonalik kvartira').rooms, {3});
      expect(SmartSearchParser.parse("to'rt xonadan").rooms, {4});
      expect(SmartSearchParser.parse('olti xonali').rooms, {6});
    });

    test('en shorthands', () {
      expect(SmartSearchParser.parse('four bedrooms').rooms, {4});
      expect(SmartSearchParser.parse('3 bhk').rooms, {3});
      expect(SmartSearchParser.parse('3-bed').rooms, {3});
      expect(SmartSearchParser.parse('six bedroom apartment').rooms, {6});
    });
  });

  group('vocabulary — district adjectives', () {
    test('every district resolves in every adjective case', () {
      const endings = [
        'ого',
        'ому',
        'ом',
        'им',
        'ими',
        'ая',
        'ой',
        'ую',
        'ие',
        'их',
      ];
      for (final district in kSearchDistrictEntries) {
        final nominative = district.aliases.firstWhere(
          (a) => a.endsWith('ский'),
          orElse: () => '',
        );
        expect(
          nominative,
          isNotEmpty,
          reason: '${district.canonical} has no adjective to derive from',
        );
        final stem = nominative.substring(0, nominative.length - 2);
        for (final ending in endings) {
          final query = '$stem$ending район';
          expect(
            SmartSearchParser.parse(query).district,
            district.canonical,
            reason: query,
          );
        }
      }
    });

    test('the failures that motivated the generator', () {
      expect(
        SmartSearchParser.parse('чиланзарского района').district,
        'Chilanzar',
      );
      expect(SmartSearchParser.parse('юнусабадского').district, 'Yunusabad');
      expect(SmartSearchParser.parse('яккасарайскую').district, 'Yakkasaray');
      expect(SmartSearchParser.parse('бектемирского').district, 'Bektemir');
    });

    test('a hyphenated multi-word name declines as well', () {
      final c = SmartSearchParser.parse('мирзо-улугбекского района');
      expect(c.district, 'Mirzo Ulugbek');
      expect(c.unrecognized, isEmpty);
    });
  });

  group('vocabulary — amenities that used to be unknown words', () {
    test('a watched, fenced courtyard reads as security', () {
      for (final query in [
        'закрытая территория',
        'охраняемая территория',
        'территория под охраной',
        'видеонаблюдение',
        'камеры',
        'кпп',
        'yopiq hudud',
        'gated community',
      ]) {
        final c = SmartSearchParser.parse(query);
        expect(c.amenities, {'security'}, reason: query);
        expect(c.unrecognized, isEmpty, reason: query);
      }
    });

    test('"a parking space of my own" is still just parking', () {
      for (final query in [
        'своя парковка',
        'собственная парковка',
        'паркоместо',
        'garaj',
        'parking space',
      ]) {
        final c = SmartSearchParser.parse(query);
        expect(c.amenities, {'parking'}, reason: query);
        expect(c.unrecognized, isEmpty, reason: query);
      }
    });

    test('a storage room is a wish, not an unknown word', () {
      for (final query in [
        'кладовка',
        'кладовая',
        'omborcha',
        'ombor xonasi',
        'storage room',
      ]) {
        final c = SmartSearchParser.parse(query);
        expect(c.amenities, {'storage'}, reason: query);
        expect(c.unrecognized, isEmpty, reason: query);
      }
      // «ombor» and «omborxona» both name a warehouse: that is real inventory
      // vocabulary and must not be swallowed by the new amenity.
      expect(SmartSearchParser.parse('ombor').unitKind, 'commercial');
      expect(SmartSearchParser.parse('omborxona').unitKind, 'commercial');
    });

    test('underfloor heating resolves in all three languages', () {
      for (final query in [
        'теплый пол',
        'тёплые полы',
        'underfloor heating',
        'issiq pol',
      ]) {
        final c = SmartSearchParser.parse(query);
        expect(c.amenities, {'underfloor heating'}, reason: query);
        expect(c.unrecognized, isEmpty, reason: query);
      }
    });

    test('uz «qurilgan» is a new build', () {
      for (final query in [
        'qurilgan',
        'yangi qurilgan',
        'qurilmoqda',
        'yangi uy',
      ]) {
        final c = SmartSearchParser.parse(query);
        expect(c.isOffplan, isTrue, reason: query);
        expect(c.unrecognized, isEmpty, reason: query);
      }
    });

    test('the new-build words leave the property noun alone', () {
      // «yangi qurilgan uy» has to yield both facts: a home, and a new one.
      final c = SmartSearchParser.parse('yangi qurilgan uy');
      expect(c.unitKind, 'apartment');
      expect(c.isOffplan, isTrue);
      // …and the district still outranks the bare adjective inside its name.
      final district = SmartSearchParser.parse('Yangi Hayotda yangi uy');
      expect(district.district, 'Yangihayot');
      expect(district.isOffplan, isTrue);
    });
  });

  group('vocabulary — filler words and misspellings', () {
    test('words that carry no constraint are swallowed silently', () {
      final parsed = SmartSearchParser.analyze(
        'Интересует своя территория, рассмотрю варианты, срочно, пожалуйста',
      );
      expect(parsed.constraints.unrecognized, isEmpty);
      expect(parsed.suggestions, isEmpty);
    });

    test('filler never outranks the phrase it is part of', () {
      // «своя» and «территория» are noise on their own; paired they are the
      // amenity, and the phrase pass has to win.
      expect(SmartSearchParser.parse('своя парковка').amenities, {'parking'});
      expect(SmartSearchParser.parse('закрытая территория').amenities, {
        'security',
      });
    });

    test('short misspellings resolve without a "did you mean" detour', () {
      for (final query in ['офиз', 'офиис', 'оффис', 'ofic']) {
        expect(
          SmartSearchParser.parse(query).unitKind,
          'commercial',
          reason: query,
        );
      }
      for (final query in ['аренад', 'арнеда', 'аренду']) {
        expect(SmartSearchParser.parse(query).dealType, 'rent', reason: query);
      }
      for (final query in ['студья', 'стюдия', 'студя']) {
        expect(SmartSearchParser.parse(query).rooms, {0}, reason: query);
      }
      for (final query in ['кварира', 'квртира', 'квортиру', 'кватиру']) {
        expect(
          SmartSearchParser.parse(query).unitKind,
          'apartment',
          reason: query,
        );
      }
    });

    test('an exact alias never reports itself as an autocorrection', () {
      // The point of adding these spellings is that the user is not told
      // their query was rewritten.
      for (final query in ['офиз', 'кварира', 'студья']) {
        expect(
          SmartSearchParser.analyze(query).autocorrections,
          isEmpty,
          reason: query,
        );
      }
    });
  });

  group('vocabulary — end to end', () {
    late Store store;
    final engine = SmartSearchEngine();

    setUp(() => store = createTestStore());

    test('a storage wish ranks instead of emptying the page', () {
      final data = engine.run(
        store,
        query: 'квартира с кладовкой в Юнусабаде',
        language: 'ru',
      );
      final constraints = data['constraints'] as Map<String, dynamic>;
      expect(constraints['amenities'], isEmpty);
      expect(constraints['softAmenities'], ['storage']);
      expect((data['results'] as List), isNotEmpty);
      expect(data['unknownTerms'], isEmpty);
    });

    test('a declined district plus a declined room count is searched', () {
      final data = engine.run(
        store,
        query: 'двухкомнатную в юнусабадском районе',
        language: 'ru',
      );
      expect(data['blocked'], isFalse);
      final constraints = data['constraints'] as Map<String, dynamic>;
      expect(constraints['rooms'], [2]);
      expect(constraints['district'], 'Yunusabad');
      expect(data['unknownTerms'], isEmpty);
      expect((data['results'] as List), isNotEmpty);
    });
  });
}
