import 'package:meta/meta.dart';

import '../../core/exceptions.dart';
import 'ast/arithmetic_nodes.dart';
import 'ast/leaf_nodes.dart';
import 'ast/node.dart';
import 'ast/visitor.dart';

/// Compiles an [ExpressionNode] AST into a flat linear form.
///
/// Output is a sparse representation:
/// - [terms]: variable ID -> accumulated coefficient.
/// - [constant]: accumulated constant offset.
///
/// The compiler is single-use per expression subtree in the sense that
/// [compile] accumulates into the same maps; create a fresh instance per
/// objective/constraint (as `MathOptModel.solve` does).
///
/// Linear-only: multiplying two non-constant expressions throws
/// [ModelValidationException]. Handles nesting such as `2 * (x + y)`
/// via a [_currentMultiplier] context.
@internal
class LinearExpressionCompiler implements ExpressionVisitor<void> {
  /// Variable ID -> accumulated coefficient.
  final Map<int, double> _terms = {};
  double _constant = 0.0;

  /// Current multiplier context for nested multiplications.
  double _currentMultiplier = 1.0;

  /// Traverses [node], accumulating terms and constants.
  void compile(ExpressionNode node) {
    node.accept(this);
  }

  /// Sparse terms: variable ID -> coefficient.
  Map<int, double> get terms => Map.unmodifiable(_terms);

  double get constant => _constant;

  /// Terms sorted by variable ID (deterministic DTO order).
  List<MapEntry<int, double>> get sortedTerms {
    final entries = _terms.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  @override
  void visitVariableNode(VariableNode node) {
    _terms[node.variable.id] =
        (_terms[node.variable.id] ?? 0.0) + _currentMultiplier;
  }

  @override
  void visitConstantNode(ConstantNode node) {
    _constant += node.value * _currentMultiplier;
  }

  @override
  void visitAddNode(AddNode node) {
    node.left.accept(this);
    node.right.accept(this);
  }

  @override
  void visitMultiplyNode(MultiplyNode node) {
    // Linear programming: at least one side must be (transitively) constant.
    final leftConst = _asConstant(node.operand);
    final rightConst = _asConstant(node.factor);

    if (leftConst == null && rightConst == null) {
      throw const ModelValidationException(
        'Non-linear multiplication is not supported yet.',
      );
    }
    if (leftConst != null && rightConst != null) {
      // const * const folds directly into the constant accumulator.
      _constant += leftConst * rightConst * _currentMultiplier;
      return;
    }
    final previous = _currentMultiplier;
    if (leftConst != null) {
      _currentMultiplier *= leftConst;
      try {
        node.factor.accept(this);
      } finally {
        _currentMultiplier = previous;
      }
    } else {
      _currentMultiplier *= rightConst!;
      try {
        node.operand.accept(this);
      } finally {
        _currentMultiplier = previous;
      }
    }
  }

  @override
  void visitNegateNode(NegateNode node) {
    final previous = _currentMultiplier;
    _currentMultiplier = -_currentMultiplier;
    try {
      node.operand.accept(this);
    } finally {
      _currentMultiplier = previous;
    }
  }

  /// Returns the constant value if [node] is (transitively) constant,
  /// otherwise `null`.
  ///
  /// Handles `ConstantNode`, `NegateNode(Constant)`, and
  /// `Add/Multiply` of constants without touching [_terms].
  double? _asConstant(ExpressionNode node) {
    const probe = _ConstProbe();
    try {
      return node.accept(probe);
    } on _NonConstant {
      return null;
    }
  }
}

class _NonConstant implements Exception {
  const _NonConstant();
}

/// Probe visitor that evaluates constant-only subtrees.
class _ConstProbe implements ExpressionVisitor<double> {
  const _ConstProbe();

  @override
  double visitVariableNode(VariableNode node) => throw const _NonConstant();

  @override
  double visitConstantNode(ConstantNode node) => node.value;

  @override
  double visitAddNode(AddNode node) =>
      node.left.accept(this) + node.right.accept(this);

  @override
  double visitMultiplyNode(MultiplyNode node) =>
      node.operand.accept(this) * node.factor.accept(this);

  @override
  double visitNegateNode(NegateNode node) => -node.operand.accept(this);
}
