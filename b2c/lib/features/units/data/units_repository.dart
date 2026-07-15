import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../models/mock_data.dart';

/// Fetches a single unit by id, from the live API or the bundled mock data
/// (see [ProjectsRepository] for the same mock/live seam).
class UnitsRepository {
  UnitsRepository(this._dio);

  final Dio _dio;

  Future<Unit?> fetchUnit(String id) async {
    if (Env.useMockData) {
      for (final project in MockData.projects) {
        for (final building in project.buildings) {
          for (final unit in building.units) {
            if (unit.id == id) return unit;
          }
        }
      }
      return null;
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>('/units/$id');
      return Unit.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

final unitsRepositoryProvider = Provider<UnitsRepository>((ref) {
  return UnitsRepository(ref.watch(apiClientProvider));
});
