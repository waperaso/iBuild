// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaItem _$MediaItemFromJson(Map<String, dynamic> json) => _MediaItem(
  id: json['id'] as String,
  type: $enumDecode(_$MediaTypeEnumMap, json['type']),
  url: json['url'] as String,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  isCover: json['isCover'] as bool? ?? false,
);

Map<String, dynamic> _$MediaItemToJson(_MediaItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$MediaTypeEnumMap[instance.type]!,
      'url': instance.url,
      'sortOrder': instance.sortOrder,
      'isCover': instance.isCover,
    };

const _$MediaTypeEnumMap = {
  MediaType.photo: 'photo',
  MediaType.floorplan: 'floorplan',
  MediaType.render: 'render',
  MediaType.tour: 'tour',
};
