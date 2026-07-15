import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;

import '../lib/src/app.dart';
import '../lib/src/db/pg_config.dart';
import '../lib/src/env_loader.dart';
import '../lib/src/store.dart';

/// iBuild dev/demo backend.
///
/// A lightweight Dart stand-in for the NestJS + PostgreSQL + Redis API in
/// `IBUILD_APP_PLAN.md` (§6, §8) — same REST envelope, resource paths and
/// WebSocket events, so the Flutter client talks to a real, running server
/// end-to-end in this environment (Node.js is not available here).
///
/// Persistence is opt-in: set `DB_HOST` (+ friends, see `PgConfig.fromEnv`
/// and `README.md`) either as environment variables or in `server/.env`
/// (auto-loaded, see `env_loader.dart`) to back this server with a real
/// PostgreSQL database instead of the default in-memory-only store.
void main(List<String> args) async {
  final env = appEnv();
  // Fail fast in production if SMS creds / required secrets are missing,
  // rather than silently falling back to insecure dev behavior.
  assertProductionSecrets();
  final store = await Store.create();
  final port = int.tryParse(env['PORT'] ?? '') ?? 4000;

  final handler = createHandler(store);

  // BIND_ADDRESS: use 127.0.0.1 in production behind nginx (see
  // docs/HOSTING_AHOST.md). Default remains all-interfaces for local/dev.
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
}
