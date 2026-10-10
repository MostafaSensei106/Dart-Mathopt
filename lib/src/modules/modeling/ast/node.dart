import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../core/types.dart';
import '../constraints.dart';
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
  const ExpressionNode();

  /// Accepts a visitor to traverse the AST.
  R accept<R>(ExpressionVisitor<R> visitor);

  // -- Arithmetic builders (create new nodes, never mutate) --

  ExpressionNode operator +(ExpressionNode other) => AddNode(this, other);

  ExpressionNode operator -(ExpressionNode other) =>
      AddNode(this, NegateNode(other));

  ExpressionNode operator *(num value) =>
      MultiplyNode(this, ConstantNode(value.toDouble()));

  ExpressionNode operator -() => NegateNode(this);

  /// Adds a plain number to this expression.
  ExpressionNode addNum(num value) =>
      AddNode(this, ConstantNode(value.toDouble()));

  /// Subtracts a plain number from this expression.
  ExpressionNode subNum(num value) =>
      AddNode(this, NegateNode(ConstantNode(value.toDouble())));

  // -- Constraint builders --

  Constraint operator <=(num rhs) =>
      Constraint(this, ConstraintSense.lessThanOrEqual, rhs.toDouble());

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
