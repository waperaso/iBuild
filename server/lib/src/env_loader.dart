import 'dart:io';

Map<String, String>? _cached;

/// Process env over `.env` (cwd, then `server/.env`). Process vars win; cached.
Map<String, String> appEnv() => _cached ??= _load();

/// Clear cached env (tests).
void resetAppEnvCache() => _cached = null;

/// `APP_ENV` lowercased ('' if unset). Gates prod-only secret checks.
String appEnvName() => (appEnv()['APP_ENV'] ?? '').trim().toLowerCase();

/// `APP_ENV=production`.
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

/// Parse dotenv [lines] (`KEY=VALUE`, `#` comments, optional quotes).
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
