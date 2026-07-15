// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PhotoReport _$PhotoReportFromJson(Map<String, dynamic> json) => _PhotoReport(
  id: json['id'] as String,
  projectId: json['projectId'] as String,
  buildingId: json['buildingId'] as String?,
  photoUrl: json['photoUrl'] as String,
  takenAt: DateTime.parse(json['takenAt'] as String),
  takenAtIsManual: json['takenAtIsManual'] as bool? ?? false,
  progressPercent: (json['progressPercent'] as num?)?.toInt(),
  uploadedBy: json['uploadedBy'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$PhotoReportToJson(_PhotoReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'buildingId': instance.buildingId,
      'photoUrl': instance.photoUrl,
      'takenAt': instance.takenAt.toIso8601String(),
      'takenAtIsManual': instance.takenAtIsManual,
      'progressPercent': instance.progressPercent,
      'uploadedBy': instance.uploadedBy,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
