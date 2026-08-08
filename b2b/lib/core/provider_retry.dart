import 'package:dio/dio.dart';

/// Skip retries on 4xx; short capped backoff otherwise.
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
