// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pare_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PareResult<T> {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PareResult<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PareResult<$T>()';
}


}

/// @nodoc
class $PareResultCopyWith<T,$Res>  {
$PareResultCopyWith(PareResult<T> _, $Res Function(PareResult<T>) __);
}


/// Adds pattern-matching-related methods to [PareResult].
extension PareResultPatterns<T> on PareResult<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PareResultSuccess<T> value)?  success,TResult Function( PareResultFailure<T> value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PareResultSuccess() when success != null:
return success(_that);case PareResultFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PareResultSuccess<T> value)  success,required TResult Function( PareResultFailure<T> value)  failure,}){
final _that = this;
switch (_that) {
case PareResultSuccess():
return success(_that);case PareResultFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PareResultSuccess<T> value)?  success,TResult? Function( PareResultFailure<T> value)?  failure,}){
final _that = this;
switch (_that) {
case PareResultSuccess() when success != null:
return success(_that);case PareResultFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( T data)?  success,TResult Function( PareException error)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PareResultSuccess() when success != null:
return success(_that.data);case PareResultFailure() when failure != null:
return failure(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( T data)  success,required TResult Function( PareException error)  failure,}) {final _that = this;
switch (_that) {
case PareResultSuccess():
return success(_that.data);case PareResultFailure():
return failure(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( T data)?  success,TResult? Function( PareException error)?  failure,}) {final _that = this;
switch (_that) {
case PareResultSuccess() when success != null:
return success(_that.data);case PareResultFailure() when failure != null:
return failure(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class PareResultSuccess<T> extends PareResult<T> {
  const PareResultSuccess(this.data): super._();
  

 final  T data;

/// Create a copy of PareResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PareResultSuccessCopyWith<T, PareResultSuccess<T>> get copyWith => _$PareResultSuccessCopyWithImpl<T, PareResultSuccess<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PareResultSuccess<T>&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'PareResult<$T>.success(data: $data)';
}


}

/// @nodoc
abstract mixin class $PareResultSuccessCopyWith<T,$Res> implements $PareResultCopyWith<T, $Res> {
  factory $PareResultSuccessCopyWith(PareResultSuccess<T> value, $Res Function(PareResultSuccess<T>) _then) = _$PareResultSuccessCopyWithImpl;
@useResult
$Res call({
 T data
});




}
/// @nodoc
class _$PareResultSuccessCopyWithImpl<T,$Res>
    implements $PareResultSuccessCopyWith<T, $Res> {
  _$PareResultSuccessCopyWithImpl(this._self, this._then);

  final PareResultSuccess<T> _self;
  final $Res Function(PareResultSuccess<T>) _then;

/// Create a copy of PareResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = freezed,}) {
  return _then(PareResultSuccess<T>(
freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class PareResultFailure<T> extends PareResult<T> {
  const PareResultFailure(this.error): super._();
  

 final  PareException error;

/// Create a copy of PareResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PareResultFailureCopyWith<T, PareResultFailure<T>> get copyWith => _$PareResultFailureCopyWithImpl<T, PareResultFailure<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PareResultFailure<T>&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'PareResult<$T>.failure(error: $error)';
}


}

/// @nodoc
abstract mixin class $PareResultFailureCopyWith<T,$Res> implements $PareResultCopyWith<T, $Res> {
  factory $PareResultFailureCopyWith(PareResultFailure<T> value, $Res Function(PareResultFailure<T>) _then) = _$PareResultFailureCopyWithImpl;
@useResult
$Res call({
 PareException error
});




}
/// @nodoc
class _$PareResultFailureCopyWithImpl<T,$Res>
    implements $PareResultFailureCopyWith<T, $Res> {
  _$PareResultFailureCopyWithImpl(this._self, this._then);

  final PareResultFailure<T> _self;
  final $Res Function(PareResultFailure<T>) _then;

/// Create a copy of PareResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(PareResultFailure<T>(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as PareException,
  ));
}


}

// dart format on
