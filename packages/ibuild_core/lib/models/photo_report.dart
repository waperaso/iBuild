import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_report.freezed.dart';
part 'photo_report.g.dart';

/// One dated construction-progress photo (plan section 11 / "тrust system")
/// — see `server`'s `GET /v1/projects/:id/photo-reports` for the matching
/// backend contract. The B2C construction-progress timeline groups these by
/// month and overlays [progressPercent] where the uploader logged one.
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
