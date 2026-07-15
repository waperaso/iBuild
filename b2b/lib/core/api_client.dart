import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ibuild_core/ibuild_core.dart';

import 'env.dart';

abstract class AuthStorageKeys {
  static const accessToken = 'b2b_access_token';
  static const refreshToken = 'b2b_refresh_token';
  static const userJson = 'b2b_user';

  /// Last known snapshot of the signed-in user's developer application
  /// (`GET /developers/me`). Cached so the apply screen can paint the
  /// pending/rejected state instantly on relaunch, before the network
  /// round-trip that refreshes it resolves.
  static const developerApplicationJson = 'b2b_developer_application';
}

String? _accessTokenCache;
final List<void Function(String?)> _accessTokenListeners = [];

void setAccessTokenCache(String? token) {
  _accessTokenCache = token;
  for (final listener in List<void Function(String?)>.from(
    _accessTokenListeners,
  )) {
    listener(token);
  }
}

/// Current in-memory bearer token, if any — read by [wsClientProvider] (see
/// `core/network/ws_client.dart`) to authenticate the `/v1/ws` handshake
/// without awaiting secure storage on every reconnect attempt.
String? get accessTokenCache => _accessTokenCache;

/// Notifies [listener] whenever [setAccessTokenCache] runs (sign-in, token
/// refresh, sign-out) so the shared WebSocket client can reconnect with
/// fresh credentials. Returns an unsubscribe callback.
void Function() addAccessTokenListener(void Function(String?) listener) {
  _accessTokenListeners.add(listener);
  return () => _accessTokenListeners.remove(listener);
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  // Single-flight guard: without it, N concurrent requests that all 401 at
  // once each fire their own `/auth/refresh`, rotating the refresh token N
  // times and invalidating every rotation but the last — the classic
  // refresh race that logs the user out mid-session. While a refresh is in
  // flight we skip re-entering the flow and let the original error surface;
  // the caller can retry once the cache is repopulated.
  var refreshing = false;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _accessTokenCache;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Unwrap the shared `{ success, data, meta }` envelope in one place
        // (see `ApiEnvelope` in ibuild_core) so callers see the raw entity.
        response.data = ApiEnvelope.unwrap(response.data);
        handler.next(response);
      },
      onError: (err, handler) async {
        // Never try to refresh a failed auth call itself (a 401 from
        // `/auth/refresh` or `/auth/otp/*` means the credential is truly
        // dead), and never re-enter while a refresh is already running.
        if (err.response?.statusCode == 401 &&
            !err.requestOptions.path.contains('/auth/') &&
            !refreshing) {
          refreshing = true;
          try {
            final refresh = await storage.read(
              key: AuthStorageKeys.refreshToken,
            );
            if (refresh != null && refresh.isNotEmpty) {
              final refreshDio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));
              final res = await refreshDio.post<Map<String, dynamic>>(
                '/auth/refresh',
                data: {'refreshToken': refresh},
              );
              var data = res.data;
              if (data != null && data.containsKey('data')) {
                data = data['data'] as Map<String, dynamic>?;
              }
              if (data is Map<String, dynamic>) {
                final access = data['accessToken'] as String?;
                final newRefresh = data['refreshToken'] as String?;
                // Only accept a fully-formed rotation. A partial/blank
                // response must not overwrite a still-valid session with
                // garbage tokens (the old "brittle restore" failure mode).
                if (access != null &&
                    access.isNotEmpty &&
                    newRefresh != null &&
                    newRefresh.isNotEmpty) {
                  await storage.write(
                    key: AuthStorageKeys.accessToken,
                    value: access,
                  );
                  await storage.write(
                    key: AuthStorageKeys.refreshToken,
                    value: newRefresh,
                  );
                  setAccessTokenCache(access);
                  err.requestOptions.headers['Authorization'] =
                      'Bearer $access';
                  final clone = await dio.fetch(err.requestOptions);
                  refreshing = false;
                  return handler.resolve(clone);
                }
              }
            }
          } catch (_) {
            // Refresh failed — drop the stale session so the UI re-auths.
            setAccessTokenCache(null);
            await storage.delete(key: AuthStorageKeys.accessToken);
            await storage.delete(key: AuthStorageKeys.refreshToken);
            await storage.delete(key: AuthStorageKeys.userJson);
          } finally {
            refreshing = false;
          }
        }
        handler.next(err);
      },
    ),
  );

  return dio;
});
