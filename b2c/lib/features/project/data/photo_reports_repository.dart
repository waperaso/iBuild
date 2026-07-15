import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../models/mock_data.dart';

/// Construction-progress photo reports for one project (plan section 11
/// "Trust system") — live API or mock fallback (see [ProjectsRepository] for
/// the same `Env.useMockData` seam). Backs the project page's
/// construction-progress timeline tab.
class PhotoReportsRepository {
  PhotoReportsRepository(this._dio);

  final Dio _dio;

  /// Fetches a project's photo reports, newest-first (per the frozen
  /// contract) — the timeline widget groups these by month client-side.
  Future<List<PhotoReport>> fetchForProject(String projectId) async {
    if (Env.useMockData) {
      return List.of(MockData.photoReportsByProject[projectId] ?? const []);
    }
    final response = await _dio.get<List<dynamic>>(
      '/projects/$projectId/photo-reports',
    );
    return (response.data ?? const [])
        .map((e) => PhotoReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final photoReportsRepositoryProvider = Provider<PhotoReportsRepository>((
  ref,
) {
  return PhotoReportsRepository(ref.watch(apiClientProvider));
});
