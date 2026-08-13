/// Compile-time env (`--dart-define-from-file=dart_defines.*.json`).
abstract class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ibuild.uz/v1',
  );

  /// True when [apiBaseUrl] has a scheme and non-empty host (e.g. not `http:///v1`).
  static bool get hasValidApiBaseUrl {
    final uri = Uri.tryParse(apiBaseUrl);
    return uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        !apiBaseUrl.contains(':///');
  }

  /// WebSocket endpoint for live unit-status and lead pushes.
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://api.ibuild.uz/v1/ws',
  );

  /// The AI assistant chat is built and tested but parked out of the product
  /// until it ships: the FAB and its sheet stay off unless a build passes
  /// `--dart-define=AI_CHAT_ENABLED=true`.
  static const bool aiChatEnabled = bool.fromEnvironment(
    'AI_CHAT_ENABLED',
    defaultValue: false,
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
