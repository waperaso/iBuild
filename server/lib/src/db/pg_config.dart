import '../env_loader.dart';

/// Optional Postgres settings from env ([PgConfig.fromEnv]; null → in-memory).
class PgConfig {
  const PgConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    required this.useSsl,
  });

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final bool useSsl;

  /// From `DB_*` env ([appEnv] by default). Null if `DB_HOST` unset.
  static PgConfig? fromEnv([Map<String, String>? environment]) {
    final env = environment ?? appEnv();
    final host = env['DB_HOST']?.trim();
    if (host == null || host.isEmpty) return null;

    return PgConfig(
      host: host,
      port: int.tryParse(env['DB_PORT'] ?? '') ?? 5432,
      database: env['DB_NAME'] ?? 'ibuild',
      username: env['DB_USER'] ?? 'postgres',
      password: env['DB_PASSWORD'] ?? '',
      useSsl: (env['DB_SSL'] ?? 'false').trim().toLowerCase() == 'true',
    );
  }

  @override
  String toString() =>
      'PgConfig(host: $host, port: $port, database: $database, '
      'username: $username, useSsl: $useSsl)';
}
