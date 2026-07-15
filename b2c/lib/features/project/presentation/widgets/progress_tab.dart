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

/// Construction-progress timeline tab (plan section 11 "Trust system") —
/// dated photo reports from [photoReportsProvider], grouped by month, with
/// the project's overall progress-percent bar at the top. Falls back to an
/// empty state when a project has no photo reports yet (e.g. ready/handed
/// over projects, or one that hasn't been photographed yet).
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
                _OverallProgressBar(project: project),
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
              _OverallProgressBar(project: project),
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

class _OverallProgressBar extends StatelessWidget {
  const _OverallProgressBar({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final progress = (project.constructionProgress ?? 0).clamp(0, 100) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.overallProgressTitle, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: colors.surfaceAlt,
            color: colors.accent,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Text(
              l10n.builtPercent(project.constructionProgress ?? 0),
              style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
            ),
            const Spacer(),
            if (project.completionDate != null)
              Text(
                l10n.completionDate(Formatters.date(project.completionDate!)),
                style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
              ),
          ],
        ),
      ],
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
