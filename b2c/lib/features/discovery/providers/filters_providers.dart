import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

/// Category shortcut chips shown on the discovery screen (see `_CategoryChips`
/// in `discovery_screen.dart`), folded into the same filter state as the
/// search bar and filter sheet.
enum DiscoveryCategory { all, apartments, offices, streetRetail, newBuilds }

/// Immutable filter state for the discovery screen: free-text search, the
/// filter-sheet fields (district/status/price range) and the category chips.
class DiscoveryFilters {
  const DiscoveryFilters({
    this.searchText = '',
    this.district,
    this.status,
    this.minPrice,
    this.maxPrice,
    this.rooms = const {},
    this.areaMin,
    this.offplanOnly = false,
    this.category = DiscoveryCategory.all,
  });

  final String searchText;
  final String? district;
  final ProjectStatus? status;
  final double? minPrice;
  final double? maxPrice;
  final Set<int> rooms;
  final double? areaMin;
  final bool offplanOnly;
  final DiscoveryCategory category;

  /// Whether any filter-sheet field (district/status/price/rooms/area/off-plan)
  /// is set — used to badge the filter icon. Search text and category are
  /// surfaced elsewhere in the UI so they're excluded here.
  bool get hasSheetFilters =>
      district != null ||
      status != null ||
      minPrice != null ||
      maxPrice != null ||
      rooms.isNotEmpty ||
      areaMin != null ||
      offplanOnly;

  DiscoveryFilters copyWith({String? searchText, DiscoveryCategory? category}) {
    return DiscoveryFilters(
      searchText: searchText ?? this.searchText,
      district: district,
      status: status,
      minPrice: minPrice,
      maxPrice: maxPrice,
      rooms: rooms,
      areaMin: areaMin,
      offplanOnly: offplanOnly,
      category: category ?? this.category,
    );
  }

  /// Returns a copy with the filter-sheet fields replaced (nulls/empty clear
  /// the field), keeping search text and category untouched.
  DiscoveryFilters withSheetFilters({
    String? district,
    ProjectStatus? status,
    double? minPrice,
    double? maxPrice,
    Set<int> rooms = const {},
    double? areaMin,
    bool offplanOnly = false,
  }) {
    return DiscoveryFilters(
      searchText: searchText,
      district: district,
      status: status,
      minPrice: minPrice,
      maxPrice: maxPrice,
      rooms: rooms,
      areaMin: areaMin,
      offplanOnly: offplanOnly,
      category: category,
    );
  }

  /// Resets the filter-sheet fields but keeps search text and category.
  DiscoveryFilters clearSheetFilters() =>
      DiscoveryFilters(searchText: searchText, category: category);

  @override
  bool operator ==(Object other) =>
      other is DiscoveryFilters &&
      other.searchText == searchText &&
      other.district == district &&
      other.status == status &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.rooms.length == rooms.length &&
      other.rooms.containsAll(rooms) &&
      other.areaMin == areaMin &&
      other.offplanOnly == offplanOnly &&
      other.category == category;

  @override
  int get hashCode => Object.hash(
    searchText,
    district,
    status,
    minPrice,
    maxPrice,
    Object.hashAllUnordered(rooms),
    areaMin,
    offplanOnly,
    category,
  );
}

/// Search text, filter-sheet fields and the category chip, shared by the
/// search bar, `filter_sheet.dart` and `_CategoryChips` on the discovery
/// screen. `projectsProvider` in `discovery_providers.dart` watches this
/// alongside `discoveryModeProvider` to build the query it sends through
/// [ProjectsRepository].
class DiscoveryFiltersController extends Notifier<DiscoveryFilters> {
  @override
  DiscoveryFilters build() => const DiscoveryFilters();

  void setSearchText(String text) => state = state.copyWith(searchText: text);

  void setCategory(DiscoveryCategory category) =>
      state = state.copyWith(category: category);

  void applySheetFilters({
    String? district,
    ProjectStatus? status,
    double? minPrice,
    double? maxPrice,
    Set<int> rooms = const {},
    double? areaMin,
    bool offplanOnly = false,
  }) {
    state = state.withSheetFilters(
      district: district,
      status: status,
      minPrice: minPrice,
      maxPrice: maxPrice,
      rooms: rooms,
      areaMin: areaMin,
      offplanOnly: offplanOnly,
    );
  }

  void clearSheetFilters() => state = state.clearSheetFilters();

  /// Restores a full snapshot (search text + sheet fields) taken earlier,
  /// e.g. from a [SavedSearch] — keeps the category chip untouched since
  /// saved searches don't track it.
  void applySnapshot({
    required String searchText,
    String? district,
    ProjectStatus? status,
    double? minPrice,
    double? maxPrice,
  }) {
    state = DiscoveryFilters(
      searchText: searchText,
      district: district,
      status: status,
      minPrice: minPrice,
      maxPrice: maxPrice,
      category: state.category,
    );
  }
}

final discoveryFiltersProvider =
    NotifierProvider<DiscoveryFiltersController, DiscoveryFilters>(
      DiscoveryFiltersController.new,
    );
