import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_report.freezed.dart';
part 'photo_report.g.dart';

/// Dated construction-progress photo, optionally with [progressPercent].
@freezed
abstract class PhotoReport with _$PhotoReport {
  const factory PhotoReport({
    required String id,
    required String projectId,
    String? buildingId,
    required String photoUrl,
    required DateTime takenAt,
    @Default(false) bool takenAtIsManual,
    int? progressPercent,
    String? uploadedBy,
    DateTime? createdAt,
  }) = _PhotoReport;

  factory PhotoReport.fromJson(Map<String, dynamic> json) =>
      _$PhotoReportFromJson(json);
}
