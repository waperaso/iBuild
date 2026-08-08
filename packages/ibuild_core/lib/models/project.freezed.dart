// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Project {

 String get id; String get name; ProjectType get type; ProjectStatus get status; String get district; String get address; double get lat; double get lng; Developer? get developer; String? get description; List<String> get amenities; List<String> get tags; double? get priceMin; double? get priceMax; double? get rentMin; double? get rentMax; int? get constructionProgress;/// Progress the developer's published schedule promises for today. Shown
/// next to [constructionProgress] so a buyer sees promise against fact
/// instead of a single unverifiable number.
 int? get plannedProgress; DateTime? get completionDate; double get rating; int get availableUnits; int get totalUnits; bool get isFeatured; List<MediaItem> get gallery; List<Building> get buildings; List<Offer> get offers;
/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectCopyWith<Project> get copyWith => _$ProjectCopyWithImpl<Project>(this as Project, _$identity);

  /// Serializes this Project to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Project&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.district, district) || other.district == district)&&(identical(other.address, address) || other.address == address)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.developer, developer) || other.developer == developer)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.amenities, amenities)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.priceMin, priceMin) || other.priceMin == priceMin)&&(identical(other.priceMax, priceMax) || other.priceMax == priceMax)&&(identical(other.rentMin, rentMin) || other.rentMin == rentMin)&&(identical(other.rentMax, rentMax) || other.rentMax == rentMax)&&(identical(other.constructionProgress, constructionProgress) || other.constructionProgress == constructionProgress)&&(identical(other.plannedProgress, plannedProgress) || other.plannedProgress == plannedProgress)&&(identical(other.completionDate, completionDate) || other.completionDate == completionDate)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.availableUnits, availableUnits) || other.availableUnits == availableUnits)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&const DeepCollectionEquality().equals(other.gallery, gallery)&&const DeepCollectionEquality().equals(other.buildings, buildings)&&const DeepCollectionEquality().equals(other.offers, offers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,type,status,district,address,lat,lng,developer,description,const DeepCollectionEquality().hash(amenities),const DeepCollectionEquality().hash(tags),priceMin,priceMax,rentMin,rentMax,constructionProgress,plannedProgress,completionDate,rating,availableUnits,totalUnits,isFeatured,const DeepCollectionEquality().hash(gallery),const DeepCollectionEquality().hash(buildings),const DeepCollectionEquality().hash(offers)]);

@override
String toString() {
  return 'Project(id: $id, name: $name, type: $type, status: $status, district: $district, address: $address, lat: $lat, lng: $lng, developer: $developer, description: $description, amenities: $amenities, tags: $tags, priceMin: $priceMin, priceMax: $priceMax, rentMin: $rentMin, rentMax: $rentMax, constructionProgress: $constructionProgress, plannedProgress: $plannedProgress, completionDate: $completionDate, rating: $rating, availableUnits: $availableUnits, totalUnits: $totalUnits, isFeatured: $isFeatured, gallery: $gallery, buildings: $buildings, offers: $offers)';
}


}

/// @nodoc
abstract mixin class $ProjectCopyWith<$Res>  {
  factory $ProjectCopyWith(Project value, $Res Function(Project) _then) = _$ProjectCopyWithImpl;
@useResult
$Res call({
 String id, String name, ProjectType type, ProjectStatus status, String district, String address, double lat, double lng, Developer? developer, String? description, List<String> amenities, List<String> tags, double? priceMin, double? priceMax, double? rentMin, double? rentMax, int? constructionProgress, int? plannedProgress, DateTime? completionDate, double rating, int availableUnits, int totalUnits, bool isFeatured, List<MediaItem> gallery, List<Building> buildings, List<Offer> offers
});


$DeveloperCopyWith<$Res>? get developer;

}
/// @nodoc
class _$ProjectCopyWithImpl<$Res>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._self, this._then);

  final Project _self;
  final $Res Function(Project) _then;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? status = null,Object? district = null,Object? address = null,Object? lat = null,Object? lng = null,Object? developer = freezed,Object? description = freezed,Object? amenities = null,Object? tags = null,Object? priceMin = freezed,Object? priceMax = freezed,Object? rentMin = freezed,Object? rentMax = freezed,Object? constructionProgress = freezed,Object? plannedProgress = freezed,Object? completionDate = freezed,Object? rating = null,Object? availableUnits = null,Object? totalUnits = null,Object? isFeatured = null,Object? gallery = null,Object? buildings = null,Object? offers = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProjectType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProjectStatus,district: null == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,developer: freezed == developer ? _self.developer : developer // ignore: cast_nullable_to_non_nullable
