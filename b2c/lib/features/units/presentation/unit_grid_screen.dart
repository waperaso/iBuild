import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/constrained_body.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../l10n/enum_labels.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../providers/compare_providers.dart';
import '../providers/live_unit_status_provider.dart';

/// Availability chessboard; live status via [liveUnitStatusProvider].
/// App-bar compare mode toggles multi-select for `/compare`.
class UnitGridScreen extends ConsumerStatefulWidget {
  const UnitGridScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<UnitGridScreen> createState() => _UnitGridScreenState();
}

class _UnitGridScreenState extends ConsumerState<UnitGridScreen> {
  bool _compareMode = false;
  UnitKind? _kindFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final projectAsync = ref.watch(projectByIdProvider(widget.projectId));
    final liveStatus = ref.watch(liveUnitStatusProvider(widget.projectId));
    final compareIds = ref.watch(compareProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(l10n.availabilityTitle),
        actions: [
          IconButton(
            icon: Icon(
              Icons.compare_arrows,
              color: _compareMode ? colors.accent : colors.ink,
            ),
            tooltip: l10n.compareModeAction,
            onPressed: () => setState(() => _compareMode = !_compareMode),
          ),
        ],
      ),
      body: Stack(
        children: [
          ConstrainedBody(
            maxWidth: 900,
            child: AsyncValueView(
              value: projectAsync,
              minHeight: 400,
              onRetry: () =>
                  ref.invalidate(projectByIdProvider(widget.projectId)),
              builder: (context, project) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl * 2,
                ),
                children: [
                  _KindFilterBar(
                    value: _kindFilter,
                    onChanged: (kind) => setState(() => _kindFilter = kind),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _Legend(),
                  const SizedBox(height: AppSpacing.sm),
                  const _RoomLegend(),
                  const SizedBox(height: AppSpacing.lg),
                  for (final building in project.buildings)
                    _BuildingGrid(
                      buildingName: building.name,
                      units: _kindFilter == null
                          ? building.units
                          : building.units
                                .where((u) => u.kind == _kindFilter)
                                .toList(),
                      projectId: widget.projectId,
                      liveStatus: liveStatus,
                      compareMode: _compareMode,
                      compareIds: compareIds,
                    ),
                ],
              ),
            ),
          ),
          if (compareIds.isNotEmpty)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: SafeArea(
                top: false,
                child: PillButton(
                  label: l10n.compareCountLabel(compareIds.length),
                  expand: true,
                  onPressed: () => context.push('/compare'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "All" + one chip per [UnitKind] — filters the grid below without
/// touching the underlying data (plan: "Split by property type").
class _KindFilterBar extends StatelessWidget {
  const _KindFilterBar({required this.value, required this.onChanged});

  final UnitKind? value;
  final ValueChanged<UnitKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ChoiceChip(
          label: Text(l10n.chessboardFilterAll),
          selected: value == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final kind in UnitKind.values)
          ChoiceChip(
            label: Text(kind.label(context)),
            selected: value == kind,
            onSelected: (_) => onChanged(kind),
          ),
      ],
    );
  }
}

/// Small colour key mapping room count → the corner accent shown on each
/// cell — status (fill colour) stays the primary signal; this is secondary.
class _RoomLegend extends StatelessWidget {
  const _RoomLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.chessboardRoomsLegendTitle,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        for (var rooms = 1; rooms <= 4; rooms++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: roomAccentColor(rooms),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                rooms == 4 ? l10n.chessboardRooms4Plus : '$rooms',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final items = <(String, Color)>[
      (UnitStatus.available.label(context), colors.unitAvailable),
      (UnitStatus.reserved.label(context), colors.unitReserved),
      (l10n.legendSoldRented, colors.unitSold),
      (UnitStatus.blocked.label(context), colors.unitBlocked),
    ];
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (label, color) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
      ],
    );
  }
}

class _BuildingGrid extends StatelessWidget {
  const _BuildingGrid({
    required this.buildingName,
    required this.units,
    required this.projectId,
    required this.liveStatus,
    required this.compareMode,
    required this.compareIds,
  });

