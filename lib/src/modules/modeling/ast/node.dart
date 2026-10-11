import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../core/exceptions.dart';
import '../../../core/types.dart';
import '../constraints.dart';
import '../variable.dart';
import 'arithmetic_nodes.dart';
import 'leaf_nodes.dart';
import 'visitor.dart';

/// Base class for all nodes in the mathematical expression AST.
///
/// Nodes are immutable. Operator overloads create new nodes and never
/// mutate existing ones.
@immutable
@sealed
abstract class ExpressionNode extends Equatable {
  /// Base constructor for immutable expression nodes.
  const ExpressionNode();

  /// Accepts a visitor to traverse the AST.
  R accept<R>(ExpressionVisitor<R> visitor);

  // -- Arithmetic builders (create new nodes, never mutate) --
  //
  // Like [Variable], operands accept expressions, variables (via
  // `.asExpr`), or plain numbers. Scaling takes a trailing number
  // (`expr * 3`); anything else is a non-linear product and throws.

  /// Sums two operands (expressions, variables, or numbers).
  ExpressionNode operator +(Object other) =>
      AddNode(this, coerceOperand(other));

  /// Subtracts the operand (expressions, variables, or numbers).
  ExpressionNode operator -(Object other) =>
      AddNode(this, NegateNode(coerceOperand(other)));

  /// Scales by a trailing number (`expr * 3`); anything else throws
  /// [ModelValidationException] as a non-linear product.
  ExpressionNode operator *(Object other) {
    if (other is num) {
      return MultiplyNode(this, ConstantNode(other.toDouble()));
    }
    throw const ModelValidationException(
      'Non-linear multiplication is not supported yet.',
    );
  }

  /// Negates this expression.
  ExpressionNode operator -() => NegateNode(this);

  /// Adds a plain number to this expression.
  ExpressionNode addNum(num value) =>
      AddNode(this, ConstantNode(value.toDouble()));

  /// Subtracts a plain number from this expression.
  ExpressionNode subNum(num value) =>
      AddNode(this, NegateNode(ConstantNode(value.toDouble())));

  // -- Constraint builders --

  /// Builds a less-than-or-equal constraint against a plain number.
  Constraint operator <=(num rhs) =>
      Constraint(this, ConstraintSense.lessThanOrEqual, rhs.toDouble());

  /// Builds a greater-than-or-equal constraint against a plain number.
  Constraint operator >=(num rhs) =>
      Constraint(this, ConstraintSense.greaterThanOrEqual, rhs.toDouble());

  /// Equality constraint builder (`==` must return `bool` in Dart,
  /// so equality uses a named method instead).
  Constraint eq(num rhs) =>
      Constraint(this, ConstraintSense.equal, rhs.toDouble());
}

/// Convenience conversion for building expressions from literals.
///
/// Example: `x * 2 + 1.expr`.
///
/// NOTE: Dart resolves `num`'s own `+`/`-`/`*` before extensions, so
/// literal-first forms like `2 * x` are NOT supported. Always put the
/// expression first: `x * 2`.
extension NumExpressionExtension on num {
  /// Wraps this number as a constant AST node.
  ConstantNode get expr => ConstantNode(toDouble());
}

/// Coerces a mixed arithmetic operand to an [ExpressionNode].
///
/// Accepts expressions, variables (via `.asExpr`), and plain numbers
/// (as constants). Anything else throws [ModelValidationException].
/// Used by the `+`/`-` overloads on [ExpressionNode] and `Variable`.
ExpressionNode coerceOperand(Object other) => switch (other) {
      final ExpressionNode e => e,
      final Variable v => v.asExpr,
      final num n => ConstantNode(n.toDouble()),
      _ => throw ModelValidationException(
          'Cannot use ${other.runtimeType} in an expression.',
        ),
    };
