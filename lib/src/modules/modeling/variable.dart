import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../core/exceptions.dart';
import '../../core/types.dart';
import 'ast/leaf_nodes.dart';
import 'ast/node.dart';
import 'constraints.dart';

/// A decision variable in a [MathOptModel].
///
/// Variables are allocated sequential integer IDs (0, 1, 2, ...) by the
/// model so the native solver can use fast array-based lookups instead
/// of hash maps. IDs must be dense and zero-based within a model.
///
/// This class is immutable. Use the model's factory methods
/// (`continuous`, `integer`, `binary`) to create instances.
@immutable
class Variable extends Equatable {
  /// Creates a decision variable (normally via the model factories).
  const Variable({
    required this.id,
    required this.name,
    required this.type,
    this.lowerBound,
    this.upperBound,
  });

  /// Zero-based sequential index within the owning model.
  final int id;

  /// Stable human-readable name (also used in diagnostics).
  final String name;

  /// Continuous, integer, or binary domain.
  final VariableType type;

  /// Lower bound, or `null` when unbounded below.
  final double? lowerBound;

  /// Upper bound, or `null` when unbounded above.
  final double? upperBound;

  /// This variable as an AST expression.
  ExpressionNode get asExpr => VariableNode(this);

  // -- Arithmetic passthroughs so users can write `x + y` directly. --
  //
  // Operands accept a [Variable], an [ExpressionNode], or a plain number
  // (`x + y`, `x - 2`). A leading number is impossible in Dart
  // (`2 + x` would use `num.operator +`), so expressions must start
  // from a variable or an expression: write `x * 3`, not `3 * x`.

  /// Sums a variable, expression, or number onto this variable.
  ExpressionNode operator +(Object other) => asExpr + _coerce(other);

  /// Subtracts a variable, expression, or number from this variable.
  ExpressionNode operator -(Object other) => asExpr - _coerce(other);

  /// Scales by a number (`x * 3`). Anything else throws immediately:
  /// products of variables are non-linear and unsupported.
  ExpressionNode operator *(Object other) {
    if (other is num) return asExpr * other;
    throw const ModelValidationException(
      'Non-linear multiplication is not supported yet.',
    );
  }

  /// Negates this variable.
  ExpressionNode operator -() => -asExpr;

  static ExpressionNode _coerce(Object other) => coerceOperand(other);

  /// Adds a plain number to this variable.
  ExpressionNode addNum(num value) => asExpr.addNum(value);

  /// Subtracts a plain number from this variable.
  ExpressionNode subNum(num value) => asExpr.subNum(value);

  // -- Constraint passthroughs so users can write `x + y <= 5`. --

  /// Builds a less-than-or-equal constraint against a plain number.
  Constraint operator <=(num rhs) => asExpr <= rhs;

  /// Builds a greater-than-or-equal constraint against a plain number.
  Constraint operator >=(num rhs) => asExpr >= rhs;

  /// Builds an equality constraint (`==` must return `bool` in Dart).
  Constraint eq(num rhs) => asExpr.eq(rhs);

  @override
  List<Object?> get props => [id, name, type, lowerBound, upperBound];

  @override
  String toString() => 'Variable($name#$id, $type)';
}
