import 'package:meta/meta.dart';

import 'options.dart';
import 'results.dart';

/// Capabilities advertised by a solver backend.
@immutable
class SolverCapabilities {
  /// Declares support flags; all default to unsupported.
  const SolverCapabilities({
    this.supportsMilp = false,
    this.supportsQp = false,
    this.supportsSocp = false,
  });

  /// Whether integer/binary variables are accepted.
  final bool supportsMilp;

  /// Whether quadratic objectives are accepted.
  final bool supportsQp;

  /// Whether second-order cone constraints are accepted.
  final bool supportsSocp;
}

/// Abstract solver interface (Dart side).
///
/// The default implementation dispatches to the Rust engines via FRB.
/// Custom implementations (e.g. fakes for tests) can implement this
/// interface directly.
abstract interface class SolverInterface {
  /// Capability flags used for pre-dispatch validation.
  SolverCapabilities get capabilities;

  /// Solves the already-compiled request and returns a domain result.
  Future<SolveResult> solve({
    required List<SolverVariableDto> variables,
    required List<SolverConstraintDto> constraints,
    required SolverObjectiveDto objective,
    SolveOptions? options,
  });
}

/// Minimal engine-agnostic DTOs used by [SolverInterface].
///
/// These mirror the FRB DTOs but keep the interface decoupled from the
/// generated bridge code.
@immutable
class SolverVariableDto {
  /// Creates an engine-agnostic variable description.
  const SolverVariableDto({
    required this.id,
    required this.name,
    required this.varTypeIndex,
    this.lowerBound,
    this.upperBound,
  });

  /// Dense zero-based id matching the model order.
  final int id;

  /// Stable human-readable name.
  final String name;

  /// `VariableType` index (avoids importing the modeling layer here).
  final int varTypeIndex;

  /// Lower bound, or `null` when unbounded below.
  final double? lowerBound;

  /// Upper bound, or `null` when unbounded above.
  final double? upperBound;
}

/// Sparse linear term used by [SolverInterface].
@immutable
class SolverTermDto {
  /// Creates one sparse term (`coefficient * variableId`).
  const SolverTermDto({required this.variableId, required this.coefficient});

  /// Referenced variable id.
  final int variableId;

  /// Linear coefficient.
  final double coefficient;
}

/// Engine-agnostic constraint used by [SolverInterface].
@immutable
class SolverConstraintDto {
  /// Creates an engine-agnostic constraint description.
  const SolverConstraintDto({
    required this.name,
    required this.terms,
    required this.senseIndex,
    required this.rhs,
  });

  /// Optional label for diagnostics.
  final String? name;

  /// Sparse left-hand-side terms.
  final List<SolverTermDto> terms;

  /// `ConstraintSense` index.
  final int senseIndex;

  /// Right-hand side with constants already folded in.
  final double rhs;
}

/// Engine-agnostic objective used by [SolverInterface].
@immutable
class SolverObjectiveDto {
  /// Creates an engine-agnostic objective description.
  const SolverObjectiveDto({
    required this.senseIndex,
    required this.terms,
    required this.constant,
  });

  /// `OptimizationSense` index.
  final int senseIndex;

  /// Sparse linear terms.
  final List<SolverTermDto> terms;

  /// Constant offset added back after the solve.
  final double constant;
}
