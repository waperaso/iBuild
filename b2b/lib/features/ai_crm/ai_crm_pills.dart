import 'package:flutter/material.dart';

import '../../core/localization/status_labels.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../l10n/gen/app_localizations.dart';

/// Small "AI" mark — uppercase label in a low-alpha accent pill with a
/// hairline border, per the plan's design rules (no gradients/glow/purple
/// clichés): "accent.withValues(alpha: 0.10) fill, 1px outline border".
class AiMarkBadge extends StatelessWidget {
  const AiMarkBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        'AI',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// "Example" marker for a card group the AI CRM assistant filled with sample
/// data because the workspace has no leads yet (`isExample` on the query
/// response). Deliberately neutral rather than accent-tinted so it labels the
/// demo answer without competing with [AiMarkBadge].
class AiExampleBadge extends StatelessWidget {
  const AiExampleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline, size: 14, color: colors.inkMuted),
          const SizedBox(width: AppSpacing.xs),
          Text(
            l10n.crmBotExampleBadge,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.inkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// AI score band pill — same visual treatment as `_ScorePill` in
/// platform_crm.dart (hot/warm tinted, cold neutral), reused for `aiBand`
/// values which share the same hot/warm/cold vocabulary as the manual score.
class AiBandPill extends StatelessWidget {
  const AiBandPill({super.key, required this.band});
  final String band;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final color = switch (band) {
      'hot' => colors.danger,
      'warm' => colors.warning,
      _ => colors.inkMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        leadScoreLabel(l10n, band),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Neutral chip for an `aiReasons[]` code (e.g. "no response in 24h").
class AiReasonChip extends StatelessWidget {
  const AiReasonChip({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        aiReasonLabel(l10n, code),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
