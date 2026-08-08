import 'dart:io';

import 'package:ibuild_server/src/app.dart';
import 'package:ibuild_server/src/db/pg_config.dart';
import 'package:ibuild_server/src/env_loader.dart';
import 'package:ibuild_server/src/store.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// iBuild API entrypoint. Optional Postgres via `DB_HOST` (see `PgConfig.fromEnv`).
void main(List<String> args) async {
  final env = appEnv();
  // Production: fail if SMS creds / secrets are missing (no insecure fallback).
  assertProductionSecrets();
  final store = await Store.create();
  final port = int.tryParse(env['PORT'] ?? '') ?? 4000;

  final handler = createHandler(store);

  // BIND_ADDRESS: use 127.0.0.1 in production behind nginx (see
  // docs/HOSTING_AIRNET.md). Default remains all-interfaces for local/dev.
  final bindRaw = (env['BIND_ADDRESS'] ?? '').trim();
  final address = switch (bindRaw) {
    '' || '0.0.0.0' || 'any' => InternetAddress.anyIPv4,
    'localhost' || '127.0.0.1' => InternetAddress.loopbackIPv4,
    _ => InternetAddress(bindRaw),
  };

  final server = await shelf_io.serve(handler, address, port);
  final config = PgConfig.fromEnv();
  final persistenceLine = store.hasPersistence
      ? 'Persistence: PostgreSQL @ ${config!.host}:${config.port}/${config.database}'
      : config != null
      ? 'Persistence: !!! DB configured ($config) but initialization FAILED — '
            'running IN-MEMORY, nothing will survive a restart. '
            'Check the [Store] error above.'
      : 'Persistence: in-memory only (set DB_HOST in server/.env or the '
            'environment to enable PostgreSQL — data will NOT survive '
            'restarts)';
  // ignore: avoid_print
  print(
    'iBuild API listening on http://${server.address.host}:${server.port}\n'
    'REST base:  /v1  (via reverse proxy in production)\n'
    'WebSocket:  /v1/ws\n'
    'APP_ENV:    ${appEnvName().isEmpty ? 'development' : appEnvName()}\n'
    '$persistenceLine\n'
    'Loaded ${store.projects.length} projects '
    '(${store.projects.where((p) => p['type'] == 'residential_complex').length} residential, '
    '${store.projects.where((p) => p['type'] == 'business_centre').length} business centres).',
  );

  // Graceful shutdown: systemd sends SIGTERM and waits TimeoutStopSec before
  // SIGKILL (see deploy/ibuild-api.service). Without this the process died
  // mid-request with open WebSockets and an un-closed pool, so a deploy
  // restart could drop in-flight writes.
  var shuttingDown = false;
  Future<void> shutdown(String signal) async {
    if (shuttingDown) return;
    shuttingDown = true;
    stderr.writeln('[server] $signal received — shutting down gracefully…');
    try {
      await server.close();
      store.dispose();
    } catch (error) {
      stderr.writeln('[server] Error during shutdown: $error');
    }
    exit(0);
  }

  ProcessSignal.sigint.watch().listen((_) => shutdown('SIGINT'));
  // SIGTERM cannot be watched on Windows.
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) => shutdown('SIGTERM'));
  }
}
