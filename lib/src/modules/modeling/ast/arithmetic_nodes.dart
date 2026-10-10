import 'package:meta/meta.dart';

import 'node.dart';
import 'visitor.dart';

/// Sum of two sub-expressions: `left + right`.
@immutable
class AddNode extends ExpressionNode {
  final ExpressionNode left;
  final ExpressionNode right;
  const AddNode(this.left, this.right);

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
  final ExpressionNode operand;
  final ExpressionNode factor;
  const MultiplyNode(this.operand, this.factor);

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.visitMultiplyNode(this);

  @override
  List<Object?> get props => [operand, factor];
}

/// Negation of a sub-expression: `-operand`.
@immutable
class NegateNode extends ExpressionNode {
  final ExpressionNode operand;
  const NegateNode(this.operand);

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.visitNegateNode(this);

  @override
  List<Object?> get props => [operand];
}
