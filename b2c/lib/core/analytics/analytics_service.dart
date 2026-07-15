import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pluggable analytics seam.
///
/// There's no analytics SaaS key wired up yet, so [ConsoleAnalyticsService]
/// is the only implementation today; swap the provider override with a real
/// vendor-backed implementation (Firebase, Amplitude, Segment, ...) later
/// without touching call sites, since they only ever depend on this
/// abstract class.
abstract class AnalyticsService {
  void logEvent(String name, [Map<String, Object?>? params]);

  void setUser(String? id);
}

/// Default implementation: logs to the console in debug builds only, and is
/// a no-op in release/profile builds.
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
