import 'package:freezed_annotation/freezed_annotation.dart';

import 'building.dart';
import 'developer.dart';
import 'enums.dart';
import 'media.dart';
import 'offer.dart';

part 'project.freezed.dart';
part 'project.g.dart';

/// A residential complex or business centre. One unified shape serves ready
/// sale, off-plan new builds and office rent (plan section 7.1).
@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    required ProjectType type,
    required ProjectStatus status,
    required String district,
    required String address,
    required double lat,
    required double lng,
    Developer? developer,
    String? description,
    @Default(<String>[]) List<String> amenities,
    @Default(<String>[]) List<String> tags,
    double? priceMin,
    double? priceMax,
    double? rentMin,
    double? rentMax,
    int? constructionProgress,
    DateTime? completionDate,
    @Default(0) double rating,
    @Default(0) int availableUnits,
    @Default(0) int totalUnits,
    @Default(false) bool isFeatured,
    @Default(<MediaItem>[]) List<MediaItem> gallery,
    @Default(<Building>[]) List<Building> buildings,
    @Default(<Offer>[]) List<Offer> offers,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}
