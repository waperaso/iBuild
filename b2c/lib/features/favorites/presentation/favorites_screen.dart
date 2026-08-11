import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive_card_grid.dart';
import '../../../core/widgets/scroll_tuning.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/saved_search.dart';
import '../../discovery/presentation/widgets/property_card.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../../discovery/providers/filters_providers.dart';
import '../providers/favorites_providers.dart';
import '../providers/saved_searches_providers.dart';

/// Favorites + Saved searches (plan section 3.8).
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final projectsAsync = ref.watch(projectsProvider);
    final favoriteIds = ref.watch(favoritesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(l10n.savedTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.navFavorites),
              Tab(text: l10n.tabSavedSearches),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () async => ref.invalidate(projectsProvider),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                scrollCacheExtent: scrollCacheExtentFor(context),
                slivers: [
                  ...projectsAsync.when(
                    loading: () => [
                      SliverPadding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
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
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        sliver: SliverToBoxAdapter(
                          child: AsyncValueView<List<Project>>(
                            value: projectsAsync,
                            onRetry: () => ref.invalidate(projectsProvider),
                            builder: (_, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                    data: (projects) {
                      final favorites = projects
                          .where(
                            (project) => favoriteIds.contains(project.id),
                          )
                          .toList();
                      if (favorites.isEmpty) {
                        return [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: EmptyState(
                                icon: Icons.favorite_border,
                                title: l10n.noFavoritesYet,
                                subtitle: l10n.favoritesEmptySubtitle,
                                actionLabel: l10n.browseListingsAction,
                                onAction: () => context.go('/home'),
                              ),
                            ),
                          ),
                        ];
                      }
                      return [
                        SliverPadding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          sliver: ResponsiveCardSliverGrid(
                            itemCount: favorites.length,
                            itemBuilder: (context, index) => PropertyCard(
                              project: favorites[index],
                              onTap: () => context.go(
                                '/home/project/${favorites[index].id}',
                              ),
                            ),
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
            const _SavedSearches(),
          ],
        ),
      ),
    );
  }
}

class _SavedSearches extends ConsumerWidget {
  const _SavedSearches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final searches = ref.watch(savedSearchesProvider);

    if (searches.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.bookmark_border,
          title: l10n.noSavedSearchesYet,
          subtitle: l10n.savedSearchesEmptySubtitle,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      scrollCacheExtent: scrollCacheExtentFor(context),
      itemCount: searches.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final search = searches[index];
        return AppCard(
          onTap: () => _apply(context, ref, search),
          child: Row(
            children: [
              Icon(Icons.bookmark_outline, color: colors.ink),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(search.label, style: textTheme.bodyLarge)),
              // Alerts require push — hide the fake toggle until FCM ships.
              Icon(
                search.notifyOnMatch
                    ? Icons.notifications_outlined
                    : Icons.notifications_off_outlined,
                size: 20,
                color: colors.inkMuted,
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: colors.inkMuted),
                onPressed: () =>
                    ref.read(savedSearchesProvider.notifier).remove(search.id),
              ),
            ],
          ),
        );
      },
    );
  }

  void _apply(BuildContext context, WidgetRef ref, SavedSearch search) {
    ref.read(discoveryModeProvider.notifier).set(search.mode);
    ref
        .read(discoveryFiltersProvider.notifier)
        .applySnapshot(
          searchText: search.searchText,
          districtLegacy: search.district,
          status: search.status,
          minPrice: search.minPrice,
          maxPrice: search.maxPrice,
        );
    context.go('/home');
  }
}
