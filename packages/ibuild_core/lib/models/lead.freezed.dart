// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lead.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Lead {

 String get id; String get number; String get projectId; String get projectName; String? get unitId; String? get unitLabel; LeadIntent get intent; LeadStatus get status; String get contactPhone; String? get message; DateTime? get preferredAt; DateTime get createdAt;
/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadCopyWith<Lead> get copyWith => _$LeadCopyWithImpl<Lead>(this as Lead, _$identity);

  /// Serializes this Lead to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lead&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.projectName, projectName) || other.projectName == projectName)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.status, status) || other.status == status)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.message, message) || other.message == message)&&(identical(other.preferredAt, preferredAt) || other.preferredAt == preferredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,projectId,projectName,unitId,unitLabel,intent,status,contactPhone,message,preferredAt,createdAt);

@override
String toString() {
  return 'Lead(id: $id, number: $number, projectId: $projectId, projectName: $projectName, unitId: $unitId, unitLabel: $unitLabel, intent: $intent, status: $status, contactPhone: $contactPhone, message: $message, preferredAt: $preferredAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $LeadCopyWith<$Res>  {
  factory $LeadCopyWith(Lead value, $Res Function(Lead) _then) = _$LeadCopyWithImpl;
@useResult
$Res call({
 String id, String number, String projectId, String projectName, String? unitId, String? unitLabel, LeadIntent intent, LeadStatus status, String contactPhone, String? message, DateTime? preferredAt, DateTime createdAt
});




}
/// @nodoc
class _$LeadCopyWithImpl<$Res>
    implements $LeadCopyWith<$Res> {
  _$LeadCopyWithImpl(this._self, this._then);

  final Lead _self;
  final $Res Function(Lead) _then;

/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? projectId = null,Object? projectName = null,Object? unitId = freezed,Object? unitLabel = freezed,Object? intent = null,Object? status = null,Object? contactPhone = null,Object? message = freezed,Object? preferredAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,projectName: null == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as LeadIntent,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LeadStatus,contactPhone: null == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,preferredAt: freezed == preferredAt ? _self.preferredAt : preferredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Lead].
extension LeadPatterns on Lead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lead value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lead() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lead value)  $default,){
final _that = this;
switch (_that) {
case _Lead():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lead value)?  $default,){
final _that = this;
switch (_that) {
case _Lead() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String number,  String projectId,  String projectName,  String? unitId,  String? unitLabel,  LeadIntent intent,  LeadStatus status,  String contactPhone,  String? message,  DateTime? preferredAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lead() when $default != null:
return $default(_that.id,_that.number,_that.projectId,_that.projectName,_that.unitId,_that.unitLabel,_that.intent,_that.status,_that.contactPhone,_that.message,_that.preferredAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String number,  String projectId,  String projectName,  String? unitId,  String? unitLabel,  LeadIntent intent,  LeadStatus status,  String contactPhone,  String? message,  DateTime? preferredAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Lead():
return $default(_that.id,_that.number,_that.projectId,_that.projectName,_that.unitId,_that.unitLabel,_that.intent,_that.status,_that.contactPhone,_that.message,_that.preferredAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String number,  String projectId,  String projectName,  String? unitId,  String? unitLabel,  LeadIntent intent,  LeadStatus status,  String contactPhone,  String? message,  DateTime? preferredAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Lead() when $default != null:
return $default(_that.id,_that.number,_that.projectId,_that.projectName,_that.unitId,_that.unitLabel,_that.intent,_that.status,_that.contactPhone,_that.message,_that.preferredAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Lead implements Lead {
  const _Lead({required this.id, required this.number, required this.projectId, required this.projectName, this.unitId, this.unitLabel, required this.intent, required this.status, required this.contactPhone, this.message, this.preferredAt, required this.createdAt});
  factory _Lead.fromJson(Map<String, dynamic> json) => _$LeadFromJson(json);

@override final  String id;
@override final  String number;
@override final  String projectId;
@override final  String projectName;
@override final  String? unitId;
@override final  String? unitLabel;
@override final  LeadIntent intent;
@override final  LeadStatus status;
@override final  String contactPhone;
@override final  String? message;
@override final  DateTime? preferredAt;
@override final  DateTime createdAt;

/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeadCopyWith<_Lead> get copyWith => __$LeadCopyWithImpl<_Lead>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LeadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lead&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.projectName, projectName) || other.projectName == projectName)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.status, status) || other.status == status)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.message, message) || other.message == message)&&(identical(other.preferredAt, preferredAt) || other.preferredAt == preferredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,projectId,projectName,unitId,unitLabel,intent,status,contactPhone,message,preferredAt,createdAt);

@override
String toString() {
  return 'Lead(id: $id, number: $number, projectId: $projectId, projectName: $projectName, unitId: $unitId, unitLabel: $unitLabel, intent: $intent, status: $status, contactPhone: $contactPhone, message: $message, preferredAt: $preferredAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$LeadCopyWith<$Res> implements $LeadCopyWith<$Res> {
  factory _$LeadCopyWith(_Lead value, $Res Function(_Lead) _then) = __$LeadCopyWithImpl;
@override @useResult
$Res call({
 String id, String number, String projectId, String projectName, String? unitId, String? unitLabel, LeadIntent intent, LeadStatus status, String contactPhone, String? message, DateTime? preferredAt, DateTime createdAt
});




}
/// @nodoc
class __$LeadCopyWithImpl<$Res>
    implements _$LeadCopyWith<$Res> {
  __$LeadCopyWithImpl(this._self, this._then);

  final _Lead _self;
  final $Res Function(_Lead) _then;

/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? projectId = null,Object? projectName = null,Object? unitId = freezed,Object? unitLabel = freezed,Object? intent = null,Object? status = null,Object? contactPhone = null,Object? message = freezed,Object? preferredAt = freezed,Object? createdAt = null,}) {
  return _then(_Lead(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,projectName: null == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as LeadIntent,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LeadStatus,contactPhone: null == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,preferredAt: freezed == preferredAt ? _self.preferredAt : preferredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
