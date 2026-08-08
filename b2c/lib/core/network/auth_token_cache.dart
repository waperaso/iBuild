import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// In-memory access token for Dio interceptors (avoids per-request storage I/O).
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

/// Warms [AuthTokenCache] during `/splash` so `main` isn't blocked on storage.
final bootstrapProvider = FutureProvider<void>((ref) async {
  await AuthTokenCache.warmUp(const FlutterSecureStorage());
});
