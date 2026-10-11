import 'package:meta/meta.dart';

import 'node.dart';
import 'visitor.dart';

/// Sum of two sub-expressions: `left + right`.
@immutable
class AddNode extends ExpressionNode {
  /// Creates a sum node.
  const AddNode(this.left, this.right);

  /// Left summand.
  final ExpressionNode left;

  /// Right summand.
  final ExpressionNode right;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.visitAddNode(this);

  @override
  List<Object?> get props => [left, right];
}

/// Product of an expression and a constant: `operand * factor`.
///
/// Only linear multiplication is supported: [factor] must be a constant
/// node. The [LinearExpressionCompiler] enforces this.
@immutable
class MultiplyNode extends ExpressionNode {
  /// Creates a product node (factor must be constant for LP).
  const MultiplyNode(this.operand, this.factor);

  /// The scaled sub-expression.
  final ExpressionNode operand;

  /// The constant factor (must be a constant node for LP).
  final ExpressionNode factor;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.visitMultiplyNode(this);

  @override
  List<Object?> get props => [operand, factor];
}

/// Negation of a sub-expression: `-operand`.
@immutable
class NegateNode extends ExpressionNode {
  /// Creates a negation node.
  const NegateNode(this.operand);

  /// The negated sub-expression.
  final ExpressionNode operand;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.visitNegateNode(this);

  @override
  List<Object?> get props => [operand];
}
