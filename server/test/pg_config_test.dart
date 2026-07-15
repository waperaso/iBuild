import 'package:test/test.dart';

import '../lib/src/db/pg_config.dart';

void main() {
  group('PgConfig.fromEnv', () {
    test('returns null when DB_HOST is unset', () {
      expect(PgConfig.fromEnv({}), isNull);
    });

    test('returns null when DB_HOST is empty/whitespace', () {
      expect(PgConfig.fromEnv({'DB_HOST': ''}), isNull);
      expect(PgConfig.fromEnv({'DB_HOST': '   '}), isNull);
    });

    test('applies documented defaults when only DB_HOST is set', () {
      final config = PgConfig.fromEnv({'DB_HOST': 'localhost'})!;
      expect(config.host, 'localhost');
      expect(config.port, 5432);
      expect(config.database, 'ibuild');
      expect(config.username, 'postgres');
      expect(config.password, '');
      expect(config.useSsl, isFalse);
    });

    test('reads every DB_* var when all are set', () {
      final config = PgConfig.fromEnv({
        'DB_HOST': ' localhost ',
        'DB_PORT': '5433',
        'DB_NAME': 'ibuild_test',
        'DB_USER': 'postgres',
        'DB_PASSWORD': 'postgres',
        'DB_SSL': 'true',
      })!;
      expect(config.host, 'localhost');
      expect(config.port, 5433);
      expect(config.database, 'ibuild_test');
      expect(config.username, 'postgres');
      expect(config.password, 'postgres');
      expect(config.useSsl, isTrue);
    });

    test('DB_SSL is case-insensitive and defaults to false on garbage', () {
      expect(
        PgConfig.fromEnv({'DB_HOST': 'h', 'DB_SSL': 'TRUE'})!.useSsl,
        isTrue,
      );
      expect(
        PgConfig.fromEnv({'DB_HOST': 'h', 'DB_SSL': 'nonsense'})!.useSsl,
        isFalse,
      );
    });

    test('falls back to default port when DB_PORT is not a valid int', () {
      final config = PgConfig.fromEnv({
        'DB_HOST': 'h',
        'DB_PORT': 'not-a-number',
      })!;
      expect(config.port, 5432);
    });
  });
}
