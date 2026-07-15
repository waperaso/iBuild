import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/constrained_body.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/enum_labels.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/compare_providers.dart';
import '../providers/units_providers.dart';

/// Side-by-side comparison of the units selected via [compareProvider],
/// reached from the unit grid's "Compare (n)" bar or a unit card's
/// "Add to compare" action.
class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final unitIds = ref.watch(compareProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(l10n.compareTitle),
        actions: [
          if (unitIds.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(compareProvider.notifier).clear(),
              child: Text(l10n.clearFilters),
            ),
        ],
      ),
      body: unitIds.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.compare_arrows,
                title: l10n.compareEmpty,
              ),
            )
          : ConstrainedBody(
              maxWidth: 900,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final id in unitIds)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: _CompareColumn(unitId: id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _CompareColumn extends ConsumerWidget {
  const _CompareColumn({required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final unitAsync = ref.watch(unitByIdProvider(unitId));
    final unit = unitAsync.value;

    if (unit == null) {
      return AppCard(
        color: colors.surfaceAlt,
        child: SizedBox(
          height: 200,
          child: Center(
            child: unitAsync.isLoading
                ? const AppLoadingIndicator(size: 20, strokeWidth: 2.4)
                : Text(l10n.unitNotFound),
          ),
        ),
      );
    }

    final isRent = unit.dealType == DealType.rent;
    return AppCard(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.unitNumberTitle(unit.number),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: colors.inkMuted),
                onPressed: () =>
                    ref.read(compareProvider.notifier).toggle(unitId),
              ),
            ],
          ),
          const Divider(),
          _AttributeRow(
            label: l10n.compareAreaLabel,
            value: unit.areaTotal != null
                ? Formatters.area(unit.areaTotal!)
                : '—',
          ),
          _AttributeRow(
            label: l10n.comparePriceLabel,
            value: isRent
                ? Formatters.rentMonthly(unit.rentMonthly ?? 0)
                : Formatters.price(unit.price ?? 0),
          ),
          _AttributeRow(label: l10n.compareFloorLabel, value: '${unit.floor}'),
          _AttributeRow(
            label: l10n.compareRoomsLabel,
            value: unit.rooms != null
                ? l10n.roomsCount(unit.rooms!)
                : (unit.layout ?? '—'),
          ),
          _AttributeRow(
            label: l10n.compareStatusLabel,
            value: unit.status.label(context),
          ),
          _AttributeRow(label: l10n.compareViewLabel, value: unit.view ?? '—'),
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: colors.inkMuted),
          ),
          Text(value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