as Developer?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,amenities: null == amenities ? _self.amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,priceMin: freezed == priceMin ? _self.priceMin : priceMin // ignore: cast_nullable_to_non_nullable
as double?,priceMax: freezed == priceMax ? _self.priceMax : priceMax // ignore: cast_nullable_to_non_nullable
as double?,rentMin: freezed == rentMin ? _self.rentMin : rentMin // ignore: cast_nullable_to_non_nullable
as double?,rentMax: freezed == rentMax ? _self.rentMax : rentMax // ignore: cast_nullable_to_non_nullable
as double?,constructionProgress: freezed == constructionProgress ? _self.constructionProgress : constructionProgress // ignore: cast_nullable_to_non_nullable
as int?,plannedProgress: freezed == plannedProgress ? _self.plannedProgress : plannedProgress // ignore: cast_nullable_to_non_nullable
as int?,completionDate: freezed == completionDate ? _self.completionDate : completionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,availableUnits: null == availableUnits ? _self.availableUnits : availableUnits // ignore: cast_nullable_to_non_nullable
as int,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,gallery: null == gallery ? _self.gallery : gallery // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,buildings: null == buildings ? _self.buildings : buildings // ignore: cast_nullable_to_non_nullable
as List<Building>,offers: null == offers ? _self.offers : offers // ignore: cast_nullable_to_non_nullable
as List<Offer>,
  ));
}
/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeveloperCopyWith<$Res>? get developer {
    if (_self.developer == null) {
    return null;
  }

  return $DeveloperCopyWith<$Res>(_self.developer!, (value) {
    return _then(_self.copyWith(developer: value));
  });
}
}


