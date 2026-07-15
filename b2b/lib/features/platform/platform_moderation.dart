import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import 'platform_providers.dart';
import 'platform_widgets.dart';

/// Moderation queue: new ЖК submissions awaiting publish, warn/unpublish
/// actions on already-published ones, flagged reviews, and pending rental
/// listings — split out of the platform dashboard so it reads as its own
/// inbox rather than being buried among KPIs and users.
class PlatformModeration extends ConsumerWidget {
  const PlatformModeration({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;
    final pendingProjects = ref.watch(platformPendingProjectsProvider);
    final pendingReviews = ref.watch(platformPendingReviewsProvider);
    final pendingRentalListings = ref.watch(platformPendingRentalListingsProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(l10n.moderationTitle, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.moderationSubtitle,
          style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: l10n.platformPendingProjectsSectionTitle),
        const SizedBox(height: AppSpacing.md),
        pendingProjects.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.apartment_outlined,
                title: l10n.platformNoPendingProjects,
              );
            }
            return Column(
              children: [
                for (final p in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name']?.toString() ?? '',
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${p['district'] ?? ''} · ${p['type'] ?? ''}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.inkMuted,
                                  ),
                                ),
                                if ((p['developer'] as Map?)?['name']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    l10n.platformProjectDeveloper(
                                      (p['developer'] as Map)['name']
                                          .toString(),
                                    ),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colors.inkMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PillButton(
                            label: l10n.platformPublish,
                            onPressed: () => runPlatformAction(
                              context,
                              ref,
                              action: () => ref
                                  .read(adminApiProvider)
                                  .moderateProject(
                                    p['id'] as String,
                                    decision: 'approve',
                                  ),
                              onSuccess: () =>
                                  invalidatePlatformProjectLists(ref),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PillButton(
                            label: l10n.platformReject,
                            variant: PillButtonVariant.outline,
                            onPressed: () async {
                              final note = await showDialog<String>(
                                context: context,
                                builder: (_) => NoteDialog(
                                  title: l10n.platformReject,
                                  hint: l10n.platformDeclineReasonHint,
                                  confirmLabel: l10n.platformReject,
                                ),
                              );
                              if (note == null || !context.mounted) return;
                              await runPlatformAction(
                                context,
                                ref,
                                action: () => ref
                                    .read(adminApiProvider)
                                    .moderateProject(
                                      p['id'] as String,
                                      decision: 'reject',
                                      note: note,
                                    ),
                                onSuccess: () =>
                                    invalidatePlatformProjectLists(ref),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: l10n.platformPendingReviewsSectionTitle),
        const SizedBox(height: AppSpacing.md),
        pendingReviews.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.reviews_outlined,
                title: l10n.platformNoPendingReviews,
              );
            }
            return Column(
              children: [
                for (final r in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r['userName'] ?? l10n.platformAnonymous} · '
                                  '${r['ratingOverall'] ?? '—'}★',
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  r['body']?.toString() ?? '',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PillButton(
                            label: l10n.platformKeep,
                            onPressed: () async {
                              await ref
                                  .read(adminApiProvider)
                                  .moderateReview(
                                    r['id'] as String,
                                    keep: true,
                                  );
                              ref.invalidate(platformPendingReviewsProvider);
                            },
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PillButton(
                            label: l10n.platformRemove,
                            variant: PillButtonVariant.outline,
                            onPressed: () async {
                              await ref
                                  .read(adminApiProvider)
                                  .moderateReview(
                                    r['id'] as String,
                                    keep: false,
                                  );
                              ref.invalidate(platformPendingReviewsProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SectionHeader(title: l10n.platformPendingRentalsSectionTitle),
        const SizedBox(height: AppSpacing.md),
        pendingRentalListings.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                compact: true,
                icon: Icons.home_work_outlined,
                title: l10n.platformNoPendingRentals,
              );
            }
            return Column(
              children: [
                for (final l in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l['title']?.toString() ?? '',
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${l['district'] ?? ''} · '
                                  '${l['propertyKind'] ?? ''} · '
                                  '${l['rentMonthly'] ?? '—'}/mo · '
                                  '${l['contactPhone'] ?? ''}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PillButton(
                            label: l10n.platformApprove,
                            onPressed: () async {
                              await ref
                                  .read(adminApiProvider)
                                  .moderateRentalListing(
                                    l['id'] as String,
                                    approve: true,
                                  );
                              ref.invalidate(platformPendingRentalListingsProvider);
                            },
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PillButton(
                            label: l10n.platformReject,
                            variant: PillButtonVariant.outline,
                            onPressed: () async {
                              await ref
                                  .read(adminApiProvider)
                                  .moderateRentalListing(
                                    l['id'] as String,
                                    approve: false,
                                    note: l10n.platformRentalRejectNoteDefault,
                                  );
                              ref.invalidate(platformPendingRentalListingsProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
      ],
    );
  }
}
