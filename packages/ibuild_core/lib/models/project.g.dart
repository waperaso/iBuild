// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Project _$ProjectFromJson(Map<String, dynamic> json) => _Project(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$ProjectTypeEnumMap, json['type']),
  status: $enumDecode(_$ProjectStatusEnumMap, json['status']),
  district: json['district'] as String,
  address: json['address'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  developer: json['developer'] == null
      ? null
      : Developer.fromJson(json['developer'] as Map<String, dynamic>),
  description: json['description'] as String?,
  amenities:
      (json['amenities'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  priceMin: (json['priceMin'] as num?)?.toDouble(),
  priceMax: (json['priceMax'] as num?)?.toDouble(),
  rentMin: (json['rentMin'] as num?)?.toDouble(),
  rentMax: (json['rentMax'] as num?)?.toDouble(),
  constructionProgress: (json['constructionProgress'] as num?)?.toInt(),
  completionDate: json['completionDate'] == null
      ? null
      : DateTime.parse(json['completionDate'] as String),
  rating: (json['rating'] as num?)?.toDouble() ?? 0,
  availableUnits: (json['availableUnits'] as num?)?.toInt() ?? 0,
  totalUnits: (json['totalUnits'] as num?)?.toInt() ?? 0,
  isFeatured: json['isFeatured'] as bool? ?? false,
  gallery:
      (json['gallery'] as List<dynamic>?)
          ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MediaItem>[],
  buildings:
      (json['buildings'] as List<dynamic>?)
          ?.map((e) => Building.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Building>[],
  offers:
      (json['offers'] as List<dynamic>?)
          ?.map((e) => Offer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Offer>[],
);

Map<String, dynamic> _$ProjectToJson(_Project instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$ProjectTypeEnumMap[instance.type]!,
  'status': _$ProjectStatusEnumMap[instance.status]!,
  'district': instance.district,
  'address': instance.address,
  'lat': instance.lat,
  'lng': instance.lng,
  'developer': instance.developer,
  'description': instance.description,
  'amenities': instance.amenities,
  'tags': instance.tags,
  'priceMin': instance.priceMin,
  'priceMax': instance.priceMax,
  'rentMin': instance.rentMin,
  'rentMax': instance.rentMax,
  'constructionProgress': instance.constructionProgress,
  'completionDate': instance.completionDate?.toIso8601String(),
  'rating': instance.rating,
  'availableUnits': instance.availableUnits,
  'totalUnits': instance.totalUnits,
  'isFeatured': instance.isFeatured,
  'gallery': instance.gallery,
  'buildings': instance.buildings,
  'offers': instance.offers,
};

const _$ProjectTypeEnumMap = {
  ProjectType.residentialComplex: 'residential_complex',
  ProjectType.businessCentre: 'business_centre',
  ProjectType.streetRetail: 'street_retail',
  ProjectType.office: 'office',
  ProjectType.cottage: 'cottage',
};

const _$ProjectStatusEnumMap = {
  ProjectStatus.planned: 'planned',
  ProjectStatus.underConstruction: 'under_construction',
  ProjectStatus.ready: 'ready',
  ProjectStatus.handedOver: 'handed_over',
};
