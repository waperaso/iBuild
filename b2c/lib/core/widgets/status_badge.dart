import 'package:flutter/material.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../l10n/enum_labels.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';

/// Small colored badge for unit availability status (grid legend / unit card).
class UnitStatusBadge extends StatelessWidget {
  const UnitStatusBadge({super.key, required this.status});

  final UnitStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (status) {
      UnitStatus.available => colors.unitAvailable,
      UnitStatus.reserved => colors.unitReserved,
      UnitStatus.sold || UnitStatus.rented => colors.unitSold,
      UnitStatus.blocked => colors.unitBlocked,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            status.label(context),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.ink),
          ),
        ],
      ),
    );
  }
}

/// Generic pill tag (e.g. "Best Deal", "New build").
class TagBadge extends StatelessWidget {
  const TagBadge({super.key, required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: filled ? colors.accent : colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: filled ? colors.onAccent : colors.ink,
        ),
      ),
    );
  }
}