/// Adds pattern-matching-related methods to [Project].
extension ProjectPatterns on Project {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Project value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Project value)  $default,){
final _that = this;
switch (_that) {
case _Project():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Project value)?  $default,){
final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  ProjectType type,  ProjectStatus status,  String district,  String address,  double lat,  double lng,  Developer? developer,  String? description,  List<String> amenities,  List<String> tags,  double? priceMin,  double? priceMax,  double? rentMin,  double? rentMax,  int? constructionProgress,  int? plannedProgress,  DateTime? completionDate,  double rating,  int availableUnits,  int totalUnits,  bool isFeatured,  List<MediaItem> gallery,  List<Building> buildings,  List<Offer> offers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.status,_that.district,_that.address,_that.lat,_that.lng,_that.developer,_that.description,_that.amenities,_that.tags,_that.priceMin,_that.priceMax,_that.rentMin,_that.rentMax,_that.constructionProgress,_that.plannedProgress,_that.completionDate,_that.rating,_that.availableUnits,_that.totalUnits,_that.isFeatured,_that.gallery,_that.buildings,_that.offers);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  ProjectType type,  ProjectStatus status,  String district,  String address,  double lat,  double lng,  Developer? developer,  String? description,  List<String> amenities,  List<String> tags,  double? priceMin,  double? priceMax,  double? rentMin,  double? rentMax,  int? constructionProgress,  int? plannedProgress,  DateTime? completionDate,  double rating,  int availableUnits,  int totalUnits,  bool isFeatured,  List<MediaItem> gallery,  List<Building> buildings,  List<Offer> offers)  $default,) {final _that = this;
switch (_that) {
case _Project():
return $default(_that.id,_that.name,_that.type,_that.status,_that.district,_that.address,_that.lat,_that.lng,_that.developer,_that.description,_that.amenities,_that.tags,_that.priceMin,_that.priceMax,_that.rentMin,_that.rentMax,_that.constructionProgress,_that.plannedProgress,_that.completionDate,_that.rating,_that.availableUnits,_that.totalUnits,_that.isFeatured,_that.gallery,_that.buildings,_that.offers);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  ProjectType type,  ProjectStatus status,  String district,  String address,  double lat,  double lng,  Developer? developer,  String? description,  List<String> amenities,  List<String> tags,  double? priceMin,  double? priceMax,  double? rentMin,  double? rentMax,  int? constructionProgress,  int? plannedProgress,  DateTime? completionDate,  double rating,  int availableUnits,  int totalUnits,  bool isFeatured,  List<MediaItem> gallery,  List<Building> buildings,  List<Offer> offers)?  $default,) {final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.status,_that.district,_that.address,_that.lat,_that.lng,_that.developer,_that.description,_that.amenities,_that.tags,_that.priceMin,_that.priceMax,_that.rentMin,_that.rentMax,_that.constructionProgress,_that.plannedProgress,_that.completionDate,_that.rating,_that.availableUnits,_that.totalUnits,_that.isFeatured,_that.gallery,_that.buildings,_that.offers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Project implements Project {
  const _Project({required this.id, required this.name, required this.type, required this.status, required this.district, required this.address, required this.lat, required this.lng, this.developer, this.description, final  List<String> amenities = const <String>[], final  List<String> tags = const <String>[], this.priceMin, this.priceMax, this.rentMin, this.rentMax, this.constructionProgress, this.plannedProgress, this.completionDate, this.rating = 0, this.availableUnits = 0, this.totalUnits = 0, this.isFeatured = false, final  List<MediaItem> gallery = const <MediaItem>[], final  List<Building> buildings = const <Building>[], final  List<Offer> offers = const <Offer>[]}): _amenities = amenities,_tags = tags,_gallery = gallery,_buildings = buildings,_offers = offers;
  factory _Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);

@override final  String id;
@override final  String name;
@override final  ProjectType type;
@override final  ProjectStatus status;
@override final  String district;
@override final  String address;
@override final  double lat;
@override final  double lng;
@override final  Developer? developer;
@override final  String? description;
 final  List<String> _amenities;
@override@JsonKey() List<String> get amenities {
  if (_amenities is EqualUnmodifiableListView) return _amenities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_amenities);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  double? priceMin;
@override final  double? priceMax;
@override final  double? rentMin;
@override final  double? rentMax;
@override final  int? constructionProgress;
/// Progress the developer's published schedule promises for today. Shown
/// next to [constructionProgress] so a buyer sees promise against fact
/// instead of a single unverifiable number.
@override final  int? plannedProgress;
@override final  DateTime? completionDate;
@override@JsonKey() final  double rating;
@override@JsonKey() final  int availableUnits;
@override@JsonKey() final  int totalUnits;
@override@JsonKey() final  bool isFeatured;
 final  List<MediaItem> _gallery;
@override@JsonKey() List<MediaItem> get gallery {
  if (_gallery is EqualUnmodifiableListView) return _gallery;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gallery);
}

 final  List<Building> _buildings;
@override@JsonKey() List<Building> get buildings {
  if (_buildings is EqualUnmodifiableListView) return _buildings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_buildings);
}

 final  List<Offer> _offers;
@override@JsonKey() List<Offer> get offers {
  if (_offers is EqualUnmodifiableListView) return _offers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_offers);
}


/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectCopyWith<_Project> get copyWith => __$ProjectCopyWithImpl<_Project>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Project&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.district, district) || other.district == district)&&(identical(other.address, address) || other.address == address)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.developer, developer) || other.developer == developer)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._amenities, _amenities)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.priceMin, priceMin) || other.priceMin == priceMin)&&(identical(other.priceMax, priceMax) || other.priceMax == priceMax)&&(identical(other.rentMin, rentMin) || other.rentMin == rentMin)&&(identical(other.rentMax, rentMax) || other.rentMax == rentMax)&&(identical(other.constructionProgress, constructionProgress) || other.constructionProgress == constructionProgress)&&(identical(other.plannedProgress, plannedProgress) || other.plannedProgress == plannedProgress)&&(identical(other.completionDate, completionDate) || other.completionDate == completionDate)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.availableUnits, availableUnits) || other.availableUnits == availableUnits)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&const DeepCollectionEquality().equals(other._gallery, _gallery)&&const DeepCollectionEquality().equals(other._buildings, _buildings)&&const DeepCollectionEquality().equals(other._offers, _offers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,type,status,district,address,lat,lng,developer,description,const DeepCollectionEquality().hash(_amenities),const DeepCollectionEquality().hash(_tags),priceMin,priceMax,rentMin,rentMax,constructionProgress,plannedProgress,completionDate,rating,availableUnits,totalUnits,isFeatured,const DeepCollectionEquality().hash(_gallery),const DeepCollectionEquality().hash(_buildings),const DeepCollectionEquality().hash(_offers)]);

