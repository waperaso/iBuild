import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics seam; default is [ConsoleAnalyticsService].
abstract class AnalyticsService {
  void logEvent(String name, [Map<String, Object?>? params]);

  void setUser(String? id);
}

/// Debug console logging; no-op in release/profile.
class ConsoleAnalyticsService implements AnalyticsService {
  @override
  void logEvent(String name, [Map<String, Object?>? params]) {
    if (kDebugMode) {
      debugPrint('[analytics] event: $name ${params ?? const {}}');
    }
  }

  @override
  void setUser(String? id) {
    if (kDebugMode) {
      debugPrint('[analytics] setUser: $id');
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return ConsoleAnalyticsService();
});
