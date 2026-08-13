import 'package:test/test.dart';

import '../lib/src/validation.dart';

void main() {
  group('normalizePhone', () {
    test('strips spaces, dashes, and parentheses', () {
      expect(normalizePhone('+998 90 330 64 16'), '+998903306416');
      expect(normalizePhone('+998-90-330-64-16'), '+998903306416');
      expect(normalizePhone(' +998903306416 '), '+998903306416');
    });
  });

  group('isValidPhone', () {
    test('accepts +998-style numbers with formatting', () {
      expect(isValidPhone('+998 90 123 45 67'), isTrue);
      expect(isValidPhone('+998901234567'), isTrue);
      expect(isValidPhone('998901234567'), isTrue);
    });

    test('rejects null, empty, and malformed values', () {
      expect(isValidPhone(null), isFalse);
      expect(isValidPhone(''), isFalse);
      expect(isValidPhone('not-a-phone'), isFalse);
      expect(isValidPhone('123'), isFalse);
    });
  });

  group('isValidInn / isValidPinfl', () {
    test('accepts 9-digit INN and 14-digit PINFL', () {
      expect(isValidInn('301234567'), isTrue);
      expect(isValidInn('301 234 567'), isTrue);
      expect(isValidInn('12345'), isFalse);
      expect(isValidPinfl('30101123456789'), isTrue);
      expect(isValidPinfl('301'), isFalse);
    });
  });

  group('capString', () {
    test('returns the string unchanged when within the limit', () {
      expect(capString('hello', 10), 'hello');
    });

    test('returns null when missing or too long', () {
      expect(capString(null, 10), isNull);
      expect(capString('this is way too long', 5), isNull);
    });
  });

  group('isOneOf', () {
    test('true only for present, allowed values', () {
      expect(isOneOf('new', {'new', 'contacted'}), isTrue);
      expect(isOneOf('unknown', {'new', 'contacted'}), isFalse);
      expect(isOneOf(null, {'new', 'contacted'}), isFalse);
    });
  });

  group('sanitizeText', () {
    test('returns null only for null input', () {
      expect(sanitizeText(null), isNull);
      expect(sanitizeText(''), '');
    });

    test('strips HTML/script tags and their leftover brackets', () {
      expect(
        sanitizeText('<script>alert(1)</script>Nice flat'),
        'alert(1)Nice flat',
      );
      expect(sanitizeText('<img src=x onerror=alert(1)>Sunny'), 'Sunny');
      // `< b >` is consumed as a tag-like span; a trailing lone `<` is
      // stripped as a stray bracket.
      expect(sanitizeText('a < b > c'), 'a  c');
      expect(sanitizeText('5 < 10'), '5  10');
    });

    test('removes control characters but keeps tab/newline', () {
      expect(
        sanitizeText('line1\nline2\tend\u0000\u0007'),
        'line1\nline2\tend',
      );
    });

    test('is idempotent', () {
      const raw = '<b>Hello</b> & <i>world</i>\u0000';
      final once = sanitizeText(raw);
      expect(sanitizeText(once), once);
    });

    test('trims surrounding whitespace', () {
      expect(sanitizeText('  padded  '), 'padded');
    });
  });

  group('sanitizeTextList', () {
    test('returns null for non-list values', () {
      expect(sanitizeTextList(null), isNull);
      expect(sanitizeTextList('nope'), isNull);
    });

    test('sanitizes string entries and drops non-strings', () {
      expect(sanitizeTextList(['<b>pool</b>', 42, 'gym', null]), [
        'pool',
        'gym',
      ]);
    });
  });
}
