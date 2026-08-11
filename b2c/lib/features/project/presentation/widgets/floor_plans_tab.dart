import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'media_gallery_viewer.dart';

/// Units grouped by layout/rooms for browsing floor-plan types.
class FloorPlansTab extends StatelessWidget {
  const FloorPlansTab({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final units = project.buildings.expand((b) => b.units).toList();
    if (units.isEmpty) {
      return Center(
        child: EmptyState(
          compact: true,
          icon: Icons.map_outlined,
          title: l10n.floorPlansEmptyMessage,
        ),
      );
    }

    final groups = <String, List<Unit>>{};
    for (final unit in units) {
      final key = unit.rooms != null
          ? 'rooms-${unit.rooms}'
          : 'layout-${unit.layout ?? 'default'}';
      groups.putIfAbsent(key, () => []).add(unit);
    }
    final sortedKeys = groups.keys.toList()
      ..sort(
        (a, b) => (groups[a]!.first.areaTotal ?? 0).compareTo(
          groups[b]!.first.areaTotal ?? 0,
        ),
      );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < sortedKeys.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _LayoutCard(project: project, units: groups[sortedKeys[index]]!),
        ],
      ],
    );
  }
}

class _LayoutCard extends StatelessWidget {
  const _LayoutCard({required this.project, required this.units});

  final Project project;
  final List<Unit> units;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sample = units.first;
    final label = sample.rooms != null
        ? l10n.layoutRoomsLabel(sample.rooms!)
        : (sample.layout ?? '');
    final available = units
        .where((u) => u.status == UnitStatus.available)
        .length;
    final isRent = sample.dealType == DealType.rent;

    final prices = units
        .map((u) => isRent ? u.rentMonthly : u.price)
        .whereType<double>()
        .toList();
    final priceLabel = prices.isEmpty
        ? null
        : isRent
        ? Formatters.rentMonthly(prices.reduce((a, b) => a < b ? a : b))
        : Formatters.price(prices.reduce((a, b) => a < b ? a : b));

    final floorplanMatches = sample.media.where(
      (m) => m.type == MediaType.floorplan,
    );
    final floorplan = floorplanMatches.isEmpty ? null : floorplanMatches.first;
    final gallery = [for (final u in units) ...u.media];

    return AppCard(
      border: true,
      color: context.colors.background,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => _showUnitsSheet(context, label, units),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => showMediaGalleryViewer(context, media: gallery),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: SizedBox(
                width: 76,
                height: 76,
                child: floorplan != null
                    ? MediaThumbnail(
                        item: floorplan,
                        size: 76,
                        rooms: sample.rooms,
                        layout: sample.layout,
                      )
                    : (sample.media.isNotEmpty
                          ? MediaThumbnail(item: sample.media.first, size: 76)
                          : Container(color: context.colors.surfaceAlt)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  sample.areaTotal != null
                      ? Formatters.area(sample.areaTotal!)
                      : '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (priceLabel != null)
                      TagBadge(
                        label: AppLocalizations.of(
                          context,
                        ).fromPrice(priceLabel),
                        filled: true,
                      ),
                    TagBadge(
                      label: l10n.layoutAvailability(available, units.length),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  void _showUnitsSheet(BuildContext context, String label, List<Unit> units) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, controller) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.viewAvailableUnits,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    itemCount: units.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final u = units[index];
                      final isRent = u.dealType == DealType.rent;
                      final price = isRent
                          ? Formatters.rentMonthly(u.rentMonthly ?? 0)
                          : Formatters.price(u.price ?? 0);
                      return AppCard(
                        border: true,
                        color: context.colors.background,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(
                            '/home/unit/${u.id}?project=${project.id}',
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${l10n.unitNumberTitle(u.number)} · ${l10n.floorLabel(u.floor)}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            UnitStatusBadge(status: u.status),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                price,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
