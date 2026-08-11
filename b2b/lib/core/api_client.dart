import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import 'env.dart';
import 'session_storage.dart';

/// Request extra: already retried after refresh (blocks refresh loops).
const _retriedExtraKey = 'b2b_retried_after_refresh';

abstract class AuthStorageKeys {
  static const accessToken = 'b2b_access_token';
  static const refreshToken = 'b2b_refresh_token';
  static const userJson = 'b2b_user';

  /// Cached `GET /developers/me` snapshot for apply-screen first paint.
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

/// In-memory bearer token for WS handshake (avoids secure-storage on reconnect).
String? get accessTokenCache => _accessTokenCache;

/// Listen for [setAccessTokenCache]; returns unsubscribe.
void Function() addAccessTokenListener(void Function(String?) listener) {
  _accessTokenListeners.add(listener);
  return () => _accessTokenListeners.remove(listener);
}

final List<void Function()> _sessionExpiredListeners = [];

/// Listen for session-expired from the refresh interceptor; returns unsubscribe.
void Function() addSessionExpiredListener(void Function() listener) {
  _sessionExpiredListeners.add(listener);
  return () => _sessionExpiredListeners.remove(listener);
}

/// Clear stored credentials (idempotent).
Future<void> clearStoredSession(SessionStorage storage) async {
  setAccessTokenCache(null);
  await storage.delete(key: AuthStorageKeys.accessToken);
  await storage.delete(key: AuthStorageKeys.refreshToken);
  await storage.delete(key: AuthStorageKeys.userJson);
  // Drop KYC snapshot so the next account on this device doesn't inherit it.
  await storage.delete(key: AuthStorageKeys.developerApplicationJson);
}

void notifySessionExpired() {
  for (final listener in List<void Function()>.from(_sessionExpiredListeners)) {
    listener();
  }
}

final secureStorageProvider = sessionStorageProvider;

final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(sessionStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  // Single-flight refresh: concurrent 401s await one `/auth/refresh` (same as b2c).
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
        // Auth session endpoints must stay reachable so demo re-entry /
        // sign-out are not cancelled by the read-only guard.
        if (DemoSession.isActive &&
            _isMutatingMethod(options.method) &&
            !_isDemoAllowedMutation(options.path)) {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              message: 'DEMO_READ_ONLY',
            ),
          );
        }
        final token = _accessTokenCache;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Unwrap `{ success, data, meta }` once for callers.
        response.data = ApiEnvelope.unwrap(response.data);
        handler.next(response);
      },
      onError: (err, handler) async {
        // Skip refresh for `/auth/*` 401s; retry any other request at most once.
        final is401 = err.response?.statusCode == 401;
        final isAuthPath = err.requestOptions.path.contains('/auth/');
        final alreadyRetried =
            err.requestOptions.extra[_retriedExtraKey] == true;
        if (!is401 || isAuthPath || alreadyRetried) {
          return handler.next(err);
        }

        // Refresh already in flight — wait, then retry or fail with it.
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
          // Refresh failed — clear session so the UI re-authenticates.
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

bool _isMutatingMethod(String method) {
  switch (method.toUpperCase()) {
    case 'POST':
    case 'PUT':
    case 'PATCH':
    case 'DELETE':
      return true;
    default:
      return false;
  }
}

bool _isDemoAllowedMutation(String path) {
  return path.contains('/auth/demo') ||
      path.contains('/auth/logout') ||
      path.contains('/auth/otp/') ||
      path.contains('/auth/refresh');
}
