import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/constrained_body.dart';
import '../../../core/widgets/horizontal_scroll_rail.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/verification_card.dart';
import '../../../l10n/enum_labels.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../../favorites/providers/favorites_providers.dart';
import '../../calculators/presentation/mortgage_calculator_sheet.dart';
import 'widgets/floor_plans_tab.dart';
import 'widgets/location_tracking_hero.dart';
import 'widgets/media_gallery_viewer.dart';
import 'widgets/progress_tab.dart';
import 'widgets/reviews_tab.dart';

/// Project page: a live-tracking-style location hero (3D isometric map + a
/// floating card with developer contact and construction progress), then
/// tabs (Units / Floor plans / About / Reviews) and lead CTAs.
class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final projectAsync = ref.watch(projectByIdProvider(projectId));

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          title: Text(projectAsync.value?.name ?? ''),
          actions: [
            Consumer(
              builder: (context, ref, _) {
                final isFavorite = ref.watch(
                  favoritesProvider.select((ids) => ids.contains(projectId)),
                );
                return IconButton(
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).toggle(projectId),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? colors.danger : null,
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: ConstrainedBody(
          maxWidth: AppBreakpoints.maxContentWidth,
          child: AsyncValueView(
            value: projectAsync,
            minHeight: 400,
            onRetry: () => ref.invalidate(projectByIdProvider(projectId)),
            builder: (context, project) =>
                _ProjectBody(project: project, projectId: projectId),
          ),
        ),
      ),
    );
  }
}

class _ProjectBody extends StatelessWidget {
  const _ProjectBody({required this.project, required this.projectId});

