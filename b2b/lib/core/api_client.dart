import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ibuild_core/ibuild_core.dart';

import 'env.dart';

/// Marks a request that has already been replayed after a token refresh, so a
/// second 401 surfaces to the caller instead of looping.
const _retriedExtraKey = 'b2b_retried_after_refresh';

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

final List<void Function()> _sessionExpiredListeners = [];

/// Subscribes to "the stored session is gone" events raised by the refresh
/// interceptor. `AuthController` listens so the UI drops to signed-out
/// instead of holding a user object whose token no longer works — otherwise
/// the app looks signed in while every request 401s. Returns an unsubscribe
/// callback.
void Function() addSessionExpiredListener(void Function() listener) {
  _sessionExpiredListeners.add(listener);
  return () => _sessionExpiredListeners.remove(listener);
}

/// Clears every stored credential and tells the app the session is over.
/// Safe to call more than once.
Future<void> clearStoredSession(FlutterSecureStorage storage) async {
  setAccessTokenCache(null);
  await storage.delete(key: AuthStorageKeys.accessToken);
  await storage.delete(key: AuthStorageKeys.refreshToken);
  await storage.delete(key: AuthStorageKeys.userJson);
  // Also drop the cached application snapshot: it belongs to the account that
  // just signed out, and leaving it behind shows one user's KYC status to
  // whoever signs in next on the same device.
  await storage.delete(key: AuthStorageKeys.developerApplicationJson);
}

void notifySessionExpired() {
  for (final listener in List<void Function()>.from(_sessionExpiredListeners)) {
    listener();
  }
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

  // Single-flight gate: without it, N concurrent requests that all 401 at
  // once each fire their own `/auth/refresh`, rotating the refresh token N
  // times and invalidating every rotation but the last — the classic refresh
  // race that logs the user out mid-session. Concurrent 401s await this
  // completer's result (true = refreshed, retry; false = give up) instead of
  // being failed outright, so one expired token does not surface as an error
  // on every screen that happened to be loading. Mirrors the B2C client.
  Completer<bool>? refreshGate;

  Future<bool> performRefresh() async {
    try {
      final refresh = await storage.read(key: AuthStorageKeys.refreshToken);
      if (refresh == null || refresh.isEmpty) return false;
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
        // Only accept a fully-formed rotation. A partial/blank response must
        // not overwrite a still-valid session with garbage tokens.
        if (access != null &&
            access.isNotEmpty &&
            newRefresh != null &&
            newRefresh.isNotEmpty) {
          await storage.write(key: AuthStorageKeys.accessToken, value: access);
          await storage.write(
            key: AuthStorageKeys.refreshToken,
            value: newRefresh,
          );
          setAccessTokenCache(access);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> retry(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    options.extra[_retriedExtraKey] = true;
    final token = _accessTokenCache;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    try {
      handler.resolve(await dio.fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

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
        // dead), and only ever retry a given request once.
        final is401 = err.response?.statusCode == 401;
        final isAuthPath = err.requestOptions.path.contains('/auth/');
        final alreadyRetried =
            err.requestOptions.extra[_retriedExtraKey] == true;
        if (!is401 || isAuthPath || alreadyRetried) {
          return handler.next(err);
        }

        // A refresh is already running — wait for it rather than starting our
        // own, then retry (or fail) based on its outcome.
        final inFlight = refreshGate;
        if (inFlight != null) {
          final ok = await inFlight.future;
          if (!ok) return handler.next(err);
          return retry(err, handler);
        }

        final gate = Completer<bool>();
        refreshGate = gate;
        final ok = await performRefresh();
        if (!ok) {
          // The session cannot be renewed — no stored refresh token, a
          // rejected one, or a response we could not use. Drop the
          // credentials and tell the app, so it re-authenticates instead of
          // sitting on a token that 401s forever.
          await clearStoredSession(storage);
          notifySessionExpired();
        }
        refreshGate = null;
        gate.complete(ok);

        if (!ok) return handler.next(err);
        return retry(err, handler);
      },
    ),
  );

  return dio;
});
