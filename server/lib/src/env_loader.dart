import 'dart:io';

Map<String, String>? _cached;

/// Process environment overlaid on top of the `KEY=VALUE` pairs from a `.env`
/// file, so `dart run bin/server.dart` picks up `DB_HOST` (and friends) from
/// `server/.env` without requiring the operator to export variables or use
/// `scripts/run-with-db.ps1`. Real environment variables always win over the
/// file, and the merged map is cached for the process lifetime.
///
/// The file is looked up in the current working directory first (the server
/// package root when run normally, matching how `Database` locates
/// `migrations/`), then in a `server/` subdirectory to also cover launches
/// from the repository root.
Map<String, String> appEnv() => _cached ??= _load();

/// Clears the cached merged environment (test hook).
void resetAppEnvCache() => _cached = null;

/// Deployment environment name from `APP_ENV`, lowercased ('' when unset).
/// Used to gate dev-only conveniences (fixed OTP, bootstrap-admin, free
/// subscription checkout) that must never be reachable in production.
String appEnvName() => (appEnv()['APP_ENV'] ?? '').trim().toLowerCase();

/// Whether the server is running in production (`APP_ENV=production`).
bool get isProduction => appEnvName() == 'production';

Map<String, String> _load() {
  final merged = <String, String>{};
  final file = _findEnvFile();
  if (file != null) {
    try {
      merged.addAll(parseDotEnv(file.readAsLinesSync()));
      stderr.writeln('[env] Loaded ${file.path}');
    } on FileSystemException catch (error) {
      stderr.writeln('[env] Failed to read ${file.path}: $error');
    }
  }
  merged.addAll(Platform.environment);
  return merged;
}

File? _findEnvFile() {
  final cwd = Directory.current.path;
  for (final candidate in [
    '$cwd${Platform.pathSeparator}.env',
    '$cwd${Platform.pathSeparator}server${Platform.pathSeparator}.env',
  ]) {
    final file = File(candidate);
    if (file.existsSync()) return file;
  }
  return null;
}

/// Parses dotenv-style [lines]: `KEY=VALUE`, `#` comments, blank lines,
/// optional single/double quotes around the value. Exposed for tests.
Map<String, String> parseDotEnv(List<String> lines) {
  final out = <String, String>{};
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final key = line.substring(0, eq).trim();
    var value = line.substring(eq + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    if (key.isNotEmpty) out[key] = value;
  }
  return out;
}
