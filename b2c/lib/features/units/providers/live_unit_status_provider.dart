import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/config/env.dart';
import '../../../core/network/ws_client.dart';

/// Wire `unitStatusChanged` status → [UnitStatus]; null if unrecognized.
UnitStatus? unitStatusFromWire(String? raw) => switch (raw) {
  'available' => UnitStatus.available,
  'reserved' => UnitStatus.reserved,
  'sold' => UnitStatus.sold,
  'rented' => UnitStatus.rented,
  'blocked' => UnitStatus.blocked,
  _ => null,
};

/// Live unit-status overrides for one project via WebSocket (`unitId -> status`).
/// `autoDispose` family: subscribe on first watch, unsubscribe on last dispose.
/// Values override the static status from the last project fetch.
class LiveUnitStatusController extends Notifier<Map<String, UnitStatus>> {
  LiveUnitStatusController(this.projectId);

  final String projectId;

  @override
  Map<String, UnitStatus> build() {
    // Mock/offline runs have no live backend — skip the socket entirely and
    // fall back to the static status baked into the fetched models.
    if (Env.useMockData) return const {};

    final client = ref.watch(wsClientProvider);
    client.subscribeProject(projectId);

    final subscription = client.connect().listen(_onEvent);
    ref.onDispose(() {
      subscription.cancel();
      client.unsubscribeProject(projectId);
    });

    return const {};
  }

  void _onEvent(WsEvent event) {
    if (event.type != WsEventType.unitStatusChanged) return;
    final payload = event.payload;
    if (payload['projectId'] != projectId) return;

    final unitId = payload['unitId'] as String?;
    final status = unitStatusFromWire(payload['status'] as String?);
    if (unitId == null || status == null) return;

    state = {...state, unitId: status};
  }
}

final liveUnitStatusProvider = NotifierProvider.autoDispose
    .family<LiveUnitStatusController, Map<String, UnitStatus>, String>(
      LiveUnitStatusController.new,
    );
