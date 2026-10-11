import '../../core/exceptions.dart';
import '../../core/types.dart';
import 'constraints.dart';
import 'sums.dart';
import 'variable.dart';

/// Logical choice helpers over binary variables.
///
/// Each returns a plain [Constraint] through the same expression path as
/// hand-written models (balanced sum, standard compile, standard engine
/// capability checks) — no alternate constraint pipeline:
///
/// - [exactlyOne]: Σ vars = 1.
/// - [atMostOne]: Σ vars ≤ 1.
/// - [atLeastOne]: Σ vars ≥ 1.
///
/// Inputs must be non-empty and all binary; violations throw
/// [ModelValidationException] naming the offenders.
Constraint exactlyOne(Iterable<Variable> vars, {String? name}) =>
    _choice(vars, ConstraintSense.equal, 1, 'exactlyOne', name);

/// Builds a Σ vars ≤ 1 constraint (at most one binary variable is 1).
Constraint atMostOne(Iterable<Variable> vars, {String? name}) =>
    _choice(vars, ConstraintSense.lessThanOrEqual, 1, 'atMostOne', name);

/// Builds a Σ vars ≥ 1 constraint (at least one binary variable is 1).
Constraint atLeastOne(Iterable<Variable> vars, {String? name}) =>
    _choice(vars, ConstraintSense.greaterThanOrEqual, 1, 'atLeastOne', name);

Constraint _choice(
  Iterable<Variable> vars,
  ConstraintSense sense,
  double rhs,
  String kind,
  String? name,
) {
  final list = vars.toList(growable: false);
  if (list.isEmpty) {
    throw ModelValidationException('$kind requires at least one variable.');
  }
  final offenders = [
    for (final v in list)
      if (v.type != VariableType.binary) v.name,
  ];
  if (offenders.isNotEmpty) {
    throw ModelValidationException(
      '$kind requires binary variables; not binary: ${offenders.join(', ')}.',
    );
  }
  return Constraint(Expr.sumVars(list), sense, rhs, name: name);
}
