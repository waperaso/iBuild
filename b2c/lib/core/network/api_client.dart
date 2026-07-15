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

/// Secure storage key for the persisted signed-in user. Mirrors the constant
/// in `auth_repository.dart`; kept here too so the 401 interceptor can purge a
/// dead session without importing the auth feature.
const _authUserStorageKey = 'auth_user';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Marks a request that has already been retried once after a token refresh,
/// so a second 401 on the retry doesn't kick off an endless refresh loop.
const _retriedExtraKey = '__ibuild_retried__';

/// Configured [Dio] instance for the iBuild REST API.
///
/// Handles the standard `{ success, data, meta, error }` envelope, attaches
/// the bearer token, and on 401 refreshes via `/auth/refresh` then retries.
/// Concurrent 401s share a single in-flight refresh (queued behind it), and a
/// failed refresh signs the session out so the UI reflects the logout.
final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return _createDio(
    storage,
    onSessionExpired: () {
      // Reset the auth controller to a signed-out state. Invalidation rebuilds
      // it via `restoreSession()`, which — with the tokens just cleared —
      // resolves to `null`, so guarded UI drops back to guest/sign-in.
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

  // Non-null while a refresh is in flight; concurrent 401s await its result
  // (true = refreshed, retry; false = give up) instead of each firing their
  // own `/auth/refresh`.
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

        // A refresh is already running — wait for it rather than starting our
        // own, then retry (or fail) based on its outcome.
        final inFlight = refreshGate;
        if (inFlight != null) {
          final ok = await inFlight.future;
          if (!ok) return handler.next(err);
          return retry(err, handler);
        }

        // We own the refresh for this wave of 401s.
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
    // requestHeader stays false so the bearer token in the Authorization
    // header is never written to logs.
    dio.interceptors.add(
      PrettyDioLogger(requestHeader: false, requestBody: true),
    );
  }

  return dio;
}
