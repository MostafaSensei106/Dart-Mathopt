import 'package:meta/meta.dart';

import 'modules/solving/options.dart';

/// Global runtime configuration for `dart_mathopt`.
///
/// Passed once to [DartMathOpt.init] (see `math_opt.dart`). Per-call
/// [SolveOptions] always win over these defaults: the effective options
/// for a `solve()` are `call-options ?? global-config` field by field.
///
/// The Rust engines receive the *effective* options inside every
/// `FrbSolveRequest`, so this config steers native behavior without
/// changing the FFI surface (no bridge regeneration needed to add
/// fields here — they are resolved Dart-side before crossing).
@immutable
class MathOptConfig {
  /// Creates a global config; every field is optional.
  const MathOptConfig({
    this.defaultSolver = SolverPreference.auto,
    this.defaultTimeLimitSec,
    this.defaultThreadCount,
    this.enableLogging = false,
    this.libraryPath,
    this.engineTuning = const {},
  });

  /// Big sparse LPs (factory/transport at scale): all cores, no logging.
  factory MathOptConfig.fastLp({int? threadCount}) => MathOptConfig(
        defaultSolver: SolverPreference.highs,
        defaultThreadCount: threadCount,
      );

  /// MILP shapes (assignment/knapsack/scheduling): generous time budget.
  factory MathOptConfig.accurateMilp({double timeLimitSec = 120}) =>
      MathOptConfig(
        defaultSolver: SolverPreference.highs,
        defaultTimeLimitSec: timeLimitSec,
      );

  /// Constrained devices / embedded: single thread, quiet.
  factory MathOptConfig.lowMemory() => const MathOptConfig(
        defaultSolver: SolverPreference.highs,
        defaultThreadCount: 1,
      );

  /// Debugging: native logs on, short limit so hangs surface fast.
  factory MathOptConfig.verbose({double timeLimitSec = 30}) =>
      MathOptConfig(defaultTimeLimitSec: timeLimitSec, enableLogging: true);

  /// Default backend when a solve call passes `solver: auto` (or null).
  final SolverPreference defaultSolver;

  /// Default wall-clock limit in seconds. `null` = no limit.
  final double? defaultTimeLimitSec;

  /// Default thread count for native engines. `null` = engine decides.
  final int? defaultThreadCount;

  /// Default native stdout logging (HiGHS `output_flag` / Clarabel verbose).
  final bool enableLogging;

  /// Explicit path to the native library (`.so`/`.dylib`/`.dll`).
  /// `null` = auto-resolve (default loader, then `rust/target/release`).
  final String? libraryPath;

  /// Engine-specific tuning knobs (e.g. `{'highs_presolve': 'on'}`).
  /// Reserved for future engine adapters; ignored when unknown.
  final Map<String, String> engineTuning;

  // -- Presets for the known use-cases (see example catalog) --

  /// General default: auto routing, engine-chosen threads.
  static const MathOptConfig balanced = MathOptConfig();

  /// Derives a variant; function-wrapped nullables can clear a default.
  MathOptConfig copyWith({
    SolverPreference? defaultSolver,
    double? Function()? defaultTimeLimitSec,
    int? Function()? defaultThreadCount,
    bool? enableLogging,
    String? Function()? libraryPath,
    Map<String, String>? engineTuning,
  }) {
    return MathOptConfig(
      defaultSolver: defaultSolver ?? this.defaultSolver,
      defaultTimeLimitSec: defaultTimeLimitSec != null
          ? defaultTimeLimitSec()
          : this.defaultTimeLimitSec,
      defaultThreadCount: defaultThreadCount != null
          ? defaultThreadCount()
          : this.defaultThreadCount,
      enableLogging: enableLogging ?? this.enableLogging,
      libraryPath: libraryPath != null ? libraryPath() : this.libraryPath,
      engineTuning: engineTuning ?? this.engineTuning,
    );
  }

  /// Resolves the effective per-solve options: every non-null field of
  /// [call] wins, otherwise the global default applies.
  SolveOptions resolve(SolveOptions? call) {
    call ??= const SolveOptions();
    final solver =
        call.solver == SolverPreference.auto ? defaultSolver : call.solver;
    return SolveOptions(
      timeLimitSec: call.timeLimitSec ?? defaultTimeLimitSec,
      enableLogging: call.enableLogging || enableLogging,
      threadCount: call.threadCount ?? defaultThreadCount,
      solver: solver,
    );
  }

  @override
  String toString() =>
      'MathOptConfig(solver: $defaultSolver, timeLimitSec: $defaultTimeLimitSec, '
      'threads: $defaultThreadCount, logging: $enableLogging)';
}
