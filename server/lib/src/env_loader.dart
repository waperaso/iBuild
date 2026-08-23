import 'dart:io';

Map<String, String>? _cached;
Map<String, String>? _testOverrides;

/// Process env over `.env` (cwd, then `server/.env`). Process vars win; cached.
Map<String, String> appEnv() {
  final base = _cached ??= _load();
  final overrides = _testOverrides;
  if (overrides == null || overrides.isEmpty) return base;
  return {...base, ...overrides};
}

/// Clear cached env (tests).
void resetAppEnvCache() {
  _cached = null;
  _testOverrides = null;
}

/// Test-only env overlays (merged on top of loaded env).
void setAppEnvTestOverrides(Map<String, String>? overrides) {
  _testOverrides = overrides;
  // Keep file/process cache; overlays apply on each [appEnv] read.
}

/// `APP_ENV` lowercased ('' if unset). Gates prod-only secret checks.
String appEnvName() => (appEnv()['APP_ENV'] ?? '').trim().toLowerCase();

/// `APP_ENV=production`.
bool get isProduction => appEnvName() == 'production';

/// Open `/v1/auth/demo` for pitch/reviewer login.
/// Off in production unless `DEMO_LOGIN_ENABLED=true`.
/// On in non-production unless `DEMO_LOGIN_ENABLED=false`.
bool get demoLoginEnabled {
  final raw = (appEnv()['DEMO_LOGIN_ENABLED'] ?? '').trim().toLowerCase();
  if (isProduction) return raw == 'true';
  if (raw == 'false' || raw == '0' || raw == 'off') return false;
  return true;
}

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
