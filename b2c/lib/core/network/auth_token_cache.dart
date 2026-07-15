import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// In-memory bearer token so the Dio interceptor never awaits secure storage
/// on every request. Concurrent [FlutterSecureStorage.read] calls on Flutter
/// web (IndexedDB) can hang or throw, which leaves list screens stuck in the
/// loading skeleton while the server never sees a single GET.
class AuthTokenCache {
  AuthTokenCache._();

  static String? _accessToken;
  static final List<void Function(String?)> _listeners = [];

  static String? get accessToken => _accessToken;

  static void setAccessToken(String? token) {
    _accessToken = token;
    for (final listener in List<void Function(String?)>.from(_listeners)) {
      listener(token);
    }
  }

  /// Notifies [listener] whenever [setAccessToken] runs (sign-in, refresh,
  /// sign-out). Returns an unsubscribe callback.
  static void Function() addListener(void Function(String?) listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  /// Loads the persisted token once at startup.
  static Future<void> warmUp(FlutterSecureStorage storage) async {
    try {
      final token = await storage
          .read(key: 'access_token')
          .timeout(const Duration(seconds: 5));
      _accessToken = (token != null && token.isNotEmpty) ? token : null;
    } catch (_) {
      _accessToken = null;
    }
  }
}

/// Runs [AuthTokenCache.warmUp] behind the animated splash instead of
/// blocking `main` on it — the router stays on `/splash` until this
/// resolves, so the very first frame is never delayed by a secure-storage
/// read (which can be slow, especially on web).
final bootstrapProvider = FutureProvider<void>((ref) async {
  await AuthTokenCache.warmUp(const FlutterSecureStorage());
});
