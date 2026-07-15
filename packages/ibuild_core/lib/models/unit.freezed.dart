// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Unit {

 String get id; String get buildingId; String get number; UnitKind get kind; DealType get dealType; UnitStatus get status; int get floor; bool get isOffplan; double? get areaTotal; double? get areaLiving; int? get rooms; String? get layout; double? get price; double? get priceM2; double? get rentMonthly; double? get rentM2; int? get minLeaseMonths; String? get finishing; String? get view; int? get planColumn; int? get planRow; List<MediaItem> get media;
/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitCopyWith<Unit> get copyWith => _$UnitCopyWithImpl<Unit>(this as Unit, _$identity);

  /// Serializes this Unit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Unit&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.number, number) || other.number == number)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.dealType, dealType) || other.dealType == dealType)&&(identical(other.status, status) || other.status == status)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.isOffplan, isOffplan) || other.isOffplan == isOffplan)&&(identical(other.areaTotal, areaTotal) || other.areaTotal == areaTotal)&&(identical(other.areaLiving, areaLiving) || other.areaLiving == areaLiving)&&(identical(other.rooms, rooms) || other.rooms == rooms)&&(identical(other.layout, layout) || other.layout == layout)&&(identical(other.price, price) || other.price == price)&&(identical(other.priceM2, priceM2) || other.priceM2 == priceM2)&&(identical(other.rentMonthly, rentMonthly) || other.rentMonthly == rentMonthly)&&(identical(other.rentM2, rentM2) || other.rentM2 == rentM2)&&(identical(other.minLeaseMonths, minLeaseMonths) || other.minLeaseMonths == minLeaseMonths)&&(identical(other.finishing, finishing) || other.finishing == finishing)&&(identical(other.view, view) || other.view == view)&&(identical(other.planColumn, planColumn) || other.planColumn == planColumn)&&(identical(other.planRow, planRow) || other.planRow == planRow)&&const DeepCollectionEquality().equals(other.media, media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,buildingId,number,kind,dealType,status,floor,isOffplan,areaTotal,areaLiving,rooms,layout,price,priceM2,rentMonthly,rentM2,minLeaseMonths,finishing,view,planColumn,planRow,const DeepCollectionEquality().hash(media)]);

@override
String toString() {
  return 'Unit(id: $id, buildingId: $buildingId, number: $number, kind: $kind, dealType: $dealType, status: $status, floor: $floor, isOffplan: $isOffplan, areaTotal: $areaTotal, areaLiving: $areaLiving, rooms: $rooms, layout: $layout, price: $price, priceM2: $priceM2, rentMonthly: $rentMonthly, rentM2: $rentM2, minLeaseMonths: $minLeaseMonths, finishing: $finishing, view: $view, planColumn: $planColumn, planRow: $planRow, media: $media)';
}


}

