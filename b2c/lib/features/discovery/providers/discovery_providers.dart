import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../data/projects_repository.dart';
import 'filters_providers.dart';

/// Selected Buy / Rent / New-builds toggle on the discovery + map screens.
class DiscoveryModeController extends Notifier<DiscoveryMode> {
  @override
  DiscoveryMode build() => DiscoveryMode.buy;

  void set(DiscoveryMode mode) => state = mode;
}

final discoveryModeProvider =
    NotifierProvider<DiscoveryModeController, DiscoveryMode>(
      DiscoveryModeController.new,
    );

/// Paginated projects list, filtered by the active discovery mode and the
/// search/filter-sheet/category state — backed by [ProjectsRepository] (live
/// API or mock fallback). Re-fetches page 1 whenever the mode or filters
/// change; [loadMore] appends subsequent pages for infinite scroll.
class ProjectsController extends AsyncNotifier<List<Project>> {
  int _page = 1;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  ProjectType? _typeFor(DiscoveryCategory category) => switch (category) {
    DiscoveryCategory.apartments => ProjectType.residentialComplex,
    DiscoveryCategory.offices => ProjectType.businessCentre,
    DiscoveryCategory.streetRetail => ProjectType.streetRetail,
    DiscoveryCategory.all || DiscoveryCategory.newBuilds => null,
  };

  ProjectFilter _filterFor(int page) {
    final mode = ref.read(discoveryModeProvider);
    final filters = ref.read(discoveryFiltersProvider);
    return ProjectFilter(
      mode: mode,
      search: filters.searchText.isEmpty ? null : filters.searchText,
      district: filters.district,
      status: filters.status,
      type: _typeFor(filters.category),
      minPrice: filters.minPrice,
      maxPrice: filters.maxPrice,
      rooms: filters.rooms,
      areaMin: filters.areaMin,
      offplanOnly: filters.offplanOnly,
      page: page,
    );
  }

  @override
  Future<List<Project>> build() async {
    ref.watch(discoveryModeProvider);
    ref.watch(discoveryFiltersProvider);
    _page = 1;
    _hasMore = true;
    final repo = ref.watch(projectsRepositoryProvider);
    final items = await repo.fetchProjects(_filterFor(1));
    _hasMore = items.length >= kProjectsPageSize;
    return items;
  }

  Future<void> loadMore() async {
    if (_hasMore == false) return;
    final current = state.value;
    if (current == null) return;
    final nextPage = _page + 1;
    final repo = ref.read(projectsRepositoryProvider);
    final items = await repo.fetchProjects(_filterFor(nextPage));
    if (items.isEmpty) {
      _hasMore = false;
      return;
    }
    _page = nextPage;
    _hasMore = items.length >= kProjectsPageSize;
    state = AsyncData([...current, ...items]);
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsController, List<Project>>(
      ProjectsController.new,
    );

/// Map pins reuse the discovery catalogue so switching Home↔Map does not
/// fire a second identical `GET /projects`. Home `loadMore` can grow the
/// list while Map is off-tab; Map only watches while its tab is active.
final mapProjectsProvider = Provider<AsyncValue<List<Project>>>((ref) {
  return ref.watch(projectsProvider);
});

/// Looks up a single project by id via [ProjectsRepository] (live API or
/// mock fallback).
final projectByIdProvider = FutureProvider.family<Project, String>(
  (ref, id) => ref.watch(projectsRepositoryProvider).fetchProject(id),
);
