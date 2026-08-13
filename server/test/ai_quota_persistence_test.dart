// AI quota ledger (`ai_usage`): live-DB persistence for bumpAiUsage/readAiUsage
// — the whole reason the table exists is that the in-memory RateLimiter
// fallback resets on every deploy/restart, handing out a fresh budget. This
// exercises the real SQL-backed path end to end (see AiQuota._read/_bump in
// ai/ai_quota.dart, which only falls back to RateLimiter when
// store.persistence is null).
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/src/db/database.dart';
import '../lib/src/db/pg_config.dart';
import '../lib/src/db/pg_persistence.dart';

void main() {
  final config = PgConfig.fromEnv(Platform.environment);

  group('ai_usage persistence (live DB)', () {
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

    test('bumpAiUsage increments and readAiUsage reflects it without '
        'depending on any in-memory state — a restart would reset the '
        'in-memory RateLimiter but must never reset this counter', () async {
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final key = 'ip-hash-$suffix';
      final day = DateTime.now().toUtc().toIso8601String().split('T').first;
      const kind = 'chat';

      // Nothing recorded yet for this fresh key.
      expect(await persistence.readAiUsage(key: key, day: day, kind: kind), 0);

      final first = await persistence.bumpAiUsage(
        key: key,
        day: day,
        kind: kind,
      );
      expect(first, 1);
      expect(await persistence.readAiUsage(key: key, day: day, kind: kind), 1);

      // A second "process" reading the same bucket (simulating what a
      // restarted server would see, since this is backed by the DB row and
      // not any process-local map) observes the same persisted count.
      final second = await persistence.bumpAiUsage(
        key: key,
        day: day,
        kind: kind,
      );
      expect(second, 2);
      expect(await persistence.readAiUsage(key: key, day: day, kind: kind), 2);

      // A different `kind` bucket for the same key/day is independent.
      expect(
        await persistence.readAiUsage(key: key, day: day, kind: 'search_h05'),
        0,
      );

      await db.execute(
        Sql.named(
          'DELETE FROM ai_usage WHERE ip_hash = @key AND day = @day::date',
        ),
        parameters: {
          'key': TypedValue(Type.text, key),
          'day': TypedValue(Type.text, day),
        },
      );
    });
  });
}
