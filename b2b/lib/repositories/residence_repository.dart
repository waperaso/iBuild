import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/admin/admin_api.dart';
import '../models/admin_project.dart';
import '../models/developer_profile.dart';

/// Repository for the residence-admin (ЖК owner) surface. Sits between the raw
/// [AdminApi] transport and the presentation layer, mapping loosely-typed JSON
/// into domain models so screens depend on models instead of `Map` keys.
///
/// This is the first slice of the repository layer the audit called for; other
/// surfaces (platform governance, support) can follow the same pattern.
class ResidenceRepository {
  ResidenceRepository(this._api);

  final AdminApi _api;

  /// The signed-in admin's own projects/residences.
  Future<List<AdminProject>> myProjects() async {
    final rows = await _api.myProjects();
    return rows.map(AdminProject.fromJson).toList(growable: false);
  }

  /// The admin's org/developer profile, or `null` if none exists yet.
  Future<DeveloperProfile?> myDeveloper() async {
    final json = await _api.myDeveloper();
    return json == null ? null : DeveloperProfile.fromJson(json);
  }

  /// Creates a new residence and returns it as a model.
  Future<AdminProject> createProject({
    required String name,
    required String district,
    required String address,
    required double lat,
    required double lng,
    String type = 'residential_complex',
    String status = 'under_construction',
    String description = 'Created from B2B admin',
  }) async {
    final json = await _api.createProject({
      'name': name,
      'district': district,
      'address': address,
      'lat': lat,
      'lng': lng,
      'type': type,
      'status': status,
      'description': description,
    });
    return AdminProject.fromJson(json);
  }
}

final residenceRepositoryProvider = Provider<ResidenceRepository>(
  (ref) => ResidenceRepository(ref.watch(adminApiProvider)),
);
