import 'auth_context.dart';
import 'demo_snapshot.dart';
import 'store.dart';

/// Merges [DemoSnapshot] placeholder rows in front of live admin lists.
///
/// Active for B2B demo reviewers (`auth.isDemo`). Platform-wide overlays
/// (users, tickets, moderation queues, …) stay limited to the system-admin
/// demo; project CRM overlays also apply to the NestOne residence demo so
/// that workspace is fully populated. Rows are never inserted into [Store] —
/// a real admin on the same process must not see them. Writes stay blocked
/// by [demoGuardMiddleware].
class DemoOverlay {
  DemoOverlay._();

  static bool isDemo(AuthContext? auth) => auth != null && auth.isDemo;

  static bool isPlatformActive(AuthContext? auth) =>
      isDemo(auth) && auth!.isSystemAdmin;

  static bool isResidenceActive(AuthContext? auth) =>
      isDemo(auth) && auth!.isResidenceAdmin;

  /// Any demo admin that may see CRM placeholder leads.
  static bool isCrmActive(AuthContext? auth) =>
      isPlatformActive(auth) || isResidenceActive(auth);

  /// Back-compat alias used by older call sites / docs.
  static bool isActive(AuthContext? auth) => isPlatformActive(auth);

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

  static Set<String> _ownedProjectIds(AuthContext auth, Store store) {
    return store
        .projectsForDeveloperOwner(auth.userId)
        .map((p) => p['id'] as String)
        .toSet();
  }

  static List<Map<String, dynamic>> _crmOverlayLeads(
    AuthContext auth,
    Store store, {
    String? projectId,
  }) {
    var overlay = DemoSnapshot.leads(store, projectId: projectId);
    if (isResidenceActive(auth) && !isPlatformActive(auth)) {
      final owned = _ownedProjectIds(auth, store);
      overlay = overlay
          .where((l) => owned.contains(l['projectId'] as String?))
          .toList();
    }
    return overlay;
  }

  static List<Map<String, dynamic>> leads(
    AuthContext? auth,
    Store store,
    List<Map<String, dynamic>> live, {
    String? projectId,
  }) {
    if (!isCrmActive(auth)) return live;
    return prepend(
      _crmOverlayLeads(auth!, store, projectId: projectId),
      live,
    );
  }

  static Map<String, dynamic>? leadById(
    AuthContext? auth,
    Store store,
    String id,
  ) {
    if (!isCrmActive(auth) || !isOverlayId(id)) return null;
    final lead = DemoSnapshot.leadById(store, id);
    if (lead == null) return null;
    if (isResidenceActive(auth) && !isPlatformActive(auth)) {
      final owned = _ownedProjectIds(auth!, store);
      if (!owned.contains(lead['projectId'] as String?)) return null;
    }
    return lead;
  }

  static List<Map<String, dynamic>> leadEvents(AuthContext? auth, String id) {
    if (!isCrmActive(auth) || !isOverlayId(id)) return const [];
    return DemoSnapshot.leadEvents(id);
  }

  static List<Map<String, dynamic>> users(
    AuthContext? auth,
    List<Map<String, dynamic>> live,
  ) {
    if (!isPlatformActive(auth)) return live;
    return prepend(DemoSnapshot.extraUsers(), live);
  }

  static List<Map<String, dynamic>> pendingDevelopers(
    AuthContext? auth,
    List<Map<String, dynamic>> live,
  ) {
    if (!isPlatformActive(auth)) return live;
    return prepend(DemoSnapshot.pendingDevelopers(), live);
  }

  static List<Map<String, dynamic>>? documentsForDeveloper(
    AuthContext? auth,
    String developerId,
  ) {
    if (!isPlatformActive(auth) || !isOverlayId(developerId)) return null;
    return DemoSnapshot.documentsForDeveloper(developerId);
  }

  static List<Map<String, dynamic>> businesses(
    AuthContext? auth,
    List<Map<String, dynamic>> live,
  ) {
    if (!isPlatformActive(auth)) return live;
    return prepend(DemoSnapshot.businesses(), live);
  }

  static List<Map<String, dynamic>> tickets(
    AuthContext? auth,
    List<Map<String, dynamic>> live, {
    String? status,
  }) {
    if (!isPlatformActive(auth)) return live;
    return prepend(DemoSnapshot.tickets(status: status), live);
  }

  static Map<String, dynamic>? ticketById(AuthContext? auth, String id) {
    if (!isPlatformActive(auth) || !isOverlayId(id)) return null;
    return DemoSnapshot.ticketById(id);
  }

  static List<Map<String, dynamic>> notifications(
    AuthContext? auth,
    List<Map<String, dynamic>> live, {
    bool unreadOnly = false,
    int limit = 200,
  }) {
    if (!isPlatformActive(auth)) return live;
    var overlay = DemoSnapshot.notifications();
    if (unreadOnly) {
      overlay = overlay.where((n) => n['isRead'] != true).toList();
    }
    return prepend(overlay, live).take(limit).toList();
  }

  static int unreadNotificationCount(AuthContext? auth, int liveCount) {
    if (!isPlatformActive(auth)) return liveCount;
    return liveCount + DemoSnapshot.unreadNotificationCount();
  }

  static List<Map<String, dynamic>> pendingReviews(
    AuthContext? auth,
    Store store,
    List<Map<String, dynamic>> live,
  ) {
    if (!isPlatformActive(auth)) return live;
    return prepend(DemoSnapshot.pendingReviews(store), live);
  }

  static List<Map<String, dynamic>> pendingRentalListings(
    AuthContext? auth,
    List<Map<String, dynamic>> live,
  ) {
    if (!isPlatformActive(auth)) return live;
    return prepend(DemoSnapshot.pendingRentalListings(), live);
  }

  static List<Map<String, dynamic>> auditLog(
    AuthContext? auth,
    List<Map<String, dynamic>> live, {
    int limit = 100,
  }) {
    if (!isPlatformActive(auth)) return live.take(limit).toList();
    return prepend(DemoSnapshot.auditLog(), live).take(limit).toList();
  }

  static int auditLogTotal(AuthContext? auth, int liveCount) {
    if (!isPlatformActive(auth)) return liveCount;
    return liveCount + DemoSnapshot.auditLog().length;
  }

  static Map<String, dynamic> analytics(
    AuthContext? auth,
    Store store,
    Map<String, dynamic> live,
  ) {
    if (!isPlatformActive(auth)) return live;
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

  /// Bumps project CRM analytics with overlay lead counts for demo sessions.
  static Map<String, dynamic> projectAnalytics(
    AuthContext? auth,
    Store store,
    String projectId,
    Map<String, dynamic> live,
  ) {
    if (!isCrmActive(auth)) return live;
    if (isResidenceActive(auth) && !isPlatformActive(auth)) {
      final owned = _ownedProjectIds(auth!, store);
      if (!owned.contains(projectId)) return live;
    }
    final overlay = DemoSnapshot.leads(store, projectId: projectId);
    if (overlay.isEmpty) return live;
    final merged = Map<String, dynamic>.from(live);
    final funnel = Map<String, int>.from(
      (merged['leadFunnel'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          const <String, int>{},
    );
    for (final lead in overlay) {
      final status = lead['status'] as String? ?? 'new';
      funnel[status] = (funnel[status] ?? 0) + 1;
    }
    merged['leadFunnel'] = funnel;
    merged['leadsTotal'] =
        (merged['leadsTotal'] as num? ?? 0).toInt() + overlay.length;
    merged['leadsLast30Days'] =
        (merged['leadsLast30Days'] as num? ?? 0).toInt() + overlay.length;
    return merged;
  }
}
