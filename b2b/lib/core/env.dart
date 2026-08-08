/// Compile-time env (`--dart-define-from-file=dart_defines.*.json`).
abstract class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ibuild.uz/v1',
  );

  /// WebSocket endpoint for live unit-status and lead pushes.
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://api.ibuild.uz/v1/ws',
  );

  /// Absolute URL for a server-relative path via [apiBaseUrl].
  static String? resolveUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) {
      return Uri.parse(apiBaseUrl).resolve(raw).toString();
    }
    return raw;
  }
}
