import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../l10n/gen/app_localizations.dart';
import 'platform_providers.dart';

enum _StatusFilter { all, pending, approved, rejected }

/// Platform-wide project roster for oversight (any moderation status).
class PlatformProjects extends ConsumerStatefulWidget {
  const PlatformProjects({super.key});

  @override
  ConsumerState<PlatformProjects> createState() => _PlatformProjectsState();
}

class _PlatformProjectsState extends ConsumerState<PlatformProjects> {
  var _filter = _StatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;
    final projects = ref.watch(platformAllProjectsProvider);
    final filter = _filter;
    final pad = isWide ? AppSpacing.xl : AppSpacing.lg;

    final filtered = projects.maybeWhen(
      data: (items) => items.where((p) {
        if (filter == _StatusFilter.all) return true;
        final status = p['moderationStatus']?.toString() ?? 'approved';
        return status == filter.name;
      }).toList(),
      orElse: () => const <Map<String, dynamic>>[],
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminProjectsTitle, style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.adminProjectsSubtitle,
                  style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final f in _StatusFilter.values)
                      ChoiceChip(
                        label: Text(_filterLabel(l10n, f)),
                        selected: filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (projects.isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (projects.hasError)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverToBoxAdapter(child: Text('${projects.error}')),
          )
        else if (filtered.isEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverToBoxAdapter(
              child: EmptyState(
                compact: true,
                icon: Icons.apartment_outlined,
                title: l10n.adminProjectsEmpty,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.xxxl),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ProjectRow(project: p),
                  );
                },
                childCount: filtered.length,
                addAutomaticKeepAlives: false,
              ),
            ),
          ),
      ],
    );
  }

  String _filterLabel(AppLocalizations l10n, _StatusFilter f) => switch (f) {
    _StatusFilter.all => l10n.adminProjectsFilterAll,
    _StatusFilter.pending => l10n.adminProjectsFilterPending,
    _StatusFilter.approved => l10n.adminProjectsFilterApproved,
    _StatusFilter.rejected => l10n.adminProjectsFilterRejected,
  };
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project});

  final Map project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final p = project;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: () => context.go('/residence/project/${p['id']}'),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(Icons.apartment_outlined, color: colors.inkMuted),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p['name']?.toString() ?? '',
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatusPill(
                        status: p['moderationStatus']?.toString() ?? 'approved',
                      ),
                      if (!(Map<String, dynamic>.from(p)
                          .boolOr('isPublished'))) ...[
                        const SizedBox(width: AppSpacing.xs),
                        _UnpublishedPill(l10n: l10n),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${p['district'] ?? ''} · ${p['type'] ?? ''} · '
                    '${(p['developer'] as Map?)?['name'] ?? ''}',
                    style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.adminProjectsMeta(
                      (p['gallery'] as List?)?.length ?? 0,
                      p['totalUnits']?.toString() ?? '0',
                    ),
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final color = switch (status) {
      'approved' => colors.success,
      'rejected' => colors.danger,
      _ => colors.warning,
    };
    final label = switch (status) {
      'approved' => l10n.adminProjectsFilterApproved,
      'rejected' => l10n.adminProjectsFilterRejected,
      _ => l10n.adminProjectsFilterPending,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _UnpublishedPill extends StatelessWidget {
  const _UnpublishedPill({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: colors.inkMuted.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        l10n.adminProjectsUnpublished,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.inkMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
