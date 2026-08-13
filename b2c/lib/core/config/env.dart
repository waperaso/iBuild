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

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://api.ibuild.uz/v1/ws',
  );

  /// When true, screens render bundled mock data (including the mock OTP
  /// `123456` auth bypass) instead of calling the API. Defaults to `false`
  /// so production artifacts never ship mock data by accident — pass
  /// `--dart-define=USE_MOCK_DATA=true` for hermetic tests and offline dev
  /// (CI's `flutter test` step does exactly this). A release build refuses
  /// to start when this is `true` (see `main.dart`).
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  /// The AI assistant chat is built and tested but parked out of the product
  /// until it ships: the FAB and its sheet stay off unless a build passes
  /// `--dart-define=AI_CHAT_ENABLED=true`.
  static const bool aiChatEnabled = bool.fromEnvironment(
    'AI_CHAT_ENABLED',
    defaultValue: false,
  );

  /// Marketing/sign-up entry point for the iBuild for Business (B2B) app.
  /// Ordinary consumer accounts can never list inventory for sale or rent
  /// from this app — businesses that want to list do so through the
  /// dedicated B2B workspace, linked to from the B2C profile screen.
  static const String businessUrl = String.fromEnvironment(
    'BUSINESS_URL',
    defaultValue: 'https://admin.ibuild.uz',
  );
}
