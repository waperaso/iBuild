/// Compile-time config for the B2B admin app (shared API with B2C).
///
/// Inject with `--dart-define-from-file=dart_defines.dev.json` (local) or
/// `dart_defines.prod.json` (release). Copy from `*.json.example` — those
/// files are gitignored so hosts never live in the repo. See
/// `docs/HOSTING_AHOST.md`.
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

  /// Turns server-relative paths (`/v1/static/...`) into absolute URLs using
  /// [apiBaseUrl], so uploaded documents/photo reports open correctly
  /// regardless of which host a build points at.
  static String? resolveUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) {
      return Uri.parse(apiBaseUrl).resolve(raw).toString();
    }
    return raw;
  }
}
