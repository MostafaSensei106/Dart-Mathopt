// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'errors.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FrbSolverError {

 Object get field0;



@override
bool operator ==(Object other) {
  final _this = this as FrbSolverError;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FrbSolverError&&const DeepCollectionEquality().equals(other.field0, _this.field0));
}


@override
int get hashCode {
  final _this = this as FrbSolverError;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.field0));
}

@override
String toString() {
  final _this = this as FrbSolverError;
  return 'FrbSolverError(field0: ${_this.field0})';
}


}

/// @nodoc
class $FrbSolverErrorCopyWith<$Res>  {
$FrbSolverErrorCopyWith(FrbSolverError _, $Res Function(FrbSolverError) __);
}


/// Adds pattern-matching-related methods to [FrbSolverError].
extension FrbSolverErrorPatterns on FrbSolverError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FrbSolverError_CapabilityError value)?  capabilityError,TResult Function( FrbSolverError_EngineFailure value)?  engineFailure,TResult Function( FrbSolverError_InvalidInput value)?  invalidInput,TResult Function( FrbSolverError_TimeLimitExceeded value)?  timeLimitExceeded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FrbSolverError_CapabilityError() when capabilityError != null:
return capabilityError(_that);case FrbSolverError_EngineFailure() when engineFailure != null:
return engineFailure(_that);case FrbSolverError_InvalidInput() when invalidInput != null:
return invalidInput(_that);case FrbSolverError_TimeLimitExceeded() when timeLimitExceeded != null:
return timeLimitExceeded(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FrbSolverError_CapabilityError value)  capabilityError,required TResult Function( FrbSolverError_EngineFailure value)  engineFailure,required TResult Function( FrbSolverError_InvalidInput value)  invalidInput,required TResult Function( FrbSolverError_TimeLimitExceeded value)  timeLimitExceeded,}){
final _that = this;
switch (_that) {
case FrbSolverError_CapabilityError():
return capabilityError(_that);case FrbSolverError_EngineFailure():
return engineFailure(_that);case FrbSolverError_InvalidInput():
return invalidInput(_that);case FrbSolverError_TimeLimitExceeded():
return timeLimitExceeded(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FrbSolverError_CapabilityError value)?  capabilityError,TResult? Function( FrbSolverError_EngineFailure value)?  engineFailure,TResult? Function( FrbSolverError_InvalidInput value)?  invalidInput,TResult? Function( FrbSolverError_TimeLimitExceeded value)?  timeLimitExceeded,}){
final _that = this;
switch (_that) {
case FrbSolverError_CapabilityError() when capabilityError != null:
return capabilityError(_that);case FrbSolverError_EngineFailure() when engineFailure != null:
return engineFailure(_that);case FrbSolverError_InvalidInput() when invalidInput != null:
return invalidInput(_that);case FrbSolverError_TimeLimitExceeded() when timeLimitExceeded != null:
return timeLimitExceeded(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field0)?  capabilityError,TResult Function( String field0)?  engineFailure,TResult Function( String field0)?  invalidInput,TResult Function( double field0)?  timeLimitExceeded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FrbSolverError_CapabilityError() when capabilityError != null:
return capabilityError(_that.field0);case FrbSolverError_EngineFailure() when engineFailure != null:
return engineFailure(_that.field0);case FrbSolverError_InvalidInput() when invalidInput != null:
return invalidInput(_that.field0);case FrbSolverError_TimeLimitExceeded() when timeLimitExceeded != null:
return timeLimitExceeded(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field0)  capabilityError,required TResult Function( String field0)  engineFailure,required TResult Function( String field0)  invalidInput,required TResult Function( double field0)  timeLimitExceeded,}) {final _that = this;
switch (_that) {
case FrbSolverError_CapabilityError():
return capabilityError(_that.field0);case FrbSolverError_EngineFailure():
return engineFailure(_that.field0);case FrbSolverError_InvalidInput():
return invalidInput(_that.field0);case FrbSolverError_TimeLimitExceeded():
return timeLimitExceeded(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field0)?  capabilityError,TResult? Function( String field0)?  engineFailure,TResult? Function( String field0)?  invalidInput,TResult? Function( double field0)?  timeLimitExceeded,}) {final _that = this;
switch (_that) {
case FrbSolverError_CapabilityError() when capabilityError != null:
return capabilityError(_that.field0);case FrbSolverError_EngineFailure() when engineFailure != null:
return engineFailure(_that.field0);case FrbSolverError_InvalidInput() when invalidInput != null:
return invalidInput(_that.field0);case FrbSolverError_TimeLimitExceeded() when timeLimitExceeded != null:
return timeLimitExceeded(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class FrbSolverError_CapabilityError extends FrbSolverError {
  const FrbSolverError_CapabilityError(this.field0): super._();
  

@override final  String field0;

/// Create a copy of FrbSolverError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrbSolverError_CapabilityErrorCopyWith<FrbSolverError_CapabilityError> get copyWith => _$FrbSolverError_CapabilityErrorCopyWithImpl<FrbSolverError_CapabilityError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FrbSolverError_CapabilityError&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field0);
}

@override
String toString() {
    return 'FrbSolverError.capabilityError(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $FrbSolverError_CapabilityErrorCopyWith<$Res> implements $FrbSolverErrorCopyWith<$Res> {
  factory $FrbSolverError_CapabilityErrorCopyWith(FrbSolverError_CapabilityError value, $Res Function(FrbSolverError_CapabilityError) _then) = _$FrbSolverError_CapabilityErrorCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$FrbSolverError_CapabilityErrorCopyWithImpl<$Res>
    implements $FrbSolverError_CapabilityErrorCopyWith<$Res> {
  _$FrbSolverError_CapabilityErrorCopyWithImpl(this._self, this._then);

  final FrbSolverError_CapabilityError _self;
  final $Res Function(FrbSolverError_CapabilityError) _then;

/// Create a copy of FrbSolverError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(FrbSolverError_CapabilityError(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class FrbSolverError_EngineFailure extends FrbSolverError {
  const FrbSolverError_EngineFailure(this.field0): super._();
  

@override final  String field0;

/// Create a copy of FrbSolverError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrbSolverError_EngineFailureCopyWith<FrbSolverError_EngineFailure> get copyWith => _$FrbSolverError_EngineFailureCopyWithImpl<FrbSolverError_EngineFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FrbSolverError_EngineFailure&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field0);
}

@override
String toString() {
    return 'FrbSolverError.engineFailure(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $FrbSolverError_EngineFailureCopyWith<$Res> implements $FrbSolverErrorCopyWith<$Res> {
  factory $FrbSolverError_EngineFailureCopyWith(FrbSolverError_EngineFailure value, $Res Function(FrbSolverError_EngineFailure) _then) = _$FrbSolverError_EngineFailureCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$FrbSolverError_EngineFailureCopyWithImpl<$Res>
    implements $FrbSolverError_EngineFailureCopyWith<$Res> {
  _$FrbSolverError_EngineFailureCopyWithImpl(this._self, this._then);

  final FrbSolverError_EngineFailure _self;
  final $Res Function(FrbSolverError_EngineFailure) _then;

/// Create a copy of FrbSolverError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(FrbSolverError_EngineFailure(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class FrbSolverError_InvalidInput extends FrbSolverError {
  const FrbSolverError_InvalidInput(this.field0): super._();
  

@override final  String field0;

/// Create a copy of FrbSolverError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrbSolverError_InvalidInputCopyWith<FrbSolverError_InvalidInput> get copyWith => _$FrbSolverError_InvalidInputCopyWithImpl<FrbSolverError_InvalidInput>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FrbSolverError_InvalidInput&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field0);
}

@override
String toString() {
    return 'FrbSolverError.invalidInput(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $FrbSolverError_InvalidInputCopyWith<$Res> implements $FrbSolverErrorCopyWith<$Res> {
  factory $FrbSolverError_InvalidInputCopyWith(FrbSolverError_InvalidInput value, $Res Function(FrbSolverError_InvalidInput) _then) = _$FrbSolverError_InvalidInputCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$FrbSolverError_InvalidInputCopyWithImpl<$Res>
    implements $FrbSolverError_InvalidInputCopyWith<$Res> {
  _$FrbSolverError_InvalidInputCopyWithImpl(this._self, this._then);

  final FrbSolverError_InvalidInput _self;
  final $Res Function(FrbSolverError_InvalidInput) _then;

/// Create a copy of FrbSolverError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(FrbSolverError_InvalidInput(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class FrbSolverError_TimeLimitExceeded extends FrbSolverError {
  const FrbSolverError_TimeLimitExceeded(this.field0): super._();
  

@override final  double field0;

/// Create a copy of FrbSolverError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrbSolverError_TimeLimitExceededCopyWith<FrbSolverError_TimeLimitExceeded> get copyWith => _$FrbSolverError_TimeLimitExceededCopyWithImpl<FrbSolverError_TimeLimitExceeded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FrbSolverError_TimeLimitExceeded&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field0);
}

@override
String toString() {
    return 'FrbSolverError.timeLimitExceeded(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $FrbSolverError_TimeLimitExceededCopyWith<$Res> implements $FrbSolverErrorCopyWith<$Res> {
  factory $FrbSolverError_TimeLimitExceededCopyWith(FrbSolverError_TimeLimitExceeded value, $Res Function(FrbSolverError_TimeLimitExceeded) _then) = _$FrbSolverError_TimeLimitExceededCopyWithImpl;
@useResult
$Res call({
 double field0
});




}
/// @nodoc
class _$FrbSolverError_TimeLimitExceededCopyWithImpl<$Res>
    implements $FrbSolverError_TimeLimitExceededCopyWith<$Res> {
  _$FrbSolverError_TimeLimitExceededCopyWithImpl(this._self, this._then);

  final FrbSolverError_TimeLimitExceeded _self;
  final $Res Function(FrbSolverError_TimeLimitExceeded) _then;

/// Create a copy of FrbSolverError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(FrbSolverError_TimeLimitExceeded(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
