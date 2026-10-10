import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../modeling/variable.dart';

/// High-level solve status surfaced to Dart callers.
enum SolveStatus {
  optimal,
  infeasible,
  unbounded,
  timeLimitExceeded,
  numericalError,
  unknown,
}

/// Timing/iteration statistics for a solve call.
@immutable
class SolveStatistics {
  final int solveTimeMs;
  final int iterations;

  const SolveStatistics({this.solveTimeMs = 0, this.iterations = 0});

  @override
  String toString() =>
      'SolveStatistics(solveTimeMs: $solveTimeMs, iterations: $iterations)';
}

/// The result of a successful `MathOptModel.solve()` call.
@immutable
class SolveResult {
  final SolveStatus status;

  /// Objective value reported by the engine (`null` if unavailable,
  /// e.g. infeasible models).
  final double? objectiveValue;

  /// Maps each model variable to its primal solution value.
  final Map<Variable, double> variableValues;

  /// Dual values per constraint (only for pure LP; `null` for MILP).
  final List<double>? dualValues;

  final SolveStatistics statistics;

  const SolveResult({
    required this.status,
    required this.objectiveValue,
    required this.variableValues,
    required this.dualValues,
    required this.statistics,
  });

  /// Solution value for [variable].
  double valueOf(Variable variable) => variableValues[variable] ?? double.nan;

  /// `true` when the solver proved optimality.
  bool get isOptimal => status == SolveStatus.optimal;

  @override
  String toString() =>
      'SolveResult(status: $status, objectiveValue: $objectiveValue, '
      'statistics: $statistics)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SolveResult &&
        other.status == status &&
        other.objectiveValue == objectiveValue &&
        const MapEquality<Variable, double>().equals(
          other.variableValues,
          variableValues,
        );
  }

  @override
  int get hashCode => Object.hash(status, objectiveValue, statistics);
}
