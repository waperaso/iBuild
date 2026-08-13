import 'package:test/test.dart';

import '../lib/src/ai/smart_search_engine.dart';

/// The number-bearing half of a query — room counts, budgets, areas and floors
/// — is read by regex rather than by the dictionary, so it needs its own
/// regression net. Every case below is a phrasing that used to be parsed into
/// the wrong field entirely (a budget becoming a floor, an area becoming a
/// price), which is far worse than not understanding it at all.
void main() {
  group('room counts', () {
    test('the genitive infix between digit and noun is optional', () {
      expect(SmartSearchParser.parse('2-х комнатная').rooms, {2});
      expect(SmartSearchParser.parse('2х комнатная').rooms, {2});
      expect(SmartSearchParser.parse('3-х комнатную квартиру').rooms, {3});
      expect(SmartSearchParser.parse('4 х комнатная').rooms, {4});
    });
  });

  group('budgets', () {
    test('«не» flips a comparative into a ceiling', () {
      final cheaper = SmartSearchParser.parse('не дороже 80 тысяч');
      expect(cheaper.priceMax, 80000);
      expect(cheaper.priceMin, isNull);
      expect(SmartSearchParser.parse('не больше 90000').priceMax, 90000);
      expect(SmartSearchParser.parse('не более 90 тысяч').priceMax, 90000);
    });

    test('a bare comparative is still a floor', () {
      final pricier = SmartSearchParser.parse('дороже 80 тысяч');
      expect(pricier.priceMin, 80000);
      expect(pricier.priceMax, isNull);
    });

    test('the Russian million and billion words scale the amount', () {
      final million = SmartSearchParser.parse('до 900 миллионов сум');
      expect(million.priceMax, 900000000);
      expect(million.currency, 'UZS');
      expect(SmartSearchParser.parse('1 миллион сум').priceMax, 1000000);
      expect(
        SmartSearchParser.parse('до 1 миллиарда сум').priceMax,
        1000000000,
      );
    });

    test('a range keeps the magnitude on both ends', () {
      final range = SmartSearchParser.parse(
        'от 500 миллионов до 900 миллионов сум',
      );
      expect(range.priceMin, 500000000);
      expect(range.priceMax, 900000000);
      expect(range.currency, 'UZS');
    });
  });

  group('area', () {
    test('naming the field up front makes the unit optional', () {
      expect(SmartSearchParser.parse('площадь от 60').areaMin, 60);
      expect(SmartSearchParser.parse('метраж до 90').areaMax, 90);
      expect(SmartSearchParser.parse('maydoni 85').areaMin, 85);
    });

    test('the cue word is consumed, not reported as unknown', () {
      final c = SmartSearchParser.parse('площадью 85 кв.м');
      expect(c.areaMin, 85);
      expect(c.unrecognized, isEmpty);
    });

    test('an area cue never leaks into the budget', () {
      final c = SmartSearchParser.parse('площадь от 60');
      expect(c.priceMin, isNull);
      expect(c.priceMax, isNull);
    });
  });

  group('floors', () {
    test('a refusal after the noun is still a refusal', () {
      expect(
        SmartSearchParser.parse('первый этаж не предлагать').notFirstFloor,
        true,
      );
      expect(
        SmartSearchParser.parse('последний этаж не нужен').notLastFloor,
        true,
      );
      expect(
        SmartSearchParser.parse('кроме первого этажа').notFirstFloor,
        true,
      );
      expect(
        SmartSearchParser.parse('без последнего этажа').notLastFloor,
        true,
      );
      expect(
        SmartSearchParser.parse('birinchi qavat kerak emas').notFirstFloor,
        true,
      );
      expect(SmartSearchParser.parse('no ground floor').notFirstFloor, true);
    });

    test('a refusal is not read as an exact floor', () {
      final c = SmartSearchParser.parse('первый этаж не предлагать');
      expect(c.floorMin, isNull);
      expect(c.floorMax, isNull);
    });

    test('«не на N этаже» excludes that floor by number, not by position', () {
      expect(
        SmartSearchParser.parse('квартира не на 2 этаже').excludeFloors,
        {2},
      );
      expect(
        SmartSearchParser.parse('квартира не 4 этаж').excludeFloors,
        {4},
      );
      expect(
        SmartSearchParser.parse('5 этаж не подходит').excludeFloors,
        {5},
      );
      expect(SmartSearchParser.parse('2 qavatda emas').excludeFloors, {2});
      expect(SmartSearchParser.parse('not floor 3').excludeFloors, {3});
    });

    test('«не на N этаже» is not also read as an exact floor', () {
      final c = SmartSearchParser.parse('квартира не на 2 этаже');
      expect(c.floorMin, isNull);
      expect(c.floorMax, isNull);
    });

    test('«не выше N» is a floor ceiling, «выше N» is a floor minimum', () {
      expect(SmartSearchParser.parse('этаж не выше 9').floorMax, 9);
      expect(SmartSearchParser.parse('выше 10 этажа').floorMin, 11);
    });

    test('a money phrase after «выше» stays a budget', () {
      for (final query in [
        'не выше 100 тысяч',
        'не выше 90к',
        'не выше 50 000',
      ]) {
        final c = SmartSearchParser.parse(query);
        expect(c.priceMax, isNotNull, reason: query);
        expect(c.floorMin, isNull, reason: query);
        expect(c.floorMax, isNull, reason: query);
      }
    });

    test('a floor and a budget in one query stay in their own fields', () {
      final c = SmartSearchParser.parse('квартира выше 5 этажа до 90 тысяч');
      expect(c.floorMin, 6);
      expect(c.priceMax, 90000);
    });
  });
}
