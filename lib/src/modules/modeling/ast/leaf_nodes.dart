import 'package:meta/meta.dart';

import '../variable.dart';
import 'node.dart';
import 'visitor.dart';

/// A leaf node referencing a decision variable.
@immutable
class VariableNode extends ExpressionNode {
  final Variable variable;
  const VariableNode(this.variable);

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.visitVariableNode(this);

  @override
  List<Object?> get props => [variable];
}

/// A leaf node holding a constant value.
@immutable
class ConstantNode extends ExpressionNode {
  final double value;
  const ConstantNode(this.value);

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.visitConstantNode(this);

  @override
  List<Object?> get props => [value];
}
