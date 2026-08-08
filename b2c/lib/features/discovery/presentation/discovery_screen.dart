import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/developer_card.dart';
import '../../../core/widgets/district_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/horizontal_scroll_rail.dart';
import '../../../core/widgets/promo_banner.dart';
import '../../../core/widgets/responsive_card_grid.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../../rentals/data/rental_listings_repository.dart';
import '../../rentals/providers/rental_listings_providers.dart';
import '../../rentals/presentation/widgets/rental_listing_card.dart';
import '../providers/discovery_providers.dart';
import '../providers/filters_providers.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/property_card.dart';

/// Discovery home: mode toggle, search/filters, paginated project list.
class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _loadingMore = false;
  DateTime? _lastLoadMoreAt;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final notifier = ref.read(projectsProvider.notifier);
    if (_loadingMore || !notifier.hasMore) return;
    final now = DateTime.now();
    final last = _lastLoadMoreAt;
    // Keep paging from chaining into a burst of GETs while layout settles.
    if (last != null && now.difference(last) < const Duration(milliseconds: 600)) {
      return;
    }
    _lastLoadMoreAt = now;
    setState(() => _loadingMore = true);
    await notifier.loadMore();
    if (mounted) setState(() => _loadingMore = false);
  }

  /// Lazy sliver grid for projects — loading/error stay as box adapters so
  /// the outer [CustomScrollView] never materializes every card at once.
  List<Widget> _projectGridSlivers(
    BuildContext context,
    AsyncValue<List<Project>> projectsAsync,
  ) {
    const padding = EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.sm,
      AppSpacing.xl,
      AppSpacing.lg,
    );

    return projectsAsync.when(
      loading: () => [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: AsyncValueView<List<Project>>(
              value: const AsyncLoading(),
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
      error: (_, _) => [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: AsyncValueView<List<Project>>(
              value: projectsAsync,
              onRetry: () => ref.invalidate(projectsProvider),
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
      data: (projects) => [
        SliverPadding(
          padding: padding,
          sliver: ResponsiveCardSliverGrid(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return FadeSlideIn(
                index: index,
                child: PropertyCard(
                  project: project,
                  onTap: () => context.go('/home/project/${project.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(discoveryModeProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final loadedProjects = projectsAsync.value;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: colors.accent,
          backgroundColor: colors.surface,
          onRefresh: () async => ref.invalidate(projectsProvider),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.madeForYou,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.inkMuted,
                                  ),
                                ),
                                Text(
                                  l10n.exploreProperties,
                                  style: textTheme.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                          const _NotificationsBell(),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ModeToggle(
                        mode: mode,
                        onChanged: (m) =>
                            ref.read(discoveryModeProvider.notifier).set(m),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _SearchAndFilterRow(),
                      const SizedBox(height: AppSpacing.lg),
                      const _CategoryChips(),
                      if (loadedProjects != null &&
                          loadedProjects.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        SectionHeader(title: l10n.popularDistrictsTitle),
                        const SizedBox(height: AppSpacing.md),
                        _PopularDistricts(projects: loadedProjects),
                        const SizedBox(height: AppSpacing.xl),
                        SectionHeader(title: l10n.developersTitle),
                        const SizedBox(height: AppSpacing.md),
                        _DevelopersRail(projects: loadedProjects),
                      ],
                      if (mode == DiscoveryMode.rent) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const _OwnerListingsRail(),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      PromoBanner(
                        title: l10n.promoBannerTitle,
                        subtitle: l10n.promoBannerSubtitle,
                        actionLabel: l10n.promoBannerAction,
                        icon: Icons.apartment,
                        onAction: () => ref
                            .read(discoveryFiltersProvider.notifier)
                            .setCategory(DiscoveryCategory.newBuilds),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SectionHeader(title: l10n.recommendForYou),
                    ],
                  ),
                ),
              ),
              ..._projectGridSlivers(context, projectsAsync),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 120),
                sliver: SliverToBoxAdapter(
                  child: _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(
                            child: AppLoadingIndicator(size: 24, strokeWidth: 2.5),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Owner listings nearby" rail shown in Rent mode alongside primary
/// developer inventory — surfaces approved secondary rentals (Konseptsiya
/// §5) without ever mixing them into the sale/"Купить" feed.
class _OwnerListingsRail extends ConsumerWidget {
  const _OwnerListingsRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final listingsAsync = ref.watch(
      approvedRentalListingsProvider(const RentalListingFilter()),
    );
    final listings = listingsAsync.value ?? const [];
    if (listings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.ownerListingsSectionTitle),
        const SizedBox(height: AppSpacing.md),
        HorizontalScrollRail(
          height: 240,
          itemCount: listings.length,
          itemBuilder: (context, index) => SizedBox(
            width: 220,
            child: RentalListingCard(
              listing: listings[index],
              onTap: () => showRentalListingDetails(context, listings[index]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Notifications bell with unread badge.
class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.surface,
            child: Icon(Icons.notifications_none, color: colors.ink),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: colors.danger,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final DiscoveryMode mode;
  final ValueChanged<DiscoveryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final items = {
      DiscoveryMode.buy: l10n.modeBuy,
      DiscoveryMode.rent: l10n.modeRent,
      DiscoveryMode.newBuilds: l10n.modeNewBuilds,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          for (final entry in items.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md - 2,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: mode == entry.key
                        ? colors.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    entry.value,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: mode == entry.key
                          ? colors.onAccent
                          : colors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Search field + filter icon button, sharing state with [FilterSheet] via
/// [discoveryFiltersProvider]. Search input is debounced so typing doesn't
/// fire a request per keystroke.
class _SearchAndFilterRow extends ConsumerStatefulWidget {
  const _SearchAndFilterRow();

  @override
  ConsumerState<_SearchAndFilterRow> createState() =>
      _SearchAndFilterRowState();
}

class _SearchAndFilterRowState extends ConsumerState<_SearchAndFilterRow> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(discoveryFiltersProvider).searchText,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(discoveryFiltersProvider.notifier).setSearchText(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final hasSheetFilters = ref.watch(
      discoveryFiltersProvider.select((f) => f.hasSheetFilters),
    );

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: Icon(Icons.search, color: colors.inkMuted),
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                borderSide: BorderSide(
                  color: colors.accent.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Material(
          color: hasSheetFilters ? colors.accent : colors.surface,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: () => showFilterSheet(context),
            icon: Icon(
              Icons.tune,
              color: hasSheetFilters ? colors.onAccent : colors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(
      discoveryFiltersProvider.select((f) => f.category),
    );
    final categories = {
      DiscoveryCategory.all: l10n.categoryAll,
      DiscoveryCategory.apartments: l10n.categoryApartments,
      DiscoveryCategory.offices: l10n.categoryOffices,
      DiscoveryCategory.streetRetail: l10n.projectTypeStreetRetail,
      DiscoveryCategory.newBuilds: l10n.modeNewBuilds,
    };
    return HorizontalScrollRow(
      height: 44,
      children: [
        for (final entry in categories.entries)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppChip(
              label: entry.value,
              selected: entry.key == selected,
              onTap: () => ref
                  .read(discoveryFiltersProvider.notifier)
                  .setCategory(entry.key),
            ),
          ),
      ],
    );
  }
}

/// Real Tashkent developers to surface first in the home-screen rail.
const _featuredDeveloperIds = {'dev-hills-group', 'dev-murad', 'dev-imarat'};

/// Unique developers derived from the loaded catalogue — featured builders
/// (Hills Group, Murad Buildings, Imarat Development) are pinned to the front.
class _DevelopersRail extends StatelessWidget {
  const _DevelopersRail({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final byDeveloper = <String, ({Developer dev, List<Project> items})>{};

    for (final project in projects) {
      final dev = project.developer;
      if (dev == null) continue;
      final bucket = byDeveloper[dev.id];
      if (bucket == null) {
        byDeveloper[dev.id] = (dev: dev, items: [project]);
      } else {
        byDeveloper[dev.id] = (dev: dev, items: [...bucket.items, project]);
      }
    }

    final entries = byDeveloper.values.toList()
      ..sort((a, b) {
        final aFeatured = _featuredDeveloperIds.contains(a.dev.id);
        final bFeatured = _featuredDeveloperIds.contains(b.dev.id);
        if (aFeatured != bFeatured) return aFeatured ? -1 : 1;
        return b.items.length.compareTo(a.items.length);
      });

    final top = entries.take(10).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return HorizontalScrollRail(
      height: 148,
      itemCount: top.length,
      itemBuilder: (context, index) {
        final entry = top[index];
        final dev = entry.dev;
        final count = entry.items.length;
        return FadeSlideIn(
          index: index,
          child: DeveloperCard(
            name: dev.name,
            rating: dev.rating,
            projectsCount: count,
            projectsLabel: l10n.developerProjectsCount(count),
            onTap: () => context.go('/home/developer/${dev.id}'),
          ),
        );
      },
    );
  }
}

/// Districts covered by the currently loaded [projects], ranked by listing
/// count — tapping one narrows the discovery filters to that district.
class _PopularDistricts extends ConsumerWidget {
  const _PopularDistricts({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(discoveryFiltersProvider);
    final selectedDistrict = filters.district;
    final byDistrict = <String, List<Project>>{};
    for (final p in projects) {
      byDistrict.putIfAbsent(p.district, () => []).add(p);
    }
    final entries = byDistrict.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final top = entries.take(8).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return HorizontalScrollRail(
      height: 108,
      itemCount: top.length,
      itemBuilder: (context, index) {
        final entry = top[index];
        final urls = entry.value.expand((p) => p.gallery).map((m) => m.url);
        final thumbUrl = urls.isEmpty ? null : urls.first;
        final isSelected = selectedDistrict == entry.key;
        return FadeSlideIn(
          index: index,
          child: DistrictCard(
            name: entry.key,
            count: l10n.districtListingsCount(entry.value.length),
            imageUrl: thumbUrl,
            selected: isSelected,
            onTap: () => ref
                .read(discoveryFiltersProvider.notifier)
                .applySheetFilters(
                  district: isSelected ? null : entry.key,
                  status: filters.status,
                  minPrice: filters.minPrice,
                  maxPrice: filters.maxPrice,
                ),
          ),
        );
      },
    );
  }
}
