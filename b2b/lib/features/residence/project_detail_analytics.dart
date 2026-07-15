part of 'project_detail_admin.dart';

/// Project analytics summary: KPI stats plus lead-funnel and units-by-status
/// breakdowns.
class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({required this.analytics});

  final Map<String, dynamic> analytics;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final funnel =
        (analytics['leadFunnel'] as Map?)?.cast<String, dynamic>() ?? const {};
    final byStatus =
        (analytics['unitsByStatus'] as Map?)?.cast<String, dynamic>() ??
        const {};
    final sellThrough = analytics['sellThroughPercent'];
    final monthsToSellOut = analytics['estimatedMonthsToSellOut'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _Stat(
                label: l10n.projectLeadsStat,
                value: '${analytics['leadsLast30Days'] ?? 0}',
              ),
              _Stat(
                label: l10n.projectLeadsTotalStat,
                value: '${analytics['leadsTotal'] ?? 0}',
              ),
              _Stat(
                label: l10n.projectSellThroughStat,
                value: sellThrough == null ? '—' : '$sellThrough%',
              ),
              _Stat(
                label: l10n.projectMonthsToSellOutStat,
                value: monthsToSellOut?.toString() ?? '—',
              ),
              _Stat(
                label: l10n.projectUnitsStat,
                value: '${analytics['totalUnits'] ?? 0}',
              ),
            ],
          ),
          if (funnel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.projectLeadFunnelTitle, style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final entry in funnel.entries)
                  _MetaChip(
                    label:
                        '${leadStatusLabel(l10n, entry.key)}: ${entry.value}',
                  ),
              ],
            ),
          ],
          if (byStatus.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.projectUnitsByStatusTitle, style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final entry in byStatus.entries)
                  _MetaChip(
                    label:
                        '${unitStatusLabel(l10n, entry.key)}: ${entry.value}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A single labelled KPI value.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: textTheme.titleLarge),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Lead temperature chip (hot / warm / cold).
class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score});

  final String score;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final color = switch (score) {
      'hot' => colors.danger,
      'warm' => colors.accent,
      _ => colors.inkMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        leadScoreLabel(l10n, score),
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Small neutral pill used for metadata (moderation status, tags, funnel …).
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
