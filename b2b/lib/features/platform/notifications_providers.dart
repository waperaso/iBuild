import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/ws_client.dart';
import '../admin/admin_api.dart';

/// System-admin notification inbox: REST restore + `adminNotification` WS pushes.
/// For platform screens only (residence tokens cannot call `/platform/notifications`).
class AdminNotificationsController
    extends Notifier<AsyncValue<List<Map<String, dynamic>>>> {
  StreamSubscription<WsEvent>? _subscription;

  @override
  AsyncValue<List<Map<String, dynamic>>> build() {
    ref.onDispose(() => _subscription?.cancel());
    _subscribe();
    unawaited(_load());
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    try {
      final items = await ref.read(adminApiProvider).notifications();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribe() {
    final client = ref.read(wsClientProvider);
    _subscription = client.connect().listen(_onEvent);
  }

  void _onEvent(WsEvent event) {
    if (event.type != WsEventType.adminNotification) return;
    final current = state.value ?? const <Map<String, dynamic>>[];
    if (current.any((n) => n['id'] == event.payload['id'])) return;
    state = AsyncValue.data([event.payload, ...current]);
  }

  Future<void> refresh() => _load();

  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data([
      for (final n in current)
        if (n['id'] == id) {...n, 'isRead': true} else n,
    ]);
    try {
      await ref.read(adminApiProvider).markNotificationRead(id);
    } catch (_) {
      // Optimistic local update already applied.
    }
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null || current.isEmpty) return;
    state = AsyncValue.data([
      for (final n in current) {...n, 'isRead': true},
    ]);
    try {
      await ref.read(adminApiProvider).markAllNotificationsRead();
    } catch (_) {
      // Optimistic local update already applied.
    }
  }
}

final adminNotificationsProvider = NotifierProvider<
  AdminNotificationsController,
  AsyncValue<List<Map<String, dynamic>>>
>(AdminNotificationsController.new);

final unreadAdminNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(adminNotificationsProvider).value ?? const [];
  return items.where((n) => n['isRead'] != true).length;
});
