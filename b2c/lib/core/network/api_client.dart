import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../config/env.dart';
import 'auth_token_cache.dart';

/// Secure storage keys for auth tokens.
abstract class AuthStorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
}

/// Persisted user key (same as auth_repository; here for 401 session purge).
const _authUserStorageKey = 'auth_user';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Request extra: already retried after refresh (blocks refresh loops).
const _retriedExtraKey = '__ibuild_retried__';

/// [Dio] for the REST API: envelope unwrap, bearer token, 401 → refresh/retry.
/// Concurrent 401s share one refresh; failed refresh signs out.
final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return _createDio(
    storage,
    onSessionExpired: () {
      // Tokens cleared; invalidate so restoreSession() yields guest/null.
      ref.invalidate(authControllerProvider);
    },
  );
});

Dio _createDio(
  FlutterSecureStorage storage, {
  required VoidCallback onSessionExpired,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  // Single-flight refresh: concurrent 401s await one `/auth/refresh`.
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
        if (access != null && newRefresh != null) {
          await storage.write(key: AuthStorageKeys.accessToken, value: access);
          await storage.write(
            key: AuthStorageKeys.refreshToken,
            value: newRefresh,
          );
          AuthTokenCache.setAccessToken(access);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearSession() async {
    await storage.delete(key: AuthStorageKeys.accessToken);
    await storage.delete(key: AuthStorageKeys.refreshToken);
    await storage.delete(key: _authUserStorageKey);
    AuthTokenCache.setAccessToken(null);
  }

  Future<void> retry(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    options.extra[_retriedExtraKey] = true;
    final token = AuthTokenCache.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    try {
      final clone = await dio.fetch(options);
      handler.resolve(clone);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AuthTokenCache.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final body = response.data;
        if (body is Map<String, dynamic> && body.containsKey('data')) {
          response.data = body['data'];
        }
        handler.next(response);
      },
      onError: (err, handler) async {
        final is401 = err.response?.statusCode == 401;
        final isAuthPath = err.requestOptions.path.contains('/auth/');
        final alreadyRetried = err.requestOptions.extra[_retriedExtraKey] == true;
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

        // This interceptor owns the refresh for concurrent 401s.
        final gate = Completer<bool>();
        refreshGate = gate;
        final ok = await performRefresh();
        if (!ok) {
          await clearSession();
          onSessionExpired();
        }
        refreshGate = null;
        gate.complete(ok);

        if (!ok) return handler.next(err);
        return retry(err, handler);
      },
    ),
  );

  if (kDebugMode) {
    // Omit request headers so the bearer token is not logged.
    dio.interceptors.add(
      PrettyDioLogger(requestHeader: false, requestBody: true),
    );
  }

  return dio;
}