/// @nodoc
abstract mixin class $UnitCopyWith<$Res>  {
  factory $UnitCopyWith(Unit value, $Res Function(Unit) _then) = _$UnitCopyWithImpl;
@useResult
$Res call({
 String id, String buildingId, String number, UnitKind kind, DealType dealType, UnitStatus status, int floor, bool isOffplan, double? areaTotal, double? areaLiving, int? rooms, String? layout, double? price, double? priceM2, double? rentMonthly, double? rentM2, int? minLeaseMonths, String? finishing, String? view, int? planColumn, int? planRow, List<MediaItem> media
});




}
/// @nodoc
class _$UnitCopyWithImpl<$Res>
    implements $UnitCopyWith<$Res> {
  _$UnitCopyWithImpl(this._self, this._then);

  final Unit _self;
  final $Res Function(Unit) _then;

/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? buildingId = null,Object? number = null,Object? kind = null,Object? dealType = null,Object? status = null,Object? floor = null,Object? isOffplan = null,Object? areaTotal = freezed,Object? areaLiving = freezed,Object? rooms = freezed,Object? layout = freezed,Object? price = freezed,Object? priceM2 = freezed,Object? rentMonthly = freezed,Object? rentM2 = freezed,Object? minLeaseMonths = freezed,Object? finishing = freezed,Object? view = freezed,Object? planColumn = freezed,Object? planRow = freezed,Object? media = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as UnitKind,dealType: null == dealType ? _self.dealType : dealType // ignore: cast_nullable_to_non_nullable
as DealType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UnitStatus,floor: null == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as int,isOffplan: null == isOffplan ? _self.isOffplan : isOffplan // ignore: cast_nullable_to_non_nullable
as bool,areaTotal: freezed == areaTotal ? _self.areaTotal : areaTotal // ignore: cast_nullable_to_non_nullable
as double?,areaLiving: freezed == areaLiving ? _self.areaLiving : areaLiving // ignore: cast_nullable_to_non_nullable
as double?,rooms: freezed == rooms ? _self.rooms : rooms // ignore: cast_nullable_to_non_nullable
as int?,layout: freezed == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,priceM2: freezed == priceM2 ? _self.priceM2 : priceM2 // ignore: cast_nullable_to_non_nullable
as double?,rentMonthly: freezed == rentMonthly ? _self.rentMonthly : rentMonthly // ignore: cast_nullable_to_non_nullable
as double?,rentM2: freezed == rentM2 ? _self.rentM2 : rentM2 // ignore: cast_nullable_to_non_nullable
as double?,minLeaseMonths: freezed == minLeaseMonths ? _self.minLeaseMonths : minLeaseMonths // ignore: cast_nullable_to_non_nullable
as int?,finishing: freezed == finishing ? _self.finishing : finishing // ignore: cast_nullable_to_non_nullable
as String?,view: freezed == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as String?,planColumn: freezed == planColumn ? _self.planColumn : planColumn // ignore: cast_nullable_to_non_nullable
as int?,planRow: freezed == planRow ? _self.planRow : planRow // ignore: cast_nullable_to_non_nullable
as int?,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [Unit].
extension UnitPatterns on Unit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Unit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Unit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Unit value)  $default,){
final _that = this;
switch (_that) {
case _Unit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Unit value)?  $default,){
final _that = this;
switch (_that) {
case _Unit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String buildingId,  String number,  UnitKind kind,  DealType dealType,  UnitStatus status,  int floor,  bool isOffplan,  double? areaTotal,  double? areaLiving,  int? rooms,  String? layout,  double? price,  double? priceM2,  double? rentMonthly,  double? rentM2,  int? minLeaseMonths,  String? finishing,  String? view,  int? planColumn,  int? planRow,  List<MediaItem> media)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Unit() when $default != null:
return $default(_that.id,_that.buildingId,_that.number,_that.kind,_that.dealType,_that.status,_that.floor,_that.isOffplan,_that.areaTotal,_that.areaLiving,_that.rooms,_that.layout,_that.price,_that.priceM2,_that.rentMonthly,_that.rentM2,_that.minLeaseMonths,_that.finishing,_that.view,_that.planColumn,_that.planRow,_that.media);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String buildingId,  String number,  UnitKind kind,  DealType dealType,  UnitStatus status,  int floor,  bool isOffplan,  double? areaTotal,  double? areaLiving,  int? rooms,  String? layout,  double? price,  double? priceM2,  double? rentMonthly,  double? rentM2,  int? minLeaseMonths,  String? finishing,  String? view,  int? planColumn,  int? planRow,  List<MediaItem> media)  $default,) {final _that = this;
switch (_that) {
case _Unit():
return $default(_that.id,_that.buildingId,_that.number,_that.kind,_that.dealType,_that.status,_that.floor,_that.isOffplan,_that.areaTotal,_that.areaLiving,_that.rooms,_that.layout,_that.price,_that.priceM2,_that.rentMonthly,_that.rentM2,_that.minLeaseMonths,_that.finishing,_that.view,_that.planColumn,_that.planRow,_that.media);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String buildingId,  String number,  UnitKind kind,  DealType dealType,  UnitStatus status,  int floor,  bool isOffplan,  double? areaTotal,  double? areaLiving,  int? rooms,  String? layout,  double? price,  double? priceM2,  double? rentMonthly,  double? rentM2,  int? minLeaseMonths,  String? finishing,  String? view,  int? planColumn,  int? planRow,  List<MediaItem> media)?  $default,) {final _that = this;
switch (_that) {
case _Unit() when $default != null:
return $default(_that.id,_that.buildingId,_that.number,_that.kind,_that.dealType,_that.status,_that.floor,_that.isOffplan,_that.areaTotal,_that.areaLiving,_that.rooms,_that.layout,_that.price,_that.priceM2,_that.rentMonthly,_that.rentM2,_that.minLeaseMonths,_that.finishing,_that.view,_that.planColumn,_that.planRow,_that.media);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Unit implements Unit {
  const _Unit({required this.id, required this.buildingId, required this.number, required this.kind, required this.dealType, required this.status, required this.floor, this.isOffplan = false, this.areaTotal, this.areaLiving, this.rooms, this.layout, this.price, this.priceM2, this.rentMonthly, this.rentM2, this.minLeaseMonths, this.finishing, this.view, this.planColumn, this.planRow, final  List<MediaItem> media = const <MediaItem>[]}): _media = media;
  factory _Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);

@override final  String id;
@override final  String buildingId;
@override final  String number;
@override final  UnitKind kind;
@override final  DealType dealType;
@override final  UnitStatus status;
@override final  int floor;
@override@JsonKey() final  bool isOffplan;
@override final  double? areaTotal;
@override final  double? areaLiving;
@override final  int? rooms;
@override final  String? layout;
@override final  double? price;
@override final  double? priceM2;
@override final  double? rentMonthly;
@override final  double? rentM2;
@override final  int? minLeaseMonths;
@override final  String? finishing;
@override final  String? view;
@override final  int? planColumn;
@override final  int? planRow;
 final  List<MediaItem> _media;
@override@JsonKey() List<MediaItem> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}


/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitCopyWith<_Unit> get copyWith => __$UnitCopyWithImpl<_Unit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Unit&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.number, number) || other.number == number)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.dealType, dealType) || other.dealType == dealType)&&(identical(other.status, status) || other.status == status)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.isOffplan, isOffplan) || other.isOffplan == isOffplan)&&(identical(other.areaTotal, areaTotal) || other.areaTotal == areaTotal)&&(identical(other.areaLiving, areaLiving) || other.areaLiving == areaLiving)&&(identical(other.rooms, rooms) || other.rooms == rooms)&&(identical(other.layout, layout) || other.layout == layout)&&(identical(other.price, price) || other.price == price)&&(identical(other.priceM2, priceM2) || other.priceM2 == priceM2)&&(identical(other.rentMonthly, rentMonthly) || other.rentMonthly == rentMonthly)&&(identical(other.rentM2, rentM2) || other.rentM2 == rentM2)&&(identical(other.minLeaseMonths, minLeaseMonths) || other.minLeaseMonths == minLeaseMonths)&&(identical(other.finishing, finishing) || other.finishing == finishing)&&(identical(other.view, view) || other.view == view)&&(identical(other.planColumn, planColumn) || other.planColumn == planColumn)&&(identical(other.planRow, planRow) || other.planRow == planRow)&&const DeepCollectionEquality().equals(other._media, _media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,buildingId,number,kind,dealType,status,floor,isOffplan,areaTotal,areaLiving,rooms,layout,price,priceM2,rentMonthly,rentM2,minLeaseMonths,finishing,view,planColumn,planRow,const DeepCollectionEquality().hash(_media)]);

