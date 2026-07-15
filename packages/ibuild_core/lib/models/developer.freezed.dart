// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'developer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Developer {

 String get id; String get name; String? get logoUrl; double get rating; int get projectsCount;/// Developer/sales-office contact number.
 String? get phone;/// Assigned realtor/sales agent for this project, if any.
 String? get agentName; String? get agentPhone; String? get agentAvatarUrl;
/// Create a copy of Developer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeveloperCopyWith<Developer> get copyWith => _$DeveloperCopyWithImpl<Developer>(this as Developer, _$identity);

  /// Serializes this Developer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Developer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.projectsCount, projectsCount) || other.projectsCount == projectsCount)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.agentName, agentName) || other.agentName == agentName)&&(identical(other.agentPhone, agentPhone) || other.agentPhone == agentPhone)&&(identical(other.agentAvatarUrl, agentAvatarUrl) || other.agentAvatarUrl == agentAvatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,logoUrl,rating,projectsCount,phone,agentName,agentPhone,agentAvatarUrl);

@override
String toString() {
  return 'Developer(id: $id, name: $name, logoUrl: $logoUrl, rating: $rating, projectsCount: $projectsCount, phone: $phone, agentName: $agentName, agentPhone: $agentPhone, agentAvatarUrl: $agentAvatarUrl)';
}


}

/// @nodoc
abstract mixin class $DeveloperCopyWith<$Res>  {
  factory $DeveloperCopyWith(Developer value, $Res Function(Developer) _then) = _$DeveloperCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? logoUrl, double rating, int projectsCount, String? phone, String? agentName, String? agentPhone, String? agentAvatarUrl
});




}
/// @nodoc
class _$DeveloperCopyWithImpl<$Res>
    implements $DeveloperCopyWith<$Res> {
  _$DeveloperCopyWithImpl(this._self, this._then);

  final Developer _self;
  final $Res Function(Developer) _then;

/// Create a copy of Developer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? logoUrl = freezed,Object? rating = null,Object? projectsCount = null,Object? phone = freezed,Object? agentName = freezed,Object? agentPhone = freezed,Object? agentAvatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,projectsCount: null == projectsCount ? _self.projectsCount : projectsCount // ignore: cast_nullable_to_non_nullable
as int,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,agentName: freezed == agentName ? _self.agentName : agentName // ignore: cast_nullable_to_non_nullable
as String?,agentPhone: freezed == agentPhone ? _self.agentPhone : agentPhone // ignore: cast_nullable_to_non_nullable
as String?,agentAvatarUrl: freezed == agentAvatarUrl ? _self.agentAvatarUrl : agentAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Developer].
extension DeveloperPatterns on Developer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Developer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Developer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Developer value)  $default,){
final _that = this;
switch (_that) {
case _Developer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Developer value)?  $default,){
final _that = this;
switch (_that) {
case _Developer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? logoUrl,  double rating,  int projectsCount,  String? phone,  String? agentName,  String? agentPhone,  String? agentAvatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Developer() when $default != null:
return $default(_that.id,_that.name,_that.logoUrl,_that.rating,_that.projectsCount,_that.phone,_that.agentName,_that.agentPhone,_that.agentAvatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? logoUrl,  double rating,  int projectsCount,  String? phone,  String? agentName,  String? agentPhone,  String? agentAvatarUrl)  $default,) {final _that = this;
switch (_that) {
case _Developer():
return $default(_that.id,_that.name,_that.logoUrl,_that.rating,_that.projectsCount,_that.phone,_that.agentName,_that.agentPhone,_that.agentAvatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? logoUrl,  double rating,  int projectsCount,  String? phone,  String? agentName,  String? agentPhone,  String? agentAvatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _Developer() when $default != null:
return $default(_that.id,_that.name,_that.logoUrl,_that.rating,_that.projectsCount,_that.phone,_that.agentName,_that.agentPhone,_that.agentAvatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Developer implements Developer {
  const _Developer({required this.id, required this.name, this.logoUrl, this.rating = 0, this.projectsCount = 0, this.phone, this.agentName, this.agentPhone, this.agentAvatarUrl});
  factory _Developer.fromJson(Map<String, dynamic> json) => _$DeveloperFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? logoUrl;
@override@JsonKey() final  double rating;
@override@JsonKey() final  int projectsCount;
/// Developer/sales-office contact number.
@override final  String? phone;
/// Assigned realtor/sales agent for this project, if any.
@override final  String? agentName;
@override final  String? agentPhone;
@override final  String? agentAvatarUrl;

/// Create a copy of Developer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeveloperCopyWith<_Developer> get copyWith => __$DeveloperCopyWithImpl<_Developer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeveloperToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Developer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.projectsCount, projectsCount) || other.projectsCount == projectsCount)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.agentName, agentName) || other.agentName == agentName)&&(identical(other.agentPhone, agentPhone) || other.agentPhone == agentPhone)&&(identical(other.agentAvatarUrl, agentAvatarUrl) || other.agentAvatarUrl == agentAvatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,logoUrl,rating,projectsCount,phone,agentName,agentPhone,agentAvatarUrl);

@override
String toString() {
  return 'Developer(id: $id, name: $name, logoUrl: $logoUrl, rating: $rating, projectsCount: $projectsCount, phone: $phone, agentName: $agentName, agentPhone: $agentPhone, agentAvatarUrl: $agentAvatarUrl)';
}


}

/// @nodoc
abstract mixin class _$DeveloperCopyWith<$Res> implements $DeveloperCopyWith<$Res> {
  factory _$DeveloperCopyWith(_Developer value, $Res Function(_Developer) _then) = __$DeveloperCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? logoUrl, double rating, int projectsCount, String? phone, String? agentName, String? agentPhone, String? agentAvatarUrl
});




}
/// @nodoc
class __$DeveloperCopyWithImpl<$Res>
    implements _$DeveloperCopyWith<$Res> {
  __$DeveloperCopyWithImpl(this._self, this._then);

  final _Developer _self;
  final $Res Function(_Developer) _then;

/// Create a copy of Developer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? logoUrl = freezed,Object? rating = null,Object? projectsCount = null,Object? phone = freezed,Object? agentName = freezed,Object? agentPhone = freezed,Object? agentAvatarUrl = freezed,}) {
  return _then(_Developer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,projectsCount: null == projectsCount ? _self.projectsCount : projectsCount // ignore: cast_nullable_to_non_nullable
as int,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,agentName: freezed == agentName ? _self.agentName : agentName // ignore: cast_nullable_to_non_nullable
as String?,agentPhone: freezed == agentPhone ? _self.agentPhone : agentPhone // ignore: cast_nullable_to_non_nullable
as String?,agentAvatarUrl: freezed == agentAvatarUrl ? _self.agentAvatarUrl : agentAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
