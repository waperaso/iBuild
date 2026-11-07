import 'dart:async';
import 'dart:io';

import 'package:ibuild_server/ibuild_server.dart';

Future<void> main() async {
  final env = AppEnv.load();
  final problems = env.production ? env.productionProblems() : env.secretProblems;
  if (problems.isNotEmpty) {
    stderr.writeln('Запуск остановлен:');
    for (final problem in problems) {
      stderr.writeln(' - $problem');
    }
    exit(78);
  }
  final db = await AppDatabase.open(env.databaseUrl);
  await db.migrate(env.migrationsDir);
  if (env.seedOnStart) {
    await seedIfEmpty(db, env.seedPassword);
    await seedPilotBudgetIfMissing(db, env.seedPassword);
    await ensurePlatformAdmin(db, env.seedPassword);
    await ensureBankCabinet(db, env.seedPassword);
    if (!env.demoEnabled) await seedDemoApplications(db);
  }
  if (env.demoEnabled) await seedDemoWorld(db);
  Vault.configure(env.mailKey);
  if (await sealLegacyMail(db) > 0) stdout.writeln('Старые письма в очереди зашифрованы');
  await bankReconcile(db);
  final handler = buildHandler(db: db, env: env);
  final server = await serveApi(handler, env.host, env.port);
  stdout.writeln('iBuild API on http://${server.address.host}:${server.port}');
  final mailing = Timer.periodic(const Duration(minutes: 15), (_) async {
    try {
      await runReportSchedules(db);
    } catch (error) {
      stderr.writeln('Рассылка отчётов: $error');
    }
  });
  var stopping = false;
  Future<void> stop(ProcessSignal signal) async {
    if (stopping) return;
    stopping = true;
    mailing.cancel();
    stdout.writeln('Получен ${signal.name}: заканчиваю запросы и закрываю базу');
    await server.close().timeout(const Duration(seconds: 20), onTimeout: () => server.close(force: true));
    await db.close();
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen(stop);
  ProcessSignal.sigint.watch().listen(stop);
}
