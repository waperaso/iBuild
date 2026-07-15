import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/config/env.dart';
import '../../../core/network/ws_client.dart';

/// Maps the wire status strings sent by the server's `unitStatusChanged`
/// event (see `server/lib/src/store.dart`, `_startLiveUpdates`) onto
/// [UnitStatus], mirroring the `@JsonValue` mapping declared on the enum in
/// `packages/ibuild_core/lib/models/enums.dart`. Returns `null` for anything
/// unrecognized so a malformed/future status never crashes the grid.
UnitStatus? unitStatusFromWire(String? raw) => switch (raw) {
  'available' => UnitStatus.available,
  'reserved' => UnitStatus.reserved,
  'sold' => UnitStatus.sold,
  'rented' => UnitStatus.rented,
  'blocked' => UnitStatus.blocked,
  _ => null,
};

/// Live unit-status overrides for a single project, pushed over the
/// WebSocket (plan section 3, "Live availability via WebSocket").
///
/// Keyed by [projectId] so screens (e.g. [UnitGridScreen]) subscribe scoped
/// to whichever project they're viewing. This is an `autoDispose` family
/// provider: [build] subscribes on first watch and [Ref.onDispose]
/// unsubscribes once the last watcher goes away (e.g. the grid screen is
/// popped), so entering/leaving the screen is all that's needed to
/// subscribe/unsubscribe — no extra widget lifecycle plumbing required.
///
/// Values are `unitId -> UnitStatus` and should win over the static status
/// baked into the fetched `Project`/`Unit` models, since they reflect
/// pushes that arrived after that snapshot.
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
