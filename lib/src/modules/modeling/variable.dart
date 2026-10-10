import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

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
  /// Zero-based sequential index within the owning model.
  final int id;
  final String name;
  final VariableType type;
  final double? lowerBound;
  final double? upperBound;

  const Variable({
    required this.id,
    required this.name,
    required this.type,
    this.lowerBound,
    this.upperBound,
  });

  /// This variable as an AST expression.
  ExpressionNode get asExpr => VariableNode(this);

  // -- Arithmetic passthroughs so users can write `x + y` directly. --

  ExpressionNode operator +(ExpressionNode other) => asExpr + other;
  ExpressionNode operator -(ExpressionNode other) => asExpr - other;
  ExpressionNode operator *(num value) => asExpr * value;
  ExpressionNode operator -() => -asExpr;

  ExpressionNode addNum(num value) => asExpr.addNum(value);
  ExpressionNode subNum(num value) => asExpr.subNum(value);

  // -- Constraint passthroughs so users can write `x + y <= 5`. --

  Constraint operator <=(num rhs) => asExpr <= rhs;
  Constraint operator >=(num rhs) => asExpr >= rhs;
  Constraint eq(num rhs) => asExpr.eq(rhs);

  @override
  List<Object?> get props => [id, name, type, lowerBound, upperBound];

  @override
  String toString() => 'Variable($name#$id, $type)';
}
