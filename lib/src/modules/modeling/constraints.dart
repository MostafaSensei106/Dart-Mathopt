import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../core/types.dart';
import 'ast/node.dart';

/// A single linear constraint: `expression (sense) rhs`.
///
/// Example: `x + 2 * y <= 5` produces
/// `Constraint(AddNode(...), ConstraintSense.lessThanOrEqual, 5.0)`.
@immutable
class Constraint extends Equatable {
  /// Creates a constraint of the form `expression (sense) rhs`.
  const Constraint(this.expression, this.sense, this.rhs, {this.name});

  /// Left-hand side expression.
  final ExpressionNode expression;

  /// The relation operator.
  final ConstraintSense sense;

  /// Right-hand side value (constants are folded here at compile time).
  final double rhs;

  /// Optional human-readable label for diagnostics.
  final String? name;

  /// Returns a copy with an optional human-readable [name].
  Constraint named(String name) =>
      Constraint(expression, sense, rhs, name: name);

  @override
  List<Object?> get props => [expression, sense, rhs, name];

  @override
  String toString() {
    final op = switch (sense) {
      ConstraintSense.lessThanOrEqual => '<=',
      ConstraintSense.greaterThanOrEqual => '>=',
      ConstraintSense.equal => '==',
    };
    final label = name == null ? '' : '$name: ';
    return '$label$expression $op $rhs';
  }
}

/// The optimization objective: an expression plus a sense.
@immutable
class Objective extends Equatable {
  /// Creates an optimization objective.
  const Objective(this.expression, this.sense);

  /// The objective expression.
  final ExpressionNode expression;

  /// Minimize or maximize.
  final OptimizationSense sense;

  @override
  List<Object?> get props => [expression, sense];
}
