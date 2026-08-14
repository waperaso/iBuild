import 'auth_context.dart';
import 'demo_snapshot.dart';
import 'store.dart';

/// Merges [DemoSnapshot] placeholder rows in front of live admin lists.
///
/// Active only for the B2B **platform** demo reviewer (`auth.isDemo` and
/// system admin). Rows are never inserted into [Store] — a real admin on the
/// same process must not see them. Writes stay blocked by
/// [demoGuardMiddleware].
class DemoOverlay {
  DemoOverlay._();

  static bool isActive(AuthContext? auth) =>
      auth != null && auth.isDemo && auth.isSystemAdmin;

  static bool isOverlayId(String id) => id.startsWith(DemoSnapshot.idPrefix);

  /// Overlay first, live after; skip overlay ids that already exist live.
  static List<Map<String, dynamic>> prepend(
    List<Map<String, dynamic>> overlay,
    List<Map<String, dynamic>> live,
  ) {
    if (overlay.isEmpty) return live;
    final liveIds = {for (final row in live) row['id']};
    return [
      ...overlay.where((row) => !liveIds.contains(row['id'])),
      ...live,
    ];
  }

  static List<Map<String, dynamic>> leads(
    AuthContext? auth,
    Store store,
    List<Map<String, dynamic>> live, {
    String? projectId,
  }) {
    if (!isActive(auth)) return live;
    return prepend(DemoSnapshot.leads(store, projectId: projectId), live);
  }

  static Map<String, dynamic>? leadById(
    AuthContext? auth,
    Store store,
    String id,
  ) {
    if (!isActive(auth) || !isOverlayId(id)) return null;
    return DemoSnapshot.leadById(store, id);
  }

  static List<Map<String, dynamic>> leadEvents(AuthContext? auth, String id) {
    if (!isActive(auth) || !isOverlayId(id)) return const [];
    return DemoSnapshot.leadEvents(id);
  }

  static List<Map<String, dynamic>> users(
    AuthContext? auth,
    List<Map<String, dynamic>> live,
  ) {
    if (!isActive(auth)) return live;
    return prepend(DemoSnapshot.extraUsers(), live);
  }

  static List<Map<String, dynamic>> pendingDevelopers(
    AuthContext? auth,
    List<Map<String, dynamic>> live,
  ) {
    if (!isActive(auth)) return live;
    return prepend(DemoSnapshot.pendingDevelopers(), live);
  }

  static List<Map<String, dynamic>>? documentsForDeveloper(
    AuthContext? auth,
    String developerId,
  ) {
    if (!isActive(auth) || !isOverlayId(developerId)) return null;
    return DemoSnapshot.documentsForDeveloper(developerId);
  }

  static List<Map<String, dynamic>> businesses(
    AuthContext? auth,
    List<Map<String, dynamic>> live,
  ) {
    if (!isActive(auth)) return live;
    return prepend(DemoSnapshot.businesses(), live);
  }

  static List<Map<String, dynamic>> tickets(
    AuthContext? auth,
    List<Map<String, dynamic>> live, {
    String? status,
  }) {
    if (!isActive(auth)) return live;
    return prepend(DemoSnapshot.tickets(status: status), live);
  }

  static Map<String, dynamic>? ticketById(AuthContext? auth, String id) {
    if (!isActive(auth) || !isOverlayId(id)) return null;
    return DemoSnapshot.ticketById(id);
  }

  static List<Map<String, dynamic>> notifications(
    AuthContext? auth,
    List<Map<String, dynamic>> live, {
    bool unreadOnly = false,
    int limit = 200,
  }) {
    if (!isActive(auth)) return live;
    var overlay = DemoSnapshot.notifications();
    if (unreadOnly) {
      overlay = overlay.where((n) => n['isRead'] != true).toList();
    }
    return prepend(overlay, live).take(limit).toList();
  }

  static int unreadNotificationCount(AuthContext? auth, int liveCount) {
    if (!isActive(auth)) return liveCount;
    return liveCount + DemoSnapshot.unreadNotificationCount();
  }

  static List<Map<String, dynamic>> pendingReviews(
    AuthContext? auth,
    Store store,
    List<Map<String, dynamic>> live,
  ) {
    if (!isActive(auth)) return live;
    return prepend(DemoSnapshot.pendingReviews(store), live);
  }

  static List<Map<String, dynamic>> pendingRentalListings(
    AuthContext? auth,
    List<Map<String, dynamic>> live,
  ) {
    if (!isActive(auth)) return live;
    return prepend(DemoSnapshot.pendingRentalListings(), live);
  }

  static List<Map<String, dynamic>> auditLog(
    AuthContext? auth,
    List<Map<String, dynamic>> live, {
    int limit = 100,
  }) {
    if (!isActive(auth)) return live.take(limit).toList();
    return prepend(DemoSnapshot.auditLog(), live).take(limit).toList();
  }

  static int auditLogTotal(AuthContext? auth, int liveCount) {
    if (!isActive(auth)) return liveCount;
    return liveCount + DemoSnapshot.auditLog().length;
  }

  static Map<String, dynamic> analytics(
    AuthContext? auth,
    Store store,
    Map<String, dynamic> live,
  ) {
    if (!isActive(auth)) return live;
    final deltas = DemoSnapshot.analyticsDeltas(store);
    final merged = Map<String, dynamic>.from(live);
    for (final entry in deltas.entries) {
      final current = merged[entry.key];
      if (current is int) {
        merged[entry.key] = current + entry.value;
      } else if (current is num) {
        merged[entry.key] = current.toInt() + entry.value;
      }
    }
    return merged;
  }
}
