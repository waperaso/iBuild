import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/ws_client.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/notifications_repository.dart';
import '../models/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(),
);

/// Notifications synthesized from `leadStatusChanged` / `newOffer` /
/// `leadCreated` WebSocket pushes, restored from local storage on boot and
/// persisted back on every change — mirroring [LiveUnitStatusController]'s
/// subscribe-on-build idiom but for a global, non-`autoDispose` provider so
/// pushes are captured for as long as the app is running.
///
/// Notification copy is composed here (outside any [BuildContext]), so it's
/// plain English rather than run through `AppLocalizations` — acceptable for
/// synthesized push-style content, unlike the app's chrome strings.
class NotificationsController extends Notifier<List<AppNotification>> {
  StreamSubscription<WsEvent>? _subscription;

  @override
  List<AppNotification> build() {
    const restored = <AppNotification>[];
    _restore();
    _subscribe();
    ref.onDispose(() => _subscription?.cancel());
    return restored;
  }

  Future<void> _restore() async {
    final notifications = await ref
        .read(notificationsRepositoryProvider)
        .restore();
    if (notifications.isEmpty) return;
    state = notifications;
  }

  void _subscribe() {
    // No live backend in mock/offline mode — restored/local notifications
    // are all that's shown. The socket also requires auth; dialing without a
    // token produced a /v1/ws 401 reconnect storm on the API.
    if (Env.useMockData) return;
    final client = ref.read(wsClientProvider);
    _subscription = client.connect().listen(_onEvent);
    ref.listen(authControllerProvider, (previous, next) {
      // Ensure the shared client picks up sign-in / sign-out even if this
      // notifier was built before auth finished restoring.
      client.onAuthChanged();
    });
  }

  void _onEvent(WsEvent event) {
    final notification = _notificationFor(event);
    if (notification == null) return;
    state = [notification, ...state].take(kNotificationsCap).toList();
    unawaited(ref.read(notificationsRepositoryProvider).persist(state));
  }

  AppNotification? _notificationFor(WsEvent event) {
    final payload = event.payload;
    final id = 'wsn-${DateTime.now().microsecondsSinceEpoch}';
    return switch (event.type) {
      WsEventType.leadStatusChanged => AppNotification(
        id: id,
        type: event.type,
        title: 'Inquiry status updated',
        body: 'Your inquiry is now "${payload['status'] ?? 'updated'}".',
        createdAt: DateTime.now(),
        projectId: payload['projectId'] as String?,
      ),
      WsEventType.newOffer => AppNotification(
        id: id,
        type: event.type,
        title: 'New offer available',
        body:
            (payload['title'] as String?) ??
            'A new offer was added to a project you follow.',
        createdAt: DateTime.now(),
        projectId: payload['projectId'] as String?,
      ),
      WsEventType.leadCreated => AppNotification(
        id: id,
        type: event.type,
        title: 'Inquiry received',
        body: 'We received your inquiry and will be in touch shortly.',
        createdAt: DateTime.now(),
        projectId: payload['projectId'] as String?,
      ),
      _ => null,
    };
  }

  Future<void> markAllRead() async {
    if (state.every((n) => n.read)) return;
    state = [for (final n in state) n.copyWith(read: true)];
    await ref.read(notificationsRepositoryProvider).persist(state);
  }

  Future<void> markRead(String id) async {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(read: true) else n,
    ];
    await ref.read(notificationsRepositoryProvider).persist(state);
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsController, List<AppNotification>>(
      NotificationsController.new,
    );

final unreadNotificationsCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).where((n) => !n.read).length,
);