@override
String toString() {
  return 'Unit(id: $id, buildingId: $buildingId, number: $number, kind: $kind, dealType: $dealType, status: $status, floor: $floor, isOffplan: $isOffplan, areaTotal: $areaTotal, areaLiving: $areaLiving, rooms: $rooms, layout: $layout, price: $price, priceM2: $priceM2, rentMonthly: $rentMonthly, rentM2: $rentM2, minLeaseMonths: $minLeaseMonths, finishing: $finishing, view: $view, planColumn: $planColumn, planRow: $planRow, media: $media)';
}


}

/// @nodoc
abstract mixin class _$UnitCopyWith<$Res> implements $UnitCopyWith<$Res> {
  factory _$UnitCopyWith(_Unit value, $Res Function(_Unit) _then) = __$UnitCopyWithImpl;
@override @useResult
$Res call({
 String id, String buildingId, String number, UnitKind kind, DealType dealType, UnitStatus status, int floor, bool isOffplan, double? areaTotal, double? areaLiving, int? rooms, String? layout, double? price, double? priceM2, double? rentMonthly, double? rentM2, int? minLeaseMonths, String? finishing, String? view, int? planColumn, int? planRow, List<MediaItem> media
});




}
/// @nodoc
class __$UnitCopyWithImpl<$Res>
    implements _$UnitCopyWith<$Res> {
  __$UnitCopyWithImpl(this._self, this._then);

  final _Unit _self;
  final $Res Function(_Unit) _then;

/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? buildingId = null,Object? number = null,Object? kind = null,Object? dealType = null,Object? status = null,Object? floor = null,Object? isOffplan = null,Object? areaTotal = freezed,Object? areaLiving = freezed,Object? rooms = freezed,Object? layout = freezed,Object? price = freezed,Object? priceM2 = freezed,Object? rentMonthly = freezed,Object? rentM2 = freezed,Object? minLeaseMonths = freezed,Object? finishing = freezed,Object? view = freezed,Object? planColumn = freezed,Object? planRow = freezed,Object? media = null,}) {
  return _then(_Unit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as UnitKind,dealType: null == dealType ? _self.dealType : dealType // ignore: cast_nullable_to_non_nullable
as DealType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UnitStatus,floor: null == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as int,isOffplan: null == isOffplan ? _self.isOffplan : isOffplan // ignore: cast_nullable_to_non_nullable
as bool,areaTotal: freezed == areaTotal ? _self.areaTotal : areaTotal // ignore: cast_nullable_to_non_nullable
as double?,areaLiving: freezed == areaLiving ? _self.areaLiving : areaLiving // ignore: cast_nullable_to_non_nullable
as double?,rooms: freezed == rooms ? _self.rooms : rooms // ignore: cast_nullable_to_non_nullable
as int?,layout: freezed == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,priceM2: freezed == priceM2 ? _self.priceM2 : priceM2 // ignore: cast_nullable_to_non_nullable
as double?,rentMonthly: freezed == rentMonthly ? _self.rentMonthly : rentMonthly // ignore: cast_nullable_to_non_nullable
as double?,rentM2: freezed == rentM2 ? _self.rentM2 : rentM2 // ignore: cast_nullable_to_non_nullable
as double?,minLeaseMonths: freezed == minLeaseMonths ? _self.minLeaseMonths : minLeaseMonths // ignore: cast_nullable_to_non_nullable
as int?,finishing: freezed == finishing ? _self.finishing : finishing // ignore: cast_nullable_to_non_nullable
as String?,view: freezed == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as String?,planColumn: freezed == planColumn ? _self.planColumn : planColumn // ignore: cast_nullable_to_non_nullable
as int?,planRow: freezed == planRow ? _self.planRow : planRow // ignore: cast_nullable_to_non_nullable
as int?,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,
  ));
}


}

// dart format on
