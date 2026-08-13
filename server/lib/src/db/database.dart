import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';

import 'pg_config.dart';

/// One Postgres connection + [migrate]. Ops serialized to avoid racing RLS context.
class Database {
  Database(this.config, {String? migrationsDir})
    : _migrationsDir =
          migrationsDir ??
          '${Directory.current.path}${Platform.pathSeparator}migrations';

  final PgConfig config;
  final String _migrationsDir;

  Connection? _connection;

  /// Serialization chain tail.
  Future<void> _gate = Future<void>.value();

  Connection get connection {
    final c = _connection;
    if (c == null) {
      throw StateError('Database.connect() must be called before use.');
    }
    return c;
  }

  /// Run [fn] after prior queued DB ops finish.
  Future<T> _serialized<T>(Future<T> Function() fn) {
    final previous = _gate;
    final done = Completer<void>();
    _gate = done.future;
    return previous.catchError((_) {}).then((_) => fn()).whenComplete(() {
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
        final retryable =
            attempt < maxAttempts && _isRetryableConnectError(error);
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

  /// Apply pending `*.sql` in [_migrationsDir] (filename order, one tx each).
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
  }) => _serialized(() => connection.execute(query, parameters: parameters));

  Future<R> runTx<R>(Future<R> Function(TxSession session) fn) =>
      _serialized(() => connection.runTx(fn));

  Future<void> close() async {
    await _connection?.close();
  }
}
