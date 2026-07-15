// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PhotoReport {

 String get id; String get projectId; String? get buildingId; String get photoUrl; DateTime get takenAt; bool get takenAtIsManual; int? get progressPercent; String? get uploadedBy; DateTime? get createdAt;
/// Create a copy of PhotoReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhotoReportCopyWith<PhotoReport> get copyWith => _$PhotoReportCopyWithImpl<PhotoReport>(this as PhotoReport, _$identity);

  /// Serializes this PhotoReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoReport&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.takenAt, takenAt) || other.takenAt == takenAt)&&(identical(other.takenAtIsManual, takenAtIsManual) || other.takenAtIsManual == takenAtIsManual)&&(identical(other.progressPercent, progressPercent) || other.progressPercent == progressPercent)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,buildingId,photoUrl,takenAt,takenAtIsManual,progressPercent,uploadedBy,createdAt);

@override
String toString() {
  return 'PhotoReport(id: $id, projectId: $projectId, buildingId: $buildingId, photoUrl: $photoUrl, takenAt: $takenAt, takenAtIsManual: $takenAtIsManual, progressPercent: $progressPercent, uploadedBy: $uploadedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PhotoReportCopyWith<$Res>  {
  factory $PhotoReportCopyWith(PhotoReport value, $Res Function(PhotoReport) _then) = _$PhotoReportCopyWithImpl;
@useResult
$Res call({
 String id, String projectId, String? buildingId, String photoUrl, DateTime takenAt, bool takenAtIsManual, int? progressPercent, String? uploadedBy, DateTime? createdAt
});




}
/// @nodoc
class _$PhotoReportCopyWithImpl<$Res>
    implements $PhotoReportCopyWith<$Res> {
  _$PhotoReportCopyWithImpl(this._self, this._then);

  final PhotoReport _self;
  final $Res Function(PhotoReport) _then;

/// Create a copy of PhotoReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? projectId = null,Object? buildingId = freezed,Object? photoUrl = null,Object? takenAt = null,Object? takenAtIsManual = null,Object? progressPercent = freezed,Object? uploadedBy = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,buildingId: freezed == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,takenAt: null == takenAt ? _self.takenAt : takenAt // ignore: cast_nullable_to_non_nullable
as DateTime,takenAtIsManual: null == takenAtIsManual ? _self.takenAtIsManual : takenAtIsManual // ignore: cast_nullable_to_non_nullable
as bool,progressPercent: freezed == progressPercent ? _self.progressPercent : progressPercent // ignore: cast_nullable_to_non_nullable
as int?,uploadedBy: freezed == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PhotoReport].
extension PhotoReportPatterns on PhotoReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhotoReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhotoReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhotoReport value)  $default,){
final _that = this;
switch (_that) {
case _PhotoReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhotoReport value)?  $default,){
final _that = this;
switch (_that) {
case _PhotoReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String projectId,  String? buildingId,  String photoUrl,  DateTime takenAt,  bool takenAtIsManual,  int? progressPercent,  String? uploadedBy,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhotoReport() when $default != null:
return $default(_that.id,_that.projectId,_that.buildingId,_that.photoUrl,_that.takenAt,_that.takenAtIsManual,_that.progressPercent,_that.uploadedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String projectId,  String? buildingId,  String photoUrl,  DateTime takenAt,  bool takenAtIsManual,  int? progressPercent,  String? uploadedBy,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PhotoReport():
return $default(_that.id,_that.projectId,_that.buildingId,_that.photoUrl,_that.takenAt,_that.takenAtIsManual,_that.progressPercent,_that.uploadedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String projectId,  String? buildingId,  String photoUrl,  DateTime takenAt,  bool takenAtIsManual,  int? progressPercent,  String? uploadedBy,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PhotoReport() when $default != null:
return $default(_that.id,_that.projectId,_that.buildingId,_that.photoUrl,_that.takenAt,_that.takenAtIsManual,_that.progressPercent,_that.uploadedBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PhotoReport implements PhotoReport {
  const _PhotoReport({required this.id, required this.projectId, this.buildingId, required this.photoUrl, required this.takenAt, this.takenAtIsManual = false, this.progressPercent, this.uploadedBy, this.createdAt});
  factory _PhotoReport.fromJson(Map<String, dynamic> json) => _$PhotoReportFromJson(json);

@override final  String id;
@override final  String projectId;
@override final  String? buildingId;
@override final  String photoUrl;
@override final  DateTime takenAt;
@override@JsonKey() final  bool takenAtIsManual;
@override final  int? progressPercent;
@override final  String? uploadedBy;
@override final  DateTime? createdAt;

/// Create a copy of PhotoReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhotoReportCopyWith<_PhotoReport> get copyWith => __$PhotoReportCopyWithImpl<_PhotoReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PhotoReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhotoReport&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.takenAt, takenAt) || other.takenAt == takenAt)&&(identical(other.takenAtIsManual, takenAtIsManual) || other.takenAtIsManual == takenAtIsManual)&&(identical(other.progressPercent, progressPercent) || other.progressPercent == progressPercent)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,buildingId,photoUrl,takenAt,takenAtIsManual,progressPercent,uploadedBy,createdAt);

@override
String toString() {
  return 'PhotoReport(id: $id, projectId: $projectId, buildingId: $buildingId, photoUrl: $photoUrl, takenAt: $takenAt, takenAtIsManual: $takenAtIsManual, progressPercent: $progressPercent, uploadedBy: $uploadedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PhotoReportCopyWith<$Res> implements $PhotoReportCopyWith<$Res> {
  factory _$PhotoReportCopyWith(_PhotoReport value, $Res Function(_PhotoReport) _then) = __$PhotoReportCopyWithImpl;
@override @useResult
$Res call({
 String id, String projectId, String? buildingId, String photoUrl, DateTime takenAt, bool takenAtIsManual, int? progressPercent, String? uploadedBy, DateTime? createdAt
});




}
/// @nodoc
class __$PhotoReportCopyWithImpl<$Res>
    implements _$PhotoReportCopyWith<$Res> {
  __$PhotoReportCopyWithImpl(this._self, this._then);

  final _PhotoReport _self;
  final $Res Function(_PhotoReport) _then;

/// Create a copy of PhotoReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? projectId = null,Object? buildingId = freezed,Object? photoUrl = null,Object? takenAt = null,Object? takenAtIsManual = null,Object? progressPercent = freezed,Object? uploadedBy = freezed,Object? createdAt = freezed,}) {
  return _then(_PhotoReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,buildingId: freezed == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,takenAt: null == takenAt ? _self.takenAt : takenAt // ignore: cast_nullable_to_non_nullable
as DateTime,takenAtIsManual: null == takenAtIsManual ? _self.takenAtIsManual : takenAtIsManual // ignore: cast_nullable_to_non_nullable
as bool,progressPercent: freezed == progressPercent ? _self.progressPercent : progressPercent // ignore: cast_nullable_to_non_nullable
as int?,uploadedBy: freezed == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
