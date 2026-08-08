import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import '../admin/admin_api.dart';
import 'platform_providers.dart';
import 'platform_widgets.dart';

/// Published residences: warn / unpublish / delete (separate from pending queue).
class PlatformActiveProjects extends ConsumerWidget {
  const PlatformActiveProjects({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;
    final publishedProjects = ref.watch(platformPublishedProjectsProvider);
    final pad = isWide ? AppSpacing.xl : AppSpacing.lg;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.activeProjectsTitle, style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.activeProjectsSubtitle,
                  style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
        ),
        publishedProjects.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverToBoxAdapter(child: Text('$e')),
          ),
          data: (items) {
            if (items.isEmpty) {
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                sliver: SliverToBoxAdapter(
                  child: EmptyState(
                    compact: true,
                    icon: Icons.apartment_outlined,
                    title: l10n.platformNoPublishedProjects,
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.xxxl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        onTap: () =>
                            context.go('/residence/project/${p['id']}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      if ((p['moderationNote'] as String?)
                                              ?.isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          p['moderationNote'].toString(),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colors.warning,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: colors.inkMuted,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                PillButton(
                                  label: l10n.platformWarn,
                                  variant: PillButtonVariant.outline,
                                  onPressed: () async {
                                    final note = await showDialog<String>(
                                      context: context,
                                      builder: (_) => NoteDialog(
                                        title: l10n.platformWarnDialogTitle(
                                          p['name']?.toString() ?? '',
                                        ),
                                        hint: l10n.platformWarnReasonHint,
                                        confirmLabel: l10n.platformWarn,
                                      ),
                                    );
                                    if (note == null || !context.mounted) {
                                      return;
                                    }
                                    await runPlatformAction(
                                      context,
                                      ref,
                                      action: () => ref
                                          .read(adminApiProvider)
                                          .moderateProject(
                                            p['id'] as String,
                                            decision: 'warn',
                                            note: note,
                                          ),
                                      onSuccess: () =>
                                          invalidatePlatformProjectLists(ref),
                                    );
                                  },
                                ),
                                PillButton(
                                  label: l10n.platformUnpublish,
                                  variant: PillButtonVariant.outline,
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(l10n.platformUnpublish),
                                        content: Text(
                                          p['name']?.toString() ?? '',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: Text(l10n.commonCancel),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: Text(
                                              l10n.platformUnpublishConfirm,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true || !context.mounted) {
                                      return;
                                    }
                                    await runPlatformAction(
                                      context,
                                      ref,
                                      action: () => ref
                                          .read(adminApiProvider)
                                          .moderateProject(
                                            p['id'] as String,
                                            decision: 'unpublish',
                                          ),
                                      onSuccess: () =>
                                          invalidatePlatformProjectLists(ref),
                                    );
                                  },
                                ),
                                PillButton(
                                  label: l10n.projectDelete,
                                  variant: PillButtonVariant.outline,
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(
                                          l10n.projectDeleteConfirmTitle(
                                            p['name']?.toString() ?? '',
                                          ),
                                        ),
                                        content: Text(
                                          l10n.projectDeleteConfirmBody,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: Text(l10n.commonCancel),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: colors.danger,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: Text(l10n.projectDelete),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true || !context.mounted) {
                                      return;
                                    }
                                    await runPlatformAction(
                                      context,
                                      ref,
                                      action: () => ref
                                          .read(adminApiProvider)
                                          .deleteAdminProject(
                                            p['id'] as String,
                                          ),
                                      onSuccess: () =>
                                          invalidatePlatformProjectLists(ref),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: items.length,
                  addAutomaticKeepAlives: false,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
