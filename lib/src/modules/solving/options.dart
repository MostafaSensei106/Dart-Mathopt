import 'package:meta/meta.dart';

/// Preferred backend engine for a solve call.
enum SolverPreference {
  /// Let the Rust router pick (integer/QP presence decides).
  auto,

  /// Force the HiGHS LP/MILP engine.
  highs,

  /// Force the Clarabel LP/QP/SOCP engine.
  clarabel,

  /// Force the MicroLP pure-Rust LP engine (via good_lp, no C++).
  microlp,
}

/// Options controlling a single `solve()` call.
///
/// Immutable value object; use [copyWith] to derive variants.
@immutable
class SolveOptions {
  const SolveOptions({
    this.timeLimitSec,
    this.enableLogging = false,
    this.threadCount,
    this.solver = SolverPreference.auto,
  });

  /// Wall-clock limit in seconds. `null` means no limit.
  final double? timeLimitSec;

  /// Forward native solver stdout logging (HiGHS `output_flag`).
  final bool enableLogging;

  /// Number of threads for the native solver. `null` lets the
  /// engine decide.
  final int? threadCount;

  /// Which backend engine to use.
  final SolverPreference solver;

  SolveOptions copyWith({
    double? timeLimitSec,
    bool? enableLogging,
    int? threadCount,
    SolverPreference? solver,
  }) {
    return SolveOptions(
      timeLimitSec: timeLimitSec ?? this.timeLimitSec,
      enableLogging: enableLogging ?? this.enableLogging,
      threadCount: threadCount ?? this.threadCount,
      solver: solver ?? this.solver,
    );
  }

  @override
  String toString() =>
      'SolveOptions(timeLimitSec: $timeLimitSec, enableLogging: $enableLogging, '
      'threadCount: $threadCount, solver: $solver)';
}
