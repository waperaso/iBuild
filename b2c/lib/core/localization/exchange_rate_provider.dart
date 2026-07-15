import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/formatters.dart';

/// Fallback when the public rate API is unreachable (approx. market rate).
const kFallbackUsdToUzs = 12650.0;

/// Fetches the live USD→UZS rate from exchangerate-api.com (no API key).
/// Result is cached in [Formatters.usdToUzsRate] for the session.
final exchangeRateProvider = FutureProvider<double>((ref) async {
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final response = await dio.get<Map<String, dynamic>>(
      'https://api.exchangerate-api.com/v4/latest/USD',
    );
    final rates = response.data?['rates'] as Map<String, dynamic>?;
    final uzs = rates?['UZS'];
    if (uzs is num && uzs > 0) {
      final rate = uzs.toDouble();
      Formatters.usdToUzsRate = rate;
      return rate;
    }
  } catch (_) {
    // Offline / CORS-blocked — keep the fallback.
  }
  Formatters.usdToUzsRate = kFallbackUsdToUzs;
  return kFallbackUsdToUzs;
});

/// Convenience read of the cached rate (falls back when the fetch is pending).
final usdToUzsRateProvider = Provider<double>((ref) {
  return ref.watch(exchangeRateProvider).value ?? Formatters.usdToUzsRate;
});
