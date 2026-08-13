import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';

/// Uppercase "AI" pill — the one mark used everywhere the assistant shows up
/// (FAB label, chat header, search bar, info sheets). Matches the
/// `TagBadge`/`UnitStatusBadge` treatment exactly: `labelMedium`,
/// `accent.withValues(alpha: 0.10)` fill, 1px `outline` border. No
/// gradients/glow/sparkle — see the plan's design constraints.
class AiMarkBadge extends StatelessWidget {
  const AiMarkBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: colors.outline),
      ),
      child: Text(
        'AI',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
