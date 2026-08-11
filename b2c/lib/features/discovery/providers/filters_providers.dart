import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

/// Category shortcut chips shown on the discovery screen (see `_CategoryChips`
/// in `discovery_screen.dart`), folded into the same filter state as the
/// search bar and filter sheet.
enum DiscoveryCategory { all, apartments, offices, streetRetail, newBuilds }

/// Immutable filter state for the discovery screen: free-text search, the
/// filter-sheet fields (districts/status/price range) and the category chips.
class DiscoveryFilters {
  const DiscoveryFilters({
    this.searchText = '',
    this.districts = const {},
    this.status,
    this.minPrice,
    this.maxPrice,
    this.rooms = const {},
    this.areaMin,
    this.offplanOnly = false,
    this.category = DiscoveryCategory.all,
  });

  final String searchText;
  final Set<String> districts;
  final ProjectStatus? status;
  final double? minPrice;
  final double? maxPrice;
  final Set<int> rooms;
  final double? areaMin;
  final bool offplanOnly;
  final DiscoveryCategory category;

  /// Whether any filter-sheet field is set — badges the filter icon and shows
  /// the active-filters bar. Search text and category are surfaced elsewhere.
  bool get hasSheetFilters =>
      districts.isNotEmpty ||
      status != null ||
      minPrice != null ||
      maxPrice != null ||
      rooms.isNotEmpty ||
      areaMin != null ||
      offplanOnly;

  /// Count of active sheet filters (for summary labels).
  int get activeSheetFilterCount {
    var n = districts.length;
    if (status != null) n++;
    if (minPrice != null || maxPrice != null) n++;
    if (rooms.isNotEmpty) n++;
    if (areaMin != null) n++;
    if (offplanOnly) n++;
    return n;
  }

  DiscoveryFilters copyWith({String? searchText, DiscoveryCategory? category}) {
    return DiscoveryFilters(
      searchText: searchText ?? this.searchText,
      districts: districts,
      status: status,
      minPrice: minPrice,
      maxPrice: maxPrice,
      rooms: rooms,
      areaMin: areaMin,
      offplanOnly: offplanOnly,
      category: category ?? this.category,
    );
  }

  /// Returns a copy with the filter-sheet fields replaced, keeping search text
  /// and category untouched.
  DiscoveryFilters withSheetFilters({
    Set<String> districts = const {},
    ProjectStatus? status,
    double? minPrice,
    double? maxPrice,
    Set<int> rooms = const {},
    double? areaMin,
    bool offplanOnly = false,
  }) {
    return DiscoveryFilters(
      searchText: searchText,
      districts: districts,
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
      other.districts.length == districts.length &&
      other.districts.containsAll(districts) &&
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
    Object.hashAllUnordered(districts),
    status,
    minPrice,
    maxPrice,
    Object.hashAllUnordered(rooms),
    areaMin,
    offplanOnly,
    category,
  );
}

/// Discovery search/filter/category state for [ProjectsRepository] queries.
class DiscoveryFiltersController extends Notifier<DiscoveryFilters> {
  @override
  DiscoveryFilters build() => const DiscoveryFilters();

  void setSearchText(String text) => state = state.copyWith(searchText: text);

  void setCategory(DiscoveryCategory category) =>
      state = state.copyWith(category: category);

  void applySheetFilters({
    Set<String> districts = const {},
    ProjectStatus? status,
    double? minPrice,
    double? maxPrice,
    Set<int> rooms = const {},
    double? areaMin,
    bool offplanOnly = false,
  }) {
    state = state.withSheetFilters(
      districts: districts,
      status: status,
      minPrice: minPrice,
      maxPrice: maxPrice,
      rooms: rooms,
      areaMin: areaMin,
      offplanOnly: offplanOnly,
    );
  }

  void toggleDistrict(String district) {
    final next = {...state.districts};
    if (!next.remove(district)) next.add(district);
    state = state.withSheetFilters(
      districts: next,
      status: state.status,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
      rooms: state.rooms,
      areaMin: state.areaMin,
      offplanOnly: state.offplanOnly,
    );
  }

  void clearSheetFilters() => state = state.clearSheetFilters();

  /// Restores a full snapshot (search text + sheet fields) taken earlier,
  /// e.g. from a [SavedSearch] — keeps the category chip untouched since
  /// saved searches don't track it.
  void applySnapshot({
    required String searchText,
    Set<String> districts = const {},
    String? districtLegacy,
    ProjectStatus? status,
    double? minPrice,
    double? maxPrice,
  }) {
    final resolvedDistricts = districts.isNotEmpty
        ? districts
        : (districtLegacy == null || districtLegacy.isEmpty)
        ? const <String>{}
        : districtLegacy.split(',').map((d) => d.trim()).where((d) => d.isNotEmpty).toSet();
    state = DiscoveryFilters(
      searchText: searchText,
      districts: resolvedDistricts,
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
