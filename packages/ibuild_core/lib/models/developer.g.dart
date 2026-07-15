// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'developer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Developer _$DeveloperFromJson(Map<String, dynamic> json) => _Developer(
  id: json['id'] as String,
  name: json['name'] as String,
  logoUrl: json['logoUrl'] as String?,
  rating: (json['rating'] as num?)?.toDouble() ?? 0,
  projectsCount: (json['projectsCount'] as num?)?.toInt() ?? 0,
  phone: json['phone'] as String?,
  agentName: json['agentName'] as String?,
  agentPhone: json['agentPhone'] as String?,
  agentAvatarUrl: json['agentAvatarUrl'] as String?,
);

Map<String, dynamic> _$DeveloperToJson(_Developer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logoUrl': instance.logoUrl,
      'rating': instance.rating,
      'projectsCount': instance.projectsCount,
      'phone': instance.phone,
      'agentName': instance.agentName,
      'agentPhone': instance.agentPhone,
      'agentAvatarUrl': instance.agentAvatarUrl,
    };
