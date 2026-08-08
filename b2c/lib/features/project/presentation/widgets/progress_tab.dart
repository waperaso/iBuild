import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../providers/photo_reports_providers.dart';
import 'media_gallery_viewer.dart';

/// Construction-progress timeline from [photoReportsProvider], grouped by month.
class ProgressTab extends ConsumerWidget {
  const ProgressTab({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reportsAsync = ref.watch(photoReportsProvider(project.id));

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(photoReportsProvider(project.id)),
      child: AsyncValueView(
        value: reportsAsync,
        onRetry: () => ref.invalidate(photoReportsProvider(project.id)),
        builder: (context, reports) {
          if (reports.isEmpty) {
            return ListView(
              children: [
                _ProgressComparison(project: project),
                const SizedBox(height: AppSpacing.lg),
                EmptyState(
                  compact: true,
                  icon: Icons.construction_outlined,
                  title: l10n.progressEmptyTitle,
                  subtitle: l10n.progressEmptySubtitle,
                ),
              ],
            );
          }

          final groups = <String, List<PhotoReport>>{};
          for (final report in reports) {
            final key =
                '${report.takenAt.year}-${report.takenAt.month.toString().padLeft(2, '0')}';
            groups.putIfAbsent(key, () => []).add(report);
          }
          final sortedKeys = groups.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView(
            children: [
              _ProgressComparison(project: project),
              const SizedBox(height: AppSpacing.lg),
              for (final key in sortedKeys) ...[
                _MonthSection(month: groups[key]!.first.takenAt, reports: groups[key]!),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Gap (percentage points) still treated as on schedule.
const int _onScheduleGap = 10;

/// Gap above which the project is flagged behind (see `Store.addPhotoReport`).
const int _acceptableGap = 15;

/// Confirmed vs schedule-promised progress (confirmed alone if no schedule).
class _ProgressComparison extends StatelessWidget {
  const _ProgressComparison({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final actual = (project.constructionProgress ?? 0).clamp(0, 100);
    final planned = project.plannedProgress?.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.overallProgressTitle, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _ProgressBar(
          label: l10n.actualProgressLabel,
          percent: actual,
          color: colors.accent,
        ),
        if (planned != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _ProgressBar(
            label: l10n.plannedProgressLabel,
            percent: planned,
            color: colors.inkMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScheduleVerdict(actual: actual, planned: planned),
        ],
        if (project.completionDate != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.completionDate(Formatters.date(project.completionDate!)),
            style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
          ),
        ],
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
              ),
            ),
            Text(
              '$percent%',
              style: textTheme.labelMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 10,
            backgroundColor: colors.surfaceAlt,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ScheduleVerdict extends StatelessWidget {
  const _ScheduleVerdict({required this.actual, required this.planned});

  final int actual;
  final int planned;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final gap = planned - actual;
    // A project promising nothing yet cannot be behind on that promise.
    final trustIndex = planned == 0
        ? 100
        : ((actual / planned) * 100).round().clamp(0, 100);

    final (String verdict, Color color) = switch (gap) {
      < 0 => (l10n.progressAheadOfSchedule, colors.success),
      <= _onScheduleGap => (l10n.progressOnSchedule, colors.success),
      <= _acceptableGap => (l10n.progressAcceptableDeviation, colors.warning),
      _ => (l10n.progressBehindSchedule, colors.danger),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  verdict,
                  style: textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
              Text(
                l10n.trustIndexLabel(trustIndex),
                style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.progressDeviation(gap.abs()),
            style: textTheme.labelMedium?.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.progressComparisonNote,
            style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({required this.month, required this.reports});

  final DateTime month;
  final List<PhotoReport> reports;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final latestWithProgress = reports.firstWhere(
      (r) => r.progressPercent != null,
      orElse: () => reports.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                Formatters.monthYear(month),
                style: textTheme.titleSmall,
              ),
            ),
            if (latestWithProgress.progressPercent != null)
              Text(
                l10n.builtPercent(latestWithProgress.progressPercent!),
                style: textTheme.labelMedium?.copyWith(color: colors.accent),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final report = reports[index];
              return GestureDetector(
                onTap: () => _openGallery(context, reports, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: Stack(
                    children: [
                      AppNetworkImage(
                        url: report.photoUrl,
                        width: 128,
                        height: 96,
                      ),
                      Positioned(
                        left: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Text(
                            Formatters.date(report.takenAt),
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openGallery(
    BuildContext context,
    List<PhotoReport> reports,
    int initialIndex,
  ) {
    showMediaGalleryViewer(
      context,
      media: [
        for (final r in reports)
          MediaItem(id: r.id, type: MediaType.photo, url: r.photoUrl),
      ],
      initialIndex: initialIndex,
    );
  }
}
