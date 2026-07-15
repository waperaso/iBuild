import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';

import 'pg_config.dart';

/// Thin wrapper around a single `postgres` v3 [Connection], adding an
/// idempotent [migrate] step that applies the SQL files under
/// `migrations/` (tracked in a `schema_migrations` table) in filename
/// order.
///
/// Kept deliberately small: the rest of the persistence layer
/// ([PgPersistence]) only needs [execute] and [runTx].
///
/// All access is serialized through [_serialized]: the postgres driver
/// rejects concurrent `execute` while a `runTx` is open on the same
/// connection, and Store write-throughs are fire-and-forget (`unawaited`),
/// so without a gate the auth middleware's `setRequestContext` (and the
/// next HTTP request) race with in-flight deletes/upserts and throw
/// `Attempting to execute query on connection while inside a runTx call`
/// — which also wedged the connection and made subsequent requests hang
/// until Dio's connectTimeout.
class Database {
  Database(this.config, {String? migrationsDir})
    : _migrationsDir =
          migrationsDir ??
          '${Directory.current.path}${Platform.pathSeparator}migrations';

  final PgConfig config;
  final String _migrationsDir;

  Connection? _connection;

  /// Tail of the serialization chain. Completes when the latest queued
  /// operation finishes (successfully or not).
  Future<void> _gate = Future<void>.value();

  Connection get connection {
    final c = _connection;
    if (c == null) {
      throw StateError('Database.connect() must be called before use.');
    }
    return c;
  }

  /// Runs [fn] only after every previously queued DB op has finished.
  Future<T> _serialized<T>(Future<T> Function() fn) {
    final previous = _gate;
    final done = Completer<void>();
    _gate = done.future;
    return previous
        .catchError((_) {})
        .then((_) => fn())
        .whenComplete(() {
          if (!done.isCompleted) done.complete();
        });
  }

  Future<void> connect({int maxAttempts = 5}) async {
    Object? lastError;
    StackTrace? lastStack;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _connection = await Connection.open(
          Endpoint(
            host: config.host,
            port: config.port,
            database: config.database,
            username: config.username,
            password: config.password,
          ),
          settings: ConnectionSettings(
            sslMode: config.useSsl ? SslMode.require : SslMode.disable,
          ),
        );
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStack = stackTrace;
        final retryable = attempt < maxAttempts && _isRetryableConnectError(error);
        if (!retryable) {
          Error.throwWithStackTrace(error, stackTrace);
        }
        final delay = Duration(seconds: 2 * attempt);
        stderr.writeln(
          '[Database] Connect attempt $attempt/$maxAttempts failed ($error); '
          'retrying in ${delay.inSeconds}s...',
        );
        await Future<void>.delayed(delay);
      }
    }
    Error.throwWithStackTrace(lastError!, lastStack!);
  }

  static bool _isRetryableConnectError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('password authentication failed') ||
        message.contains('server signature verification failed')) {
      return false;
    }
    return true;
  }

  /// Applies every `*.sql` file in [_migrationsDir] that hasn't already
  /// been recorded in `schema_migrations`, in filename order, each inside
  /// its own transaction. Safe to call on every startup — already-applied
  /// migrations are skipped.
  Future<void> migrate() async {
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    ''');

    final dir = Directory(_migrationsDir);
    if (!dir.existsSync()) {
      stderr.writeln(
        '[Database] Migrations directory not found: $_migrationsDir '
        '(skipping migrate())',
      );
      return;
    }

    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.sql'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final version = file.uri.pathSegments.last;
      final already = await connection.execute(
        Sql.named('SELECT 1 FROM schema_migrations WHERE version = @version'),
        parameters: {'version': TypedValue(Type.text, version)},
      );
      if (already.isNotEmpty) continue;

      final sql = await file.readAsString();
      await connection.runTx((tx) async {
        await tx.execute(Sql(sql), queryMode: QueryMode.simple);
        await tx.execute(
          Sql.named(
            'INSERT INTO schema_migrations (version) VALUES (@version)',
          ),
          parameters: {'version': TypedValue(Type.text, version)},
        );
      });
    }
  }

  Future<Result> execute(
    Object /* String | Sql */ query, {
    Object? parameters,
  }) => _serialized(
    () => connection.execute(query, parameters: parameters),
  );

  Future<R> runTx<R>(Future<R> Function(TxSession session) fn) =>
      _serialized(() => connection.runTx(fn));

  Future<void> close() async {
    await _connection?.close();
  }
}
