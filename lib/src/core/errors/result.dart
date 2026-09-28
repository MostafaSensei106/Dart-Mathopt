import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

@freezed
sealed class Result<T, E> with _$Result<T, E> {
  const factory Result.success({required T data}) = Success<T, E>;
  const factory Result.failure({required E error}) = Failure<T, E>;

  static Future<Result<T, E>> tryCatching<T, E>({
    required Future<T> Function() action,
    required E Function(Object e, StackTrace st) onError,
  }) async {
    try {
      return Result.success(data: await action());
    } catch (e, st) {
      return Result.failure(error: onError(e, st));
    }
  }
}

extension ResultExtension<T, E> on Result<T, E> {
  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };

  E? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  T getOrElse(T Function(E error) fallback) => switch (this) {
    Success(:final data) => data,
    Failure(:final error) => fallback(error),
  };

  Result<T, NewError> mapError<NewError>(NewError Function(E error) mapper) =>
      switch (this) {
        Success(:final data) => Result.success(data: data),
        Failure(:final error) => Result.failure(error: mapper(error)),
      };
}
