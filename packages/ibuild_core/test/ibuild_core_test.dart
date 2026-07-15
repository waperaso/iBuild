import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild_core/ibuild_core.dart';

void main() {
  group('ApiEnvelope', () {
    test('unwraps a { data: ... } envelope', () {
      expect(
        ApiEnvelope.unwrap({
          'success': true,
          'data': {'id': '1'},
        }),
        {'id': '1'},
      );
    });

    test('passes through an already-unwrapped body', () {
      expect(ApiEnvelope.unwrap({'id': '1'}), {'id': '1'});
    });

    test('asList filters non-objects', () {
      final list = ApiEnvelope.asList({
        'data': [
          {'id': '1'},
          'nope',
          {'id': '2'},
        ],
      });
      expect(list, hasLength(2));
      expect(list.first['id'], '1');
    });

    test('asObject returns null for a non-object payload', () {
      expect(ApiEnvelope.asObject({'data': 5}), isNull);
    });
  });

  group('ApiException', () {
    test('flags 401 as unauthorized', () {
      const err = ApiException('nope', statusCode: 401);
      expect(err.isUnauthorized, isTrue);
    });
  });

  group('JsonReaders', () {
    test('coerces loosely-typed values', () {
      final json = <String, dynamic>{
        'count': '7',
        'ratio': '1.5',
        'flag': 'true',
        'name': 42,
      };
      expect(json.intOr('count'), 7);
      expect(json.doubleOr('ratio'), 1.5);
      expect(json.boolOr('flag'), isTrue);
      expect(json.stringOr('name'), '42');
      expect(json.optInt('missing'), isNull);
      expect(json.intOr('missing', 3), 3);
    });
  });

  group('AppColors', () {
    test('lerp blends toward the target', () {
      const a = AppColors(
        brightness: Brightness.light,
        background: Color(0xFF000000),
        surface: Color(0xFF000000),
        surfaceAlt: Color(0xFF000000),
        accent: Color(0xFF000000),
        onAccent: Color(0xFF000000),
        accentSecondary: Color(0xFF000000),
        onAccentSecondary: Color(0xFF000000),
        heroSurface: Color(0xFF000000),
        onHeroSurface: Color(0xFF000000),
        ink: Color(0xFF000000),
        inkMuted: Color(0xFF000000),
        outline: Color(0xFF000000),
        success: Color(0xFF000000),
        warning: Color(0xFF000000),
        danger: Color(0xFF000000),
        unitAvailable: Color(0xFF000000),
        unitReserved: Color(0xFF000000),
        unitSold: Color(0xFF000000),
        unitBlocked: Color(0xFF000000),
      );
      final b = a.copyWith(background: const Color(0xFFFFFFFF));
      final mid = a.lerp(b, 1.0);
      expect(mid.background, const Color(0xFFFFFFFF));
    });
  });
}
