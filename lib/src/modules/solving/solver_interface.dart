import 'package:meta/meta.dart';

import 'options.dart';
import 'results.dart';

/// Capabilities advertised by a solver backend.
@immutable
class SolverCapabilities {
  const SolverCapabilities({
    this.supportsMilp = false,
    this.supportsQp = false,
    this.supportsSocp = false,
  });
  final bool supportsMilp;
  final bool supportsQp;
  final bool supportsSocp;
}

/// Abstract solver interface (Dart side).
///
/// The default implementation dispatches to the Rust engines via FRB.
/// Custom implementations (e.g. fakes for tests) can implement this
/// interface directly.
abstract interface class SolverInterface {
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
  const SolverVariableDto({
    required this.id,
    required this.name,
    required this.varTypeIndex,
    this.lowerBound,
    this.upperBound,
  });
  final int id;
  final String name;
  final int varTypeIndex;
  final double? lowerBound;
  final double? upperBound;
}

@immutable
class SolverTermDto {
  const SolverTermDto({required this.variableId, required this.coefficient});
  final int variableId;
  final double coefficient;
}

@immutable
class SolverConstraintDto {
  const SolverConstraintDto({
    required this.name,
    required this.terms,
    required this.senseIndex,
    required this.rhs,
  });
  final String? name;
  final List<SolverTermDto> terms;
  final int senseIndex;
  final double rhs;
}

@immutable
class SolverObjectiveDto {
  const SolverObjectiveDto({
    required this.senseIndex,
    required this.terms,
    required this.constant,
  });
  final int senseIndex;
  final List<SolverTermDto> terms;
  final double constant;
}