  final Project project;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWide = !context.isMobile;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        isWide ? AppSpacing.xl : AppSpacing.lg,
        0,
      ),
      children: [
        LocationTrackingHero(project: project),
        SizedBox(height: isWide ? AppSpacing.lg : AppSpacing.sm),
        _InfoRow(project: project),
        if (project.gallery.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _GalleryStrip(project: project),
        ],
        const SizedBox(height: AppSpacing.lg),
        const _ProjectSectionTabs(),
        const SizedBox(height: AppSpacing.lg),
        _ProjectTabPanel(project: project),
        const SizedBox(height: AppSpacing.lg),
        if (project.priceMin != null) ...[
          Wrap(
            children: [
              OutlinedButton.icon(
                onPressed: () => showMortgageCalculatorSheet(
                  context,
                  price: project.priceMin!,
                  projectId: projectId,
                ),
                icon: const Icon(Icons.account_balance_outlined, size: 18),
                label: Text(l10n.mortgageCalculatorAction),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: l10n.viewUnitGrid,
                variant: PillButtonVariant.outline,
                expand: true,
                onPressed: () => context.go('/home/project/$projectId/grid'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PillButton(
                label: l10n.requestCallback,
                expand: true,
                onPressed: () =>
                    context.go('/home/lead/new?project=$projectId'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Pill chips for project sections — switches content without a nested scroll
/// viewport (unlike [TabBarView] inside a fixed-height box).
class _ProjectSectionTabs extends StatelessWidget {
  const _ProjectSectionTabs();

  static const _tabs = <(IconData, String Function(AppLocalizations l10n))>[
    (Icons.door_front_door_outlined, _tabUnits),
    (Icons.grid_view_rounded, _tabFloorPlans),
    (Icons.apartment_outlined, _tabAbout),
    (Icons.reviews_outlined, _tabReviews),
    (Icons.construction_outlined, _tabProgress),
  ];

  static String _tabUnits(AppLocalizations l10n) => l10n.tabUnits;
  static String _tabFloorPlans(AppLocalizations l10n) => l10n.tabFloorPlans;
  static String _tabAbout(AppLocalizations l10n) => l10n.tabAbout;
  static String _tabReviews(AppLocalizations l10n) => l10n.tabReviews;
  static String _tabProgress(AppLocalizations l10n) => l10n.tabProgress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabController = DefaultTabController.of(context);

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        return HorizontalScrollRow(
          height: 44,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppChip(
                  label: _tabs[i].$2(l10n),
                  icon: _tabs[i].$1,
                  selected: tabController.index == i,
                  onTap: () => tabController.animateTo(i),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProjectTabPanel extends StatelessWidget {
  const _ProjectTabPanel({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        return switch (tabController.index) {
          0 => _UnitsTab(project: project),
          1 => FloorPlansTab(project: project),
          2 => _AboutTab(project: project),
          3 => ReviewsTab(projectId: project.id),
          _ => ProgressTab(project: project),
        };
      },
    );
  }
}

class _GalleryStrip extends StatelessWidget {
  const _GalleryStrip({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.viewGalleryCount(project.gallery.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () =>
                  showMediaGalleryViewer(context, media: project.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(l10n.viewInsideLabel),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        HorizontalScrollRail(
          height: 84,
          itemCount: project.gallery.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => showMediaGalleryViewer(
              context,
              media: project.gallery,
              initialIndex: index,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: MediaThumbnail(item: project.gallery[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasSale = project.priceMin != null;
    final hasRent = project.rentMin != null;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        TagBadge(label: project.type.label(context), filled: true),
        // Some residential complexes sell most units but keep a handful for
        // long-term rent — surface both starting prices when that's the case
        // instead of hiding the rent option behind the sale price badge.
        if (hasSale)
          TagBadge(label: l10n.fromPrice(Formatters.price(project.priceMin!))),
        if (hasRent)
          TagBadge(
            label: l10n.rentFromPrice(Formatters.rentMonthly(project.rentMin!)),
          ),
        if (!hasSale && !hasRent) TagBadge(label: l10n.fromPrice('-')),
        for (final tag in project.tags) TagBadge(label: tag),
      ],
    );
  }
}

class _UnitsTab extends StatelessWidget {
  const _UnitsTab({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final units = project.buildings.expand((b) => b.units).take(6).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < units.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          Builder(
            builder: (context) {
              final u = units[index];
              final price = u.dealType == DealType.rent
                  ? Formatters.rentMonthly(u.rentMonthly ?? 0)
                  : Formatters.price(u.price ?? 0);
              final colors = context.colors;
              return AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                onTap: () =>
                    context.go('/home/unit/${u.id}?project=${project.id}'),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.accentSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Icon(
                        Icons.door_front_door_outlined,
                        size: 18,
                        color: colors.accentSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'No. ${u.number} · ${AppLocalizations.of(context).floorLabel(u.floor)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    UnitStatusBadge(status: u.status),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (project.developer != null) ...[
          _DeveloperCard(developer: project.developer!),
          const SizedBox(height: AppSpacing.md),
          VerificationCard(developerId: project.developer!.id),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          project.description ?? l10n.noDescription,
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.amenitiesTitle, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final a in project.amenities)
              Container(
                constraints: const BoxConstraints(minWidth: 128),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _amenityIcon(a),
                      size: 18,
                      color: colors.accentSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: Text(a, style: textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Maps free-form amenity labels to icons; unknown → checkmark.
IconData _amenityIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('pool')) return Icons.pool_outlined;
  if (l.contains('sauna') || l.contains('spa')) {
    return Icons.spa_outlined;
  }
  if (l.contains('gym')) return Icons.fitness_center_outlined;
  if (l.contains('parking')) return Icons.local_parking_outlined;
  if (l.contains('security') || l.contains('access control')) {
    return Icons.shield_outlined;
  }
  if (l.contains('playground') || l.contains('kindergarten')) {
    return Icons.child_friendly_outlined;
  }
  if (l.contains('courtyard') || l.contains('garden')) {
    return Icons.park_outlined;
  }
  if (l.contains('elevator')) return Icons.elevator_outlined;
  if (l.contains('concierge')) return Icons.support_agent_outlined;
  if (l.contains('terrace') || l.contains('rooftop')) {
    return Icons.deck_outlined;
  }
  if (l.contains('internet') || l.contains('fiber')) {
    return Icons.wifi_outlined;
  }
  if (l.contains('coworking') || l.contains('conference')) {
    return Icons.groups_outlined;
  }
  if (l.contains('commercial')) return Icons.storefront_outlined;
  if (l.contains('bicycle')) return Icons.pedal_bike_outlined;
  return Icons.check_circle_outline;
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({required this.developer});

  final Developer developer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.surfaceAlt,
            backgroundImage: developer.logoUrl != null
                ? NetworkImage(developer.logoUrl!)
                : null,
            child: developer.logoUrl != null
                ? null
                : Icon(Icons.business_outlined, color: colors.inkMuted),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(developer.name, style: textTheme.titleMedium),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: colors.warning),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      developer.rating.toStringAsFixed(1),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 1,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              l10n.iBuildPartner,
              style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
