import 'package:meta/meta.dart';

import 'arithmetic_nodes.dart';
import 'leaf_nodes.dart';

/// Visitor for traversing the expression AST.
///
/// Each concrete node type has its own visit method so compilers and
/// analyzers can be added without modifying the node classes.
@internal
abstract interface class ExpressionVisitor<R> {
  R visitVariableNode(VariableNode node);
  R visitConstantNode(ConstantNode node);
  R visitAddNode(AddNode node);
  R visitMultiplyNode(MultiplyNode node);
  R visitNegateNode(NegateNode node);
}
