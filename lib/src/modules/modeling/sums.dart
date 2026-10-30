import 'package:meta/meta.dart';

import 'ast/leaf_nodes.dart';
import 'ast/node.dart';
import 'variable.dart';

/// Vectorized expression builders.
///
/// Hand-written accumulation loops (`for (...) { total += ...; }`) build
/// left-deep `Add` chains: O(n) nodes at O(n) depth, which risks stack
/// overflow in the compiler past ~10k terms and litters call sites with
/// nested loops for 2-D shapes. These builders fold with a balanced tree
/// (depth O(log n)) and collapse one loop level per call.
@immutable
abstract final class Expr {
  /// Balanced sum of [terms] (empty folds to constant `0`).
  static ExpressionNode sum(Iterable<ExpressionNode> terms) {
    final list = terms.toList(growable: false);
    if (list.isEmpty) return const ConstantNode(0);
    return _balanced(list, 0, list.length);
  }

  /// Sum of variables: `vars.sum` without spelling `.asExpr` per element.
  static ExpressionNode sumVars(Iterable<Variable> vars) =>
      sum(vars.map((v) => v.asExpr));

  /// Dot product Σ `coefs[v] * v` (+ optional [constant]).
  static ExpressionNode dot(
    Map<Variable, double> coefs, [
    double constant = 0,
  ]) {
    if (coefs.isEmpty) return ConstantNode(constant);
    final scaled = coefs.entries
        .map((e) => e.value == 1.0 ? e.key.asExpr : e.key.asExpr * e.value)
        .toList(growable: false);
    final total = sum(scaled);
    return constant == 0 ? total : total + constant.expr;
  }

  /// Dot product over parallel lists (`vars[i] * coefs[i]`).
  static ExpressionNode dotLists(
    List<Variable> vars,
    List<double> coefs, [
    double constant = 0,
  ]) {
    if (vars.length != coefs.length) {
      throw ArgumentError(
        'vars (${vars.length}) and coefs (${coefs.length}) differ in length.',
      );
    }
    return dot({
      for (var i = 0; i < vars.length; i++) vars[i]: coefs[i],
    }, constant);
  }

  static ExpressionNode _balanced(List<ExpressionNode> list, int lo, int hi) {
    if (hi - lo == 1) return list[lo];
    final mid = lo + ((hi - lo) >> 1);
    return _balanced(list, lo, mid) + _balanced(list, mid, hi);
  }
}

/// `expressions.sum`  balanced fold, see [Expr.sum].
extension ExpressionSumX on Iterable<ExpressionNode> {
  /// Balanced sum of all elements (empty folds to constant `0`).
  ExpressionNode get sum => Expr.sum(this);
}

/// `variables.sum`  see [Expr.sumVars].
extension VariableSumX on Iterable<Variable> {
  /// Balanced sum of all variables.
  ExpressionNode get sum => Expr.sumVars(this);
}
