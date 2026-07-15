import 'package:freezed_annotation/freezed_annotation.dart';

import 'unit.dart';

part 'building.freezed.dart';
part 'building.g.dart';

@freezed
abstract class Building with _$Building {
  const factory Building({
    required String id,
    required String projectId,
    required String name,
    required int floors,
    int? constructionProgress,
    DateTime? completionDate,
    @Default(<Unit>[]) List<Unit> units,
  }) = _Building;

  factory Building.fromJson(Map<String, dynamic> json) =>
      _$BuildingFromJson(json);
}
