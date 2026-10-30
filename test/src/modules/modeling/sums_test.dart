import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:dart_mathopt/src/modules/modeling/compiler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

/// Vectorized builders: balanced sums, dot products, batch constraints.
/// Pure Dart  no native library needed.
void main() {
  setUpAll(ensureNativeInit);

  Map<int, double> compile(ExpressionNode e) =>
      (LinearExpressionCompiler()..compile(e)).terms;

  double constantOf(ExpressionNode e) =>
      (LinearExpressionCompiler()..compile(e)).constant;

  group('Expr.sum', () {
    test('empty folds to constant zero', () {
      expect(constantOf(Expr.sum(const [])), 0.0);
    });

    test('single term returns it unchanged', () {
      final model = MathOptModel(name: 'Sum');
      final x = model.continuous('x');
      expect(compile([x.asExpr].sum), {x.id: 1.0});
    });

    test('matches naive accumulation exactly', () {
      final model = MathOptModel(name: 'Sum');
      final vars = [for (var i = 0; i < 50; i++) model.continuous('v$i')];
      ExpressionNode naive = const ConstantNode(0);
      for (final v in vars) {
        naive += v.asExpr;
      }
      final fast = vars.sum;
      expect(compile(fast), compile(naive));
    });

    test('balanced tree stays shallow at 4096 terms', () {
      final model = MathOptModel(name: 'Deep');
      final vars = [for (var i = 0; i < 4096; i++) model.continuous('v$i')];
      final tree = vars.sum;
      var depth = 0;
      var node = tree;
      // Left spine length bounds the depth from above for a balanced fold.
      while (node is AddNode) {
        depth++;
        node = node.left;
      }
      // Balanced: <= 13. Left-deep would be 4095.
      expect(depth, lessThanOrEqualTo(13));
      expect(compile(tree), hasLength(4096));
    });
  });

  group('Expr.dot', () {
    test('weighted sum with constant', () {
      final model = MathOptModel(name: 'Dot');
      final x = model.continuous('x');
      final y = model.continuous('y');
      final e = Expr.dot({x: 2.0, y: 3.0}, 5);
      final c = LinearExpressionCompiler()..compile(e);
      expect(c.terms, {x.id: 2.0, y.id: 3.0});
      expect(c.constant, 5.0);
    });

    test('dotLists rejects length mismatch', () {
      final model = MathOptModel(name: 'Dot');
      final x = model.continuous('x');
      expect(() => Expr.dotLists([x], [1.0, 2.0]), throwsArgumentError);
    });
  });

  group('MathOptModel.addAll', () {
    test('batch insert solves identically', () async {
      MathOptModel build(bool batch) {
        final model = MathOptModel(name: 'Batch');
        final x = model.continuous('x', lower: 0);
        final y = model.continuous('y', lower: 0);
        final cs = [(x.asExpr + y.asExpr) <= 4, (x.asExpr) <= 3];
        if (batch) {
          model.addAll(cs);
        } else {
          for (final c in cs) {
            model.add(c);
          }
        }
        model.maximize(x.asExpr + y * 2);
        return model;
      }

      final a = await build(false).solve();
      final b = await build(true).solve();
      expectOptimal(a);
      expectOptimal(b);
      expectCloseTo(b.objectiveValue!, a.objectiveValue!);
    });
  });

  group('equivalence on a 2-D shape', () {
    test('dot-built transport objective matches loop-built one', () {
      // 3x4 transparency case: same math, one expression, no nesting.
      final loop = MathOptModel(name: 'Loop');
      final flat = MathOptModel(name: 'Flat');
      const cost = [
        [4.0, 6.0, 8.0, 7.0],
        [5.0, 3.0, 6.0, 9.0],
        [7.0, 8.0, 4.0, 5.0],
      ];
      ExpressionNode loopTotal = const ConstantNode(0);
      final flatVars = <Variable>[];
      final flatCoefs = <double>[];
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 4; j++) {
          final v = loop.continuous('r_${i}_$j', lower: 0);
          loopTotal += v * cost[i][j];
          final w = flat.continuous('r_${i}_$j', lower: 0);
          flatVars.add(w);
          flatCoefs.add(cost[i][j]);
        }
      }
      final flatTotal = Expr.dotLists(flatVars, flatCoefs);
      expect(compile(flatTotal).length, compile(loopTotal).length);
      for (final id in compile(loopTotal).keys) {
        expect(compile(flatTotal)[id], compile(loopTotal)[id]);
      }
    });
  });
}