  final String buildingName;
  final List<Unit> units;
  final String projectId;
  final Map<String, UnitStatus> liveStatus;
  final bool compareMode;
  final List<String> compareIds;

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    // Group units by floor, descending (top floor first, like a real board).
    final byFloor = <int, List<Unit>>{};
    for (final u in units) {
      byFloor.putIfAbsent(u.floor, () => []).add(u);
    }
    final floors = byFloor.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(buildingName, style: textTheme.titleLarge),
        ),
        for (final floor in floors)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('$floor', style: textTheme.labelMedium),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final u in byFloor[floor]!)
                        _UnitCell(
                          unit: u,
                          projectId: projectId,
                          liveStatus: liveStatus[u.id],
                          compareMode: compareMode,
                          selected: compareIds.contains(u.id),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Fixed room-count → accent color (not theme-dependent).
Color roomAccentColor(int? rooms) => switch (rooms) {
  null => Colors.transparent,
  1 => const Color(0xFF3B82F6),
  2 => const Color(0xFF10B981),
  3 => const Color(0xFFF59E0B),
  _ => const Color(0xFF8B5CF6),
};

class _UnitCell extends ConsumerWidget {
  const _UnitCell({
    required this.unit,
    required this.projectId,
    required this.compareMode,
    required this.selected,
    this.liveStatus,
  });

  final Unit unit;
  final String projectId;
  final bool compareMode;
  final bool selected;

  /// Overrides [Unit.status] when a `unitStatusChanged` push has arrived
  /// for this unit since the project was fetched (see
  /// `live_unit_status_provider.dart`) — live status wins when present.
  final UnitStatus? liveStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final status = liveStatus ?? unit.status;
    final color = switch (status) {
      UnitStatus.available => colors.unitAvailable,
      UnitStatus.reserved => colors.unitReserved,
      UnitStatus.sold || UnitStatus.rented => colors.unitSold,
      UnitStatus.blocked => colors.unitBlocked,
    };
    final tappable =
        status == UnitStatus.available || status == UnitStatus.reserved;
    final onTap = !tappable
        ? null
        : compareMode
        ? () => ref.read(compareProvider.notifier).toggle(unit.id)
        : () => context.go('/home/unit/${unit.id}?project=$projectId');
    final accent = roomAccentColor(unit.rooms);

    final cell = Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: selected
            ? Border.all(color: colors.accent, width: 2.5)
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Text(
              unit.number,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: status == UnitStatus.blocked ? Colors.white : colors.ink,
              ),
            ),
          ),
          if (unit.rooms != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        richMessage: WidgetSpan(child: _UnitPreviewCard(unit: unit)),
        waitDuration: const Duration(milliseconds: 300),
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        decoration: const BoxDecoration(),
        child: cell,
      ),
    );
  }
}

/// Compact hover/long-press preview: unit number, room count, area, price,
/// price/m², and the first floorplan thumbnail if one exists (plan photo3).
class _UnitPreviewCard extends StatelessWidget {
  const _UnitPreviewCard({required this.unit});

  final Unit unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final floorplans = unit.media.where((m) => m.type == MediaType.floorplan);
    final floorplan = floorplans.isEmpty ? null : floorplans.first;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 12),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (floorplan != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Image.network(
                  floorplan.url,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            if (floorplan != null) const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.unitNumberTitle(unit.number),
              style: textTheme.titleSmall?.copyWith(color: colors.ink),
            ),
            const SizedBox(height: 2),
            if (unit.rooms != null)
              Text(
                l10n.roomsCount(unit.rooms!),
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
            if (unit.areaTotal != null)
              Text(
                Formatters.area(unit.areaTotal!),
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
            if (unit.price != null)
              Text(
                Formatters.price(unit.price!),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (unit.priceM2 != null)
              Text(
                Formatters.pricePerM2(unit.priceM2!),
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
          ],
        ),
      ),
    );
  }
}
