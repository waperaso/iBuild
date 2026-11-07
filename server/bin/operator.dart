import 'dart:io';

import 'package:ibuild_server/ibuild_server.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help')) {
    stderr.writeln('''
Операторские учётные записи. Экрана регистрации нет.

  dart run bin/operator.dart create --inn 300000001 --login pilot.user --name "Имя" --password "secret"
  dart run bin/operator.dart reset-password --login pilot.user --password "secret"
  dart run bin/operator.dart bootstrap-admin --login admin --name "Имя" --password "не короче 12 знаков"
  dart run bin/operator.dart set-active --login pilot.user --active false
''');
    exit(args.contains('--help') ? 0 : 64);
  }
  final command = args.first;
  final flags = _flags(args.skip(1).toList());
  final env = AppEnv.load();
  final problems = env.production ? env.productionProblems() : env.secretProblems;
  if (problems.isNotEmpty) {
    for (final problem in problems) {
      stderr.writeln(problem);
    }
    exit(78);
  }
  final db = await AppDatabase.open(env.databaseUrl);
  try {
    await db.migrate(env.migrationsDir);
    switch (command) {
      case 'create':
        await _create(db, flags);
      case 'reset-password':
        await _reset(db, flags);
      case 'set-active':
        await _active(db, flags);
      case 'bootstrap-admin':
        await _bootstrapAdmin(db, flags);
      default:
        stderr.writeln('Неизвестная команда: $command');
        exit(64);
    }
  } finally {
    await db.close();
  }
}

Future<void> _create(AppDatabase db, Map<String, String> flags) async {
  final inn = _required(flags, 'inn');
  final login = _required(flags, 'login');
  final name = _required(flags, 'name');
  final password = _required(flags, 'password');
  final companyId = await db.companyIdByInn(inn);
  if (companyId == null) {
    stderr.writeln('Компания с ИНН $inn не найдена');
    exit(1);
  }
  try {
    final id = await db.insertUser(
      companyId: companyId,
      name: name,
      login: login,
      passwordHash: hashPassword(password),
    );
    stdout.writeln('Создан пользователь $login ($id). Назначение на объект — отдельным шагом.');
  } catch (error) {
    stderr.writeln('Не удалось создать учётную запись: $error');
    exit(1);
  }
}

/// The first administrator of a production platform: nobody can sign up for it.
Future<void> _bootstrapAdmin(AppDatabase db, Map<String, String> flags) async {
  final login = _required(flags, 'login');
  final name = _required(flags, 'name');
  final password = _required(flags, 'password');
  if (password.length < 12) {
    stderr.writeln('Пароль администратора: не короче 12 знаков');
    exit(64);
  }
  final inn = flags['inn'] ?? '000000000';
  final companyId = await db.companyIdByInn(inn) ??
      await db.insertCompany(name: flags['company'] ?? 'iBuild', inn: inn, contact: flags['contact'] ?? '');
  if (await db.userByLogin(login) == null) {
    await db.insertUser(companyId: companyId, name: name, login: login, passwordHash: hashPassword(password));
  } else {
    await db.setPasswordHash(login, hashPassword(password));
  }
  await db.setPlatformAdmin(login, true);
  stdout.writeln('Администратор платформы: $login');
}

Future<void> _reset(AppDatabase db, Map<String, String> flags) async {
  final login = _required(flags, 'login');
  final password = _required(flags, 'password');
  final user = await db.userByLogin(login);
  if (user == null) {
    stderr.writeln('Пользователь $login не найден');
    exit(1);
  }
  await db.setPasswordHash(login, hashPassword(password));
  stdout.writeln('Пароль обновлён для $login');
}

Future<void> _active(AppDatabase db, Map<String, String> flags) async {
  final login = _required(flags, 'login');
  final active = _required(flags, 'active');
  if (active != 'true' && active != 'false') {
    stderr.writeln('--active принимает true или false');
    exit(64);
  }
  final user = await db.userByLogin(login);
  if (user == null) {
    stderr.writeln('Пользователь $login не найден');
    exit(1);
  }
  await db.setActive(login, active == 'true');
  stdout.writeln('$login active=$active');
}

Map<String, String> _flags(List<String> args) {
  final flags = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) continue;
    final key = arg.substring(2);
    if (i + 1 >= args.length) {
      stderr.writeln('Нет значения для --$key');
      exit(64);
    }
    flags[key] = args[++i];
  }
  return flags;
}

String _required(Map<String, String> flags, String key) {
  final value = flags[key];
  if (value == null || value.isEmpty) {
    stderr.writeln('Нужен --$key');
    exit(64);
  }
  return value;
}
