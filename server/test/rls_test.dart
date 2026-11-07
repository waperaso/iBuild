import 'package:ibuild_server/ibuild_server.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

const password = 'Pilot-2026-demo';
const testDatabaseUrl =
    'postgres://ibuild:ibuild@localhost:5433/ibuild_test?sslmode=disable';

void main() {
  late AppDatabase db;
  late Connection lock;

  setUpAll(() async {
    final admin = Pool.withUrl(
      'postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable',
    );
    try {
      final existing = await admin.execute(
        "SELECT 1 FROM pg_database WHERE datname = 'ibuild_test'",
      );
      if (existing.isEmpty) await admin.execute('CREATE DATABASE ibuild_test');
    } finally {
      await admin.close();
    }
    lock = await Connection.openFromUrl(testDatabaseUrl);
    await lock.execute('SELECT pg_advisory_lock(424242)');
    db = await AppDatabase.open(testDatabaseUrl);
    await db.migrate('migrations');
    await db.truncateAll();
    await seedDemo(db, password);
  });

  tearDownAll(() async {
    await db.close();
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
  });

  test('row security hides other tenants and other budget lines', () async {
    final ownerProjects = await db.owner.execute('SELECT count(*) FROM projects');
    expect(ownerProjects.first[0], 2);

    expect(await db.visibleProjectCount(), 0);

    final director = (await db.userIdByLogin('a.director'))!;
    final other = (await db.userIdByLogin('b.director'))!;
    final mason = (await db.userIdByLogin('a.contractor'))!;
    expect(await db.visibleProjectCount(userId: director), 1);
    expect(await db.visibleProjectCount(userId: other), 1);

    final lines = await db.asUser(mason, () async {
      final rows = await db.pool.execute('SELECT count(*) FROM budget_items');
      return rows.first[0];
    });
    expect(lines, 3);

    final foreign = await db.asUser(director, () async {
      final rows = await db.pool.execute(
        "SELECT count(*) FROM projects WHERE name = 'ЖК Чиланзар'",
      );
      return rows.first[0];
    });
    expect(foreign, 0);
  });
}
