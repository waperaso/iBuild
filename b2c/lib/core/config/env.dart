/// Compile-time environment configuration.
///
/// Inject with `--dart-define-from-file=dart_defines.dev.json` (local) or
/// `dart_defines.prod.json` (release). Copy from `*.json.example`.
/// See `docs/HOSTING_AHOST.md`.
abstract class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ibuild.uz/v1',
  );

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

  /// Marketing/sign-up entry point for the iBuild for Business (B2B) app.
  /// Ordinary consumer accounts can never list inventory for sale or rent
  /// from this app — businesses that want to list do so through the
  /// dedicated B2B workspace, linked to from the B2C profile screen.
  static const String businessUrl = String.fromEnvironment(
    'BUSINESS_URL',
    defaultValue: 'https://admin.ibuild.uz',
  );
}
