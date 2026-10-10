import 'package:meta/meta.dart';

/// Base class for all exceptions thrown by `dart_mathopt`.
@immutable
abstract class MathOptException implements Exception {
  final String message;
  const MathOptException(this.message);

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
  final int errorCode;
  const SolverExecutionException(super.message, this.errorCode);
}

/// Thrown if the solve operation exceeds the time limit.
@immutable
class SolverTimeoutException extends MathOptException {
  final Duration timeLimit;
  const SolverTimeoutException(this.timeLimit)
    : super('Solver timed out after $timeLimit');
}
