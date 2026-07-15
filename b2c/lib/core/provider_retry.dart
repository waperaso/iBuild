import 'package:dio/dio.dart';

/// Riverpod 3 retries failed providers with exponential backoff by
/// default. Don't retry permanent HTTP 4xx responses — only brief
/// retries for transient transport failures.
Duration? providerRetry(int retryCount, Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status != null && status >= 400 && status < 500) return null;
    if (retryCount >= 2) return null;
    return Duration(milliseconds: 200 * (1 << retryCount));
  }
  if (retryCount >= 3) return null;
  return Duration(milliseconds: 200 * (1 << retryCount));
}