@override
String toString() {
  return 'Project(id: $id, name: $name, type: $type, status: $status, district: $district, address: $address, lat: $lat, lng: $lng, developer: $developer, description: $description, amenities: $amenities, tags: $tags, priceMin: $priceMin, priceMax: $priceMax, rentMin: $rentMin, rentMax: $rentMax, constructionProgress: $constructionProgress, plannedProgress: $plannedProgress, completionDate: $completionDate, rating: $rating, availableUnits: $availableUnits, totalUnits: $totalUnits, isFeatured: $isFeatured, gallery: $gallery, buildings: $buildings, offers: $offers)';
}


}

/// @nodoc
abstract mixin class _$ProjectCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$ProjectCopyWith(_Project value, $Res Function(_Project) _then) = __$ProjectCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, ProjectType type, ProjectStatus status, String district, String address, double lat, double lng, Developer? developer, String? description, List<String> amenities, List<String> tags, double? priceMin, double? priceMax, double? rentMin, double? rentMax, int? constructionProgress, int? plannedProgress, DateTime? completionDate, double rating, int availableUnits, int totalUnits, bool isFeatured, List<MediaItem> gallery, List<Building> buildings, List<Offer> offers
});


@override $DeveloperCopyWith<$Res>? get developer;

}
/// @nodoc
class __$ProjectCopyWithImpl<$Res>
    implements _$ProjectCopyWith<$Res> {
  __$ProjectCopyWithImpl(this._self, this._then);

  final _Project _self;
  final $Res Function(_Project) _then;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? status = null,Object? district = null,Object? address = null,Object? lat = null,Object? lng = null,Object? developer = freezed,Object? description = freezed,Object? amenities = null,Object? tags = null,Object? priceMin = freezed,Object? priceMax = freezed,Object? rentMin = freezed,Object? rentMax = freezed,Object? constructionProgress = freezed,Object? plannedProgress = freezed,Object? completionDate = freezed,Object? rating = null,Object? availableUnits = null,Object? totalUnits = null,Object? isFeatured = null,Object? gallery = null,Object? buildings = null,Object? offers = null,}) {
  return _then(_Project(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProjectType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProjectStatus,district: null == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,developer: freezed == developer ? _self.developer : developer // ignore: cast_nullable_to_non_nullable
as Developer?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,amenities: null == amenities ? _self._amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,priceMin: freezed == priceMin ? _self.priceMin : priceMin // ignore: cast_nullable_to_non_nullable
as double?,priceMax: freezed == priceMax ? _self.priceMax : priceMax // ignore: cast_nullable_to_non_nullable
as double?,rentMin: freezed == rentMin ? _self.rentMin : rentMin // ignore: cast_nullable_to_non_nullable
as double?,rentMax: freezed == rentMax ? _self.rentMax : rentMax // ignore: cast_nullable_to_non_nullable
as double?,constructionProgress: freezed == constructionProgress ? _self.constructionProgress : constructionProgress // ignore: cast_nullable_to_non_nullable
as int?,plannedProgress: freezed == plannedProgress ? _self.plannedProgress : plannedProgress // ignore: cast_nullable_to_non_nullable
as int?,completionDate: freezed == completionDate ? _self.completionDate : completionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,availableUnits: null == availableUnits ? _self.availableUnits : availableUnits // ignore: cast_nullable_to_non_nullable
as int,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,gallery: null == gallery ? _self._gallery : gallery // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,buildings: null == buildings ? _self._buildings : buildings // ignore: cast_nullable_to_non_nullable
as List<Building>,offers: null == offers ? _self._offers : offers // ignore: cast_nullable_to_non_nullable
as List<Offer>,
  ));
}

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeveloperCopyWith<$Res>? get developer {
    if (_self.developer == null) {
    return null;
  }

  return $DeveloperCopyWith<$Res>(_self.developer!, (value) {
    return _then(_self.copyWith(developer: value));
  });
}
}

// dart format on
