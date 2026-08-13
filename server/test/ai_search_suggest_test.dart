import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../lib/src/ai/search_suggester.dart';
import '../lib/src/app.dart';
import '../lib/src/store.dart';
import 'test_fixtures.dart';

void main() {
  group('SmartSearchSuggester', () {
    late Store store;
    final suggester = SmartSearchSuggester();

    setUp(() => store = createTestStore());
    tearDown(() => store.dispose());

    Map<String, dynamic> suggest(String query, {String language = 'ru'}) =>
        suggester.suggest(store, query: query, language: language);

    test('says nothing until there is something to go on', () {
      for (final query in ['', '  ', 'кв']) {
        final data = suggest(query);
        expect(data['completion'], isNull, reason: 'for "$query"');
        expect(data['completionFull'], isNull);
        expect(data['suggestions'], isEmpty);
      }
    });

    test('completes a half-typed word inline', () {
      final data = suggest('квартира в цен');
      expect(data['completion'], 'тре Ташкента');
      expect(data['completionFull'], 'квартира в центре Ташкента');
      final suggestions = (data['suggestions'] as List).cast<Map>();
      expect(suggestions.first['tail'], 'тре Ташкента');
      expect(suggestions.first['kind'], 'district');
    });

    test('keeps the casing the user is typing in', () {
      expect(suggest('КВАРТИРА В ЦЕН')['completion'], 'ТРЕ ТАШКЕНТА');
    });

    test('guesses the next clause after two whole words', () {
      final data = suggest('Нужна квартира');
      expect(data['completion'], ' в Юнусабаде');
      expect(data['completionFull'], 'Нужна квартира в Юнусабаде');
      // Best-stocked district first, and only districts that exist.
      final districts = (data['suggestions'] as List)
          .cast<Map>()
          .where((s) => s['kind'] == 'district')
          .map((s) => s['tail'])
          .toList();
      expect(districts, contains(' в Мирабаде'));
      expect(districts.length, lessThanOrEqualTo(3));
    });

    test('a half-typed name is finished even once it already parses', () {
      // «Юнусаб» is long enough for the parser to resolve to Yunusabad, and
      // the ghost text still has to finish the word the user is typing
      // instead of jumping to the next clause.
      final data = suggest('квартира в Юнусаб');
      expect(data['completion'], 'аде');
      expect(data['completionFull'], 'квартира в Юнусабаде');
    });

    test('a whole common noun is not "completed" into a synonym', () {
      // «офис» is a finished word, not a half-typed «офисное помещение», so
      // the field moves on to what the query is still missing.
      expect(suggest('офис')['completion'], ' в Юнусабаде');
    });

    test('one understood word is already enough to guess a clause', () {
      // «двушка» says as much as two words do; going quiet on it is what made
      // the predictions feel broken.
      expect(suggest('двушка')['completion'], ' в Юнусабаде');
      expect(suggest('офис')['completion'], ' в Юнусабаде');
    });

    test('one word it did not understand stays silent', () {
      final data = suggest('asdfgh');
      expect(data['completion'], isNull);
      expect(data['suggestions'], isEmpty);
    });

    test('moves on to the budget once a district is named', () {
      final data = suggest('2-комнатная в Юнусабаде');
      expect(data['completion'], ' до 90 000 \$');
      final kinds = (data['suggestions'] as List)
          .cast<Map>()
          .map((s) => s['kind'])
          .toList();
      expect(kinds, isNot(contains('district')));
      expect(kinds, isNot(contains('rooms')));
    });

    test('does not double a dangling preposition', () {
      final data = suggest('квартира в ');
      expect(data['completion'], 'Юнусабаде');
      expect(data['completionFull'], 'квартира в Юнусабаде');
    });

    test('answers in the requested language', () {
      expect(
        suggest('I need an apartment', language: 'en')['completion'],
        ' in Yunusabad',
      );
      expect(
        suggest('Kvartira kerak', language: 'uz')['completion'],
        ' Yunusobodda',
      );
    });

    test('phrases the completion in the language of the query', () {
      // The tail is glued onto the user's own words, so a Russian query in an
      // Uzbek interface must not come back as «квартира с avtoturargoh bilan».
      expect(suggest('квартира с ', language: 'uz')['completion'], 'паркингом');
      expect(
        suggest('квартира до ', language: 'en')['completion'],
        '90 000 \$',
      );
      expect(
        suggest('Kvartira kerak', language: 'ru')['completion'],
        ' Yunusobodda',
      );
      expect(
        suggest('I need an apartment', language: 'ru')['completion'],
        ' in Yunusabad',
      );
    });

    test('a dangling «с» completes to an amenity, not a district', () {
      final data = suggest('квартира с ');
      final suggestions = (data['suggestions'] as List).cast<Map>();
      expect(suggestions, isNotEmpty);
      expect(suggestions.first['kind'], 'amenity');
      expect(data['completion'], 'паркингом');
      expect(data['completionFull'], 'квартира с паркингом');
      expect(suggestions.map((s) => s['kind']), isNot(contains('district')));
    });

    test('a dangling «до» completes to a price, not a place', () {
      final data = suggest('квартира до ');
      final suggestions = (data['suggestions'] as List).cast<Map>();
      expect(suggestions, isNotEmpty);
      for (final s in suggestions) {
        expect(s['kind'], 'price');
      }
      expect(data['completion'], '90 000 \$');
    });

    test('a dangling «рядом» completes to a proximity amenity', () {
      final data = suggest('квартира рядом ');
      final suggestions = (data['suggestions'] as List).cast<Map>();
      expect(suggestions, isNotEmpty);
      expect(suggestions.first['kind'], 'amenity');
      expect(data['completionFull'], 'квартира рядом с метро');
    });

    test('«двушка в » suggests districts and never rooms', () {
      final data = suggest('двушка в ');
      final suggestions = (data['suggestions'] as List).cast<Map>();
      expect(suggestions, isNotEmpty);
      expect(suggestions.first['kind'], 'district');
      expect(suggestions.map((s) => s['kind']), isNot(contains('rooms')));
    });

    test('an office query never gets room-count suggestions', () {
      for (final query in ['офис в Мирабаде', 'офис в аренду']) {
        final data = suggest(query);
        final kinds = (data['suggestions'] as List)
            .cast<Map>()
            .map((s) => s['kind'])
            .toList();
        expect(kinds, isNot(contains('rooms')), reason: 'for "$query"');
        expect(kinds, isNot(contains('unitKind')), reason: 'for "$query"');
      }
    });

    test('never suggests what the query already says', () {
      final data = suggest('квартира с паркингом ');
      final texts = (data['suggestions'] as List)
          .cast<Map>()
          .map((s) => s['tail'] as String)
          .toList();
      for (final tail in texts) {
        expect(tail.toLowerCase(), isNot(contains('паркинг')));
      }
    });

    test('only offers projects and developers that exist', () {
      final texts = (suggest('квартира в ')['suggestions'] as List)
          .cast<Map>()
          .map((s) => s['tail'] as String)
          .toList();
      for (final text in texts) {
        expect(
          text,
          anyOf(
            contains('Юнусабаде'),
            contains('Мирабаде'),
            contains('Ташкента'),
            contains(testResidentialName),
            contains(testBusinessName),
            contains('Test Developer'),
          ),
        );
      }
    });
  });

  group('POST /v1/ai/search/suggest', () {
    late Store store;
    late Handler handler;

    setUp(() {
      store = createTestStore();
      handler = createHandler(store);
    });
    tearDown(() => store.dispose());

    Future<Map<String, dynamic>> post(Map<String, dynamic> body) async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/ai/search/suggest'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        ),
      );
      expect(response.statusCode, 200);
      return jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    }

    test('returns the completion envelope without spending quota', () async {
      final json = await post({
        'query': 'Нужна квартира в цен',
        'user_language': 'ru',
        'limit': 3,
      });
      expect(json['success'], isTrue);
      final data = json['data'] as Map<String, dynamic>;
      expect(data['completion'], 'тре Ташкента');
      expect(data['completionFull'], 'Нужна квартира в центре Ташкента');
      expect((data['suggestions'] as List).length, lessThanOrEqualTo(3));
      expect(json.containsKey('quota'), isFalse);
    });

    test('rejects an out-of-range limit with 422', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/ai/search/suggest'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'query': 'квартира', 'limit': 99}),
        ),
      );
      expect(response.statusCode, 422);
    });
  });
}
