import 'dart:io';

import 'http_util.dart';
import 'vault.dart';

class AppEnv {
  AppEnv({
    required this.databaseUrl,
    required this.host,
    required this.port,
    required this.seedOnStart,
    required this.seedPassword,
    required this.webRoot,
    required this.cookieSecure,
    required this.migrationsDir,
    required this.sessionTtl,
    required this.loginFailureLimit,
    required this.loginWindow,
    this.fileRoot = 'data/files',
    this.registrationPerHour = 5,
    this.production = false,
    this.demoEnabled = false,
    this.demoSessionTtl = const Duration(hours: 2),
    this.maxBodyBytes = 12 * 1024 * 1024,
    this.mailKey = '',
    this.trustProxy = false,
    this.secretProblems = const [],
  });

  final String databaseUrl;
  final String host;
  final int port;
  final bool seedOnStart;
  final String seedPassword;
  final String? webRoot;
  final bool cookieSecure;
  final String migrationsDir;
  final Duration sessionTtl;
  final int loginFailureLimit;
  final Duration loginWindow;
  final String fileRoot;
  final int registrationPerHour;
  final bool production;
  final bool demoEnabled;
  final Duration demoSessionTtl;
  final int maxBodyBytes;

  /// Key that seals letters, 32 bytes in base64. Empty only in development.
  final String mailKey;

  /// Trust X-Forwarded-For only behind the production proxy, which replaces it.
  final bool trustProxy;

  /// A secret given both as a variable and as a file, or a file that cannot be read.
  final List<String> secretProblems;

  /// What is wrong with the settings of a production start. Empty when all is well.
  List<String> productionProblems() {
    if (!production) return const [];
    final problems = <String>[...secretProblems];
    if (mailKey.isEmpty) {
      problems.add('MAIL_KEY не задан: письма нечем шифровать (openssl rand -base64 32)');
    } else if (!Vault.validKey(mailKey)) {
      problems.add('MAIL_KEY должен быть 32 байта в base64');
    }
    if (!cookieSecure) problems.add('COOKIE_SECURE должен быть true: сессия ходит только по HTTPS');
    if (seedOnStart) problems.add('SEED_ON_START должен быть false: демо-данные не нужны на боевой базе');
    if (databaseUrl.contains('ibuild:ibuild@')) problems.add('DATABASE_URL использует пароль по умолчанию');
    if (databaseUrl.contains('sslmode=disable') && !databaseUrl.contains('@db:') && !databaseUrl.contains('localhost')) {
      problems.add('DATABASE_URL: для внешней базы включите SSL');
    }
    return problems;
  }

  factory AppEnv.load() {
    final file = <String, String>{};
    for (final path in const ['.env', '../.env']) {
      final envFile = File(path);
      if (!envFile.existsSync()) continue;
      for (final line in envFile.readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final separator = trimmed.indexOf('=');
        if (separator <= 0) continue;
        file.putIfAbsent(
          trimmed.substring(0, separator).trim(),
          () => trimmed.substring(separator + 1).trim(),
        );
      }
    }
    final merged = Map<String, String>.from(file);
    // The process environment wins over a file, as it did before.
    merged.addAll(Platform.environment);
    return AppEnv.parse(merged);
  }

  /// Builds settings from an explicit map. Used by [load] and by tests.
  factory AppEnv.parse(Map<String, String> source) {
    String read(String key, String fallback) => source[key] ?? fallback;

    final secretProblems = <String>[];
    final dbPassword = readSecret(source, 'DB_PASSWORD');
    final mail = readSecret(source, 'MAIL_KEY');
    final smtp = readSecret(source, 'SMTP_PASSWORD');
    secretProblems.addAll(dbPassword.problems);
    secretProblems.addAll(mail.problems);
    secretProblems.addAll(smtp.problems);

    final configuredUrl = read('DATABASE_URL', '');
    final String databaseUrl;
    if (configuredUrl.isNotEmpty) {
      databaseUrl = configuredUrl;
    } else if (dbPassword.value.isNotEmpty) {
      final host = read('DB_HOST', 'localhost');
      final sslmode = (host == 'db' || host == 'localhost' || host == '127.0.0.1') ? 'disable' : 'require';
      final port = int.parse(read('DB_PORT', host == 'db' ? '5432' : '5433'));
      databaseUrl = postgresUrl(
        user: read('DB_USER', 'ibuild'),
        password: dbPassword.value,
        host: host,
        port: port,
        database: read('DB_NAME', 'ibuild'),
        sslmode: sslmode,
      );
    } else {
      databaseUrl = 'postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable';
    }

    final webRoot = read('WEB_ROOT', '');
    return AppEnv(
      databaseUrl: databaseUrl,
      host: read('HOST', '0.0.0.0'),
      port: int.parse(read('PORT', '8080')),
      seedOnStart: read('SEED_ON_START', 'false') == 'true',
      seedPassword: read('SEED_PASSWORD', ''),
      webRoot: webRoot.isEmpty ? null : webRoot,
      cookieSecure: read('COOKIE_SECURE', 'false') == 'true',
      migrationsDir: read('MIGRATIONS_DIR', 'migrations'),
      sessionTtl: const Duration(hours: 12),
      loginFailureLimit: 5,
      loginWindow: const Duration(minutes: 15),
      fileRoot: read('FILE_ROOT', 'data/files'),
      registrationPerHour: int.parse(read('REGISTRATION_PER_HOUR', '5')),
      production: read('APP_ENV', 'development') == 'production',
      demoEnabled: read('DEMO_ENABLED', 'false') == 'true',
      demoSessionTtl: Duration(minutes: int.parse(read('DEMO_SESSION_MINUTES', '120'))),
      maxBodyBytes: int.parse(read('MAX_BODY_BYTES', '${12 * 1024 * 1024}')),
      mailKey: mail.value,
      trustProxy: read('TRUST_PROXY', 'false') == 'true',
      secretProblems: secretProblems,
    );
  }
}

/// Password is encoded so `@` and `:` stay inside the user-info.
String postgresUrl({
  required String user,
  required String password,
  required String host,
  required int port,
  required String database,
  required String sslmode,
}) {
  final userInfo = '${Uri.encodeComponent(user)}:${Uri.encodeComponent(password)}';
  return 'postgres://$userInfo@$host:$port/$database?sslmode=$sslmode';
}
