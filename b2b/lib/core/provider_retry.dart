import 'package:dio/dio.dart';

/// Riverpod 3 retries every failed provider by default (200ms → 6.4s
/// exponential). That is great for flaky networks, but hammering a
/// permanent 404 / 403 for ~15s made the B2B admin screen look hung
/// ("connection timeout") while the server log filled with the same
/// failing GET. Skip client errors; keep a short capped backoff for the
/// rest.
Duration? providerRetry(int retryCount, Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status != null && status >= 400 && status < 500) return null;
    // Connection/timeouts: a couple of retries, then surface the error.
    if (retryCount >= 2) return null;
    return Duration(milliseconds: 200 * (1 << retryCount));
  }
  if (retryCount >= 3) return null;
  return Duration(milliseconds: 200 * (1 << retryCount));
}
