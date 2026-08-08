import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../models/mock_data.dart';

/// Default page size for `GET /v1/projects`, matching the dev server's
/// default (see `server/bin/server.dart`).
const int kProjectsPageSize = 20;

/// Query params for [ProjectsRepository.fetchProjects].
/// Price range is applied client-side after fetch.
class ProjectFilter {
  const ProjectFilter({
    this.mode,
    this.search,
    this.district,
    this.status,
    this.type,
    this.minPrice,
    this.maxPrice,
    this.rooms = const {},
    this.areaMin,
    this.offplanOnly = false,
    this.page = 1,
    this.limit = kProjectsPageSize,
  });

  final DiscoveryMode? mode;
  final String? search;
  final String? district;
  final ProjectStatus? status;
  final ProjectType? type;
  final double? minPrice;
  final double? maxPrice;
  final Set<int> rooms;
  final double? areaMin;
  final bool offplanOnly;
  final int page;
  final int limit;

  ProjectFilter copyWithPage(int page) => ProjectFilter(
    mode: mode,
    search: search,
    district: district,
    status: status,
    type: type,
    minPrice: minPrice,
    maxPrice: maxPrice,
    rooms: rooms,
    areaMin: areaMin,
    offplanOnly: offplanOnly,
    page: page,
    limit: limit,
  );
}

/// Project list/detail fetch (live API or [MockData] when [Env.useMockData]).
class ProjectsRepository {
  ProjectsRepository(this._dio);

  final Dio _dio;

  /// Fetches one page of projects matching [filter]. The list length equals
  /// [ProjectFilter.limit] when there is at least one more page, so callers
  /// can infer "has more" without needing the response envelope's `meta`.
  Future<List<Project>> fetchProjects(ProjectFilter filter) async {
    if (Env.useMockData) {
      var items = List<Project>.of(MockData.projects);
      items = _applyModeAndCategory(items, filter);
      items = _applyDistrictAndSearch(items, filter);
      items = _applyPriceRange(items, filter);
      final start = (filter.page - 1) * filter.limit;
      if (start >= items.length) return const [];
      final end = (start + filter.limit).clamp(0, items.length);
      return items.sublist(start, end);
    }

    final response = await _dio.get<List<dynamic>>(
      '/projects',
      queryParameters: {
        if (filter.mode != null) 'mode': _modeParam(filter.mode!),
        if (filter.search != null && filter.search!.isNotEmpty)
          'search': filter.search,
        if (filter.district != null && filter.district!.isNotEmpty)
          'district': filter.district,
        if (filter.status != null) 'status': _statusParam(filter.status!),
        if (filter.type != null) 'type': _typeParam(filter.type!),
        if (filter.minPrice != null) 'priceMin': filter.minPrice,
        if (filter.maxPrice != null) 'priceMax': filter.maxPrice,
        if (filter.rooms.isNotEmpty) 'rooms': filter.rooms.join(','),
        if (filter.areaMin != null) 'areaMin': filter.areaMin,
        if (filter.offplanOnly) 'offplan': 'true',
        'page': filter.page,
        'limit': filter.limit,
      },
    );
    return (response.data ?? const [])
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Project> fetchProject(String id) async {
    if (Env.useMockData) return MockData.projectById(id);
    final response = await _dio.get<Map<String, dynamic>>('/projects/$id');
    return Project.fromJson(response.data!);
  }

  List<Project> _applyModeAndCategory(
    List<Project> items,
    ProjectFilter filter,
  ) {
    var result = items;
    switch (filter.mode) {
      case DiscoveryMode.buy:
        // Konseptsiya §5: "Купить" = первичка от застройщика, в любом
        // сегменте (ЖК/БЦ/стрит-ритейл) — не только жилые комплексы.
        result = result
            .where((p) => p.priceMin != null || p.priceMax != null)
            .toList();
      case DiscoveryMode.rent:
        // "Снять" = первичка И вторичка, в любом сегменте — раньше здесь
        // ошибочно оставались только бизнес-центры.
        result = result
            .where((p) => p.rentMin != null || p.rentMax != null)
            .toList();
      case DiscoveryMode.newBuilds:
        result = result
            .where((p) => p.status == ProjectStatus.underConstruction)
            .toList();
      case null:
        break;
    }
    if (filter.type != null) {
      result = result.where((p) => p.type == filter.type).toList();
    }
    if (filter.status != null) {
      result = result.where((p) => p.status == filter.status).toList();
    }
    return result;
  }

  List<Project> _applyDistrictAndSearch(
    List<Project> items,
    ProjectFilter filter,
  ) {
    var result = items;
    if (filter.district != null && filter.district!.isNotEmpty) {
      final d = filter.district!.toLowerCase();
      result = result.where((p) => p.district.toLowerCase() == d).toList();
    }
    if (filter.search != null && filter.search!.isNotEmpty) {
      final q = filter.search!.toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.district.toLowerCase().contains(q) ||
                p.address.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  /// Keeps projects whose sale (or rent, for rent-only listings) price
  /// overlaps the requested [ProjectFilter.minPrice]/[ProjectFilter.maxPrice]
  /// range. Projects with no price data at all are always kept.
  List<Project> _applyPriceRange(List<Project> items, ProjectFilter filter) {
    if (filter.minPrice == null && filter.maxPrice == null) return items;
    return items.where((p) {
      final effectiveMin = p.priceMin ?? p.rentMin;
      final effectiveMax = p.priceMax ?? p.rentMax;
      if (effectiveMin == null && effectiveMax == null) return true;
      final min = filter.minPrice;
      final max = filter.maxPrice;
      if (max != null && effectiveMin != null && effectiveMin > max) {
        return false;
      }
      if (min != null && effectiveMax != null && effectiveMax < min) {
        return false;
      }
      return true;
    }).toList();
  }

  String _modeParam(DiscoveryMode mode) => switch (mode) {
    DiscoveryMode.buy => 'buy',
    DiscoveryMode.rent => 'rent',
    DiscoveryMode.newBuilds => 'newBuilds',
  };

  String _statusParam(ProjectStatus status) => switch (status) {
    ProjectStatus.planned => 'planned',
    ProjectStatus.underConstruction => 'under_construction',
    ProjectStatus.ready => 'ready',
    ProjectStatus.handedOver => 'handed_over',
  };

  String _typeParam(ProjectType type) => switch (type) {
    ProjectType.residentialComplex => 'residential_complex',
    ProjectType.businessCentre => 'business_centre',
    ProjectType.streetRetail => 'street_retail',
    ProjectType.office => 'office',
    ProjectType.cottage => 'cottage',
  };
}

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(ref.watch(apiClientProvider));
});
