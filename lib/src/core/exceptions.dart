import 'package:meta/meta.dart';

/// Base class for all exceptions thrown by `dart_mathopt`.
@immutable
abstract class MathOptException implements Exception {
  /// Creates an exception with the given [message].
  const MathOptException(this.message);

  /// Human-readable failure description.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the user builds an invalid mathematical model.
@immutable
class ModelValidationException extends MathOptException {
  /// Creates a model-validation failure.
  const ModelValidationException(super.message);
}

/// Thrown when the underlying Rust engine fails.
@immutable
class SolverExecutionException extends MathOptException {
  /// Creates an engine failure with a native [errorCode].
  const SolverExecutionException(super.message, this.errorCode);

  /// Native error code (`-3` = no usable solution, others engine-defined).
  final int errorCode;
}

/// Thrown if the solve operation exceeds the time limit.
@immutable
class SolverTimeoutException extends MathOptException {
  /// Creates a time-limit failure for the given [timeLimit].
  const SolverTimeoutException(this.timeLimit)
      : super('Solver timed out after $timeLimit');

  /// The limit that was exceeded.
  final Duration timeLimit;
}
