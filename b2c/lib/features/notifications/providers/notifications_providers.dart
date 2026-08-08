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

/// In-app notifications from lead/offer WebSocket pushes; restored/persisted
/// locally. Non-`autoDispose` so events are captured while the app runs.
/// Structured fields are localized in the UI via [buyerNotificationCopy].
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
    final now = DateTime.now();
    final projectId = payload['projectId'] as String?;
    return switch (event.type) {
      WsEventType.leadStatusChanged => AppNotification(
        id: id,
        type: event.type,
        title: 'Inquiry status updated',
        body: 'Your inquiry is now "${payload['status'] ?? 'updated'}".',
        createdAt: now,
        projectId: projectId,
        status: payload['status']?.toString(),
      ),
      WsEventType.newOffer => AppNotification(
        id: id,
        type: event.type,
        title: 'New offer available',
        body:
            (payload['title'] as String?) ??
            'A new offer was added to a project you follow.',
        createdAt: now,
        projectId: projectId,
        offerTitle: payload['title'] as String?,
      ),
      WsEventType.leadCreated => AppNotification(
        id: id,
        type: event.type,
        title: 'Inquiry received',
        body: 'We received your inquiry and will be in touch shortly.',
        createdAt: now,
        projectId: projectId,
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
