import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/ws_client.dart';
import '../admin/admin_api.dart';

/// Admin notification inbox — every developer-side change that needs a
/// system admin's attention (new/updated/submitted project, uploaded
/// verification document). Restored from the server on first watch, then
/// kept live by `adminNotification` pushes over `/v1/ws` (admin-only — see
/// `Store.notifyAdmins` on the server), mirroring the B2C app's
/// `NotificationsController` shape but backed by server-persisted state
/// instead of client-only synthesis.
///
/// Only ever watched from system-admin screens/shell — never built for a
/// residence admin, whose token can't call `/platform/notifications` anyway.
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
      // Best-effort — the optimistic local read state already applied.
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
      // Best-effort — same rationale as markRead.
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
