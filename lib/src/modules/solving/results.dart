import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../core/exceptions.dart';
import '../modeling/variable.dart';

/// High-level solve status surfaced to Dart callers.
enum SolveStatus {
  /// The engine proved optimality; values are usable.
  optimal,

  /// No point satisfies all constraints; no usable primal exists.
  infeasible,

  /// The objective improves without bound; no usable primal exists.
  unbounded,

  /// The time limit hit first; an incumbent may exist (see `hasSolution`).
  timeLimitExceeded,

  /// The engine failed numerically; values are unreliable.
  numericalError,

  /// Termination state the bridge could not classify.
  unknown,
}

/// Timing/iteration statistics for a solve call.
@immutable
class SolveStatistics {
  /// Creates statistics; every field is optional.
  const SolveStatistics({
    this.solveTimeMs = 0,
    this.solveTimeUs = 0,
    this.iterations = 0,
  });

  /// Engine-reported solve time, millisecond resolution.
  final int solveTimeMs;

  /// Engine-reported solve time, microsecond resolution: exact for
  /// sub-millisecond solves that report `0` in [solveTimeMs].
  final int solveTimeUs;

  /// Native solver iteration count (`0` when the engine hides it).
  final int iterations;

  @override
  String toString() =>
      'SolveStatistics(solveTimeUs: $solveTimeUs, iterations: $iterations)';
}

/// The result of a successful `MathOptModel.solve()` call.
@immutable
class SolveResult {
  /// Creates a solve result; see the field docs for per-status validity.
  const SolveResult({
    required this.status,
    required this.objectiveValue,
    required this.variableValues,
    required this.dualValues,
    required this.statistics,
  });

  /// Termination status; consult it before trusting any other field.
  final SolveStatus status;

  /// Objective value reported by the engine (`null` if unavailable,
  /// e.g. infeasible models).
  final double? objectiveValue;

  /// Maps each model variable to its primal solution value.
  final Map<Variable, double> variableValues;

  /// Dual values per constraint (only for pure LP; `null` for MILP).
  final List<double>? dualValues;

  /// Timing/iteration statistics for this solve.
  final SolveStatistics statistics;

  /// Solution value for [variable].
  ///
  /// Returns `double.nan` when the variable has no value (e.g. the solve
  /// failed before producing primals). Prefer [tryValueOf] when a missing
  /// value must be told apart from a real zero.
  double valueOf(Variable variable) => variableValues[variable] ?? double.nan;

  /// Solution value for [variable], or `null` when absent.
  double? tryValueOf(Variable variable) => variableValues[variable];

  /// Whether the engine returned a usable primal solution.
  ///
  /// Data-driven, not status-only: `optimal` always qualifies;
  /// `timeLimitExceeded` qualifies when every reported value is finite
  /// (an incumbent); every other status means no usable solution, even
  /// if the engine returned numbers.
  bool get hasSolution => switch (status) {
        SolveStatus.optimal => true,
        SolveStatus.timeLimitExceeded => variableValues.values.every(
            (v) => v.isFinite,
          ),
        _ => false,
      };

  /// Returns the usable solution, or throws [SolverExecutionException]
  /// when none is available.
  ///
  /// This guarantees availability, not quality: an incumbent from a
  /// time limit is returned as-is. Check [Solution.isOptimal] (or
  /// [status]) before claiming optimality.
  Solution requireSolution() {
    if (!hasSolution) {
      throw SolverExecutionException(
        'No usable solution available (status: $status).',
        -3,
      );
    }
    return Solution(
      objectiveValue: objectiveValue,
      variableValues: Map.unmodifiable(variableValues),
      dualValues: dualValues == null ? null : List.unmodifiable(dualValues!),
      statistics: statistics,
      status: status,
      isOptimal: isOptimal,
    );
  }

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

/// A usable primal solution extracted from a [SolveResult].
///
/// Obtained via [SolveResult.requireSolution], which guarantees
/// availability but not quality: check [isOptimal] (or [status]) before
/// claiming the engine proved optimality. `objectiveValue` is null when
/// the engine reported none (possible for some time-limit incumbents).
@immutable
class Solution {
  /// Creates a usable-solution view; prefer [SolveResult.requireSolution].
  const Solution({
    required this.objectiveValue,
    required this.variableValues,
    required this.dualValues,
    required this.statistics,
    required this.status,
    required this.isOptimal,
  });

  /// Objective value, or `null` when the engine reported none.
  final double? objectiveValue;

  /// Primal values by variable.
  final Map<Variable, double> variableValues;

  /// Dual values, or `null` when unavailable (e.g. MILP).
  final List<double>? dualValues;

  /// Timing/iteration statistics for the originating solve.
  final SolveStatistics statistics;

  /// Termination status of the originating solve.
  final SolveStatus status;

  /// Whether the engine proved optimality (else this is an incumbent).
  final bool isOptimal;

  /// Value for [variable], or `double.nan` when absent.
  double valueOf(Variable variable) => variableValues[variable] ?? double.nan;

  /// Value for [variable], or `null` when absent.
  double? tryValueOf(Variable variable) => variableValues[variable];

  @override
  String toString() =>
      'Solution(status: $status, objectiveValue: $objectiveValue)';
}
