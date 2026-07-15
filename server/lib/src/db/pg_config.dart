import '../env_loader.dart';

/// Connection settings for the optional PostgreSQL persistence layer.
///
/// Constructed from environment variables via [PgConfig.fromEnv]. A `null`
/// return from that factory is the signal used throughout the app that no
/// database is configured, and the server should stay in pure in-memory
/// mode (see `Store.create`).
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

  /// Reads `DB_HOST`, `DB_PORT` (default `5432`), `DB_NAME`, `DB_USER`,
  /// `DB_PASSWORD`, `DB_SSL` (`true`/`false`, default `false`) from
  /// [environment] (defaults to [appEnv] — the process environment merged
  /// with `server/.env` when that file exists).
  ///
  /// Returns `null` when `DB_HOST` is unset or empty — the app should then
  /// fall back to the fully in-memory mode used by every existing test.
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
