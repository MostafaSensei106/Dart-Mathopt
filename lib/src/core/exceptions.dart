import 'package:meta/meta.dart';

/// Base class for all exceptions thrown by `dart_mathopt`.
@immutable
abstract class MathOptException implements Exception {
  const MathOptException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the user builds an invalid mathematical model.
@immutable
class ModelValidationException extends MathOptException {
  const ModelValidationException(super.message);
}

/// Thrown when the underlying Rust engine fails.
@immutable
class SolverExecutionException extends MathOptException {
  const SolverExecutionException(super.message, this.errorCode);
  final int errorCode;
}

/// Thrown if the solve operation exceeds the time limit.
@immutable
class SolverTimeoutException extends MathOptException {
  const SolverTimeoutException(this.timeLimit)
    : super('Solver timed out after $timeLimit');
  final Duration timeLimit;
}
