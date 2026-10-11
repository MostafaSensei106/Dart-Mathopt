import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:dart_mathopt/src/modules/modeling/compiler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compiler unit tests: AST → sparse linear form without native solves.
/// Pure Dart — fast and deterministic.
void main() {
  MathOptModel modelOf() => MathOptModel(name: 'Compiler_Probe');

  group('linear compilation', () {
    test('single variable accumulates coefficient 1', () {
      final model = modelOf();
      final x = model.continuous('x');
      final c = LinearExpressionCompiler()..compile(x.asExpr);
      expect(c.terms, {x.id: 1.0});
      expect(c.constant, 0.0);
    });

    test('scaled sums accumulate per variable', () {
      final model = modelOf();
      final x = model.continuous('x');
      final y = model.continuous('y');
      final c = LinearExpressionCompiler()
        ..compile(x.asExpr * 2 + y.asExpr * 3 + 5.expr);
      expect(c.terms[x.id], 2.0);
      expect(c.terms[y.id], 3.0);
      expect(c.constant, 5.0);
    });

    test('nested multiplication distributes the multiplier', () {
      final model = modelOf();
      final x = model.continuous('x');
      final y = model.continuous('y');
      final c = LinearExpressionCompiler()..compile((x.asExpr + y.asExpr) * 2);
      expect(c.terms[x.id], 2.0);
      expect(c.terms[y.id], 2.0);
    });

    test('const * const folds into the constant', () {
      final c = LinearExpressionCompiler()..compile(3.expr + 4.expr * 2);
      expect(c.terms, isEmpty);
      expect(c.constant, 11.0);
    });

    test('negation flips signs', () {
      final model = modelOf();
      final x = model.continuous('x');
      final c = LinearExpressionCompiler()..compile(-x.asExpr + 10.expr);
      expect(c.terms[x.id], -1.0);
      expect(c.constant, 10.0);
    });

    test('sortedTerms are deterministic by variable id', () {
      final model = modelOf();
      final a = model.continuous('a');
      final b = model.continuous('b');
      final cc = model.continuous('c');
      final c = LinearExpressionCompiler()
        ..compile(cc.asExpr + a.asExpr + b.asExpr);
      expect(c.sortedTerms.map((e) => e.key).toList(), [a.id, b.id, cc.id]);
    });
  });

  group('node equality', () {
    test('structurally equal trees compare equal', () {
      final model = MathOptModel(name: 'Eq');
      final x = model.continuous('x');
      final y = model.continuous('y');
      expect(x.asExpr + y, x.asExpr + y);
      expect(x.asExpr + y, isNot(x.asExpr + x));
      expect(const ConstantNode(2.0), const ConstantNode(2.0));
      expect(-x.asExpr, -x.asExpr);
    });
  });

  group('rejections', () {
    test('variable * variable throws ModelValidationException', () {
      final model = modelOf();
      final x = model.continuous('x');
      final y = model.continuous('y');
      expect(
        () => (LinearExpressionCompiler()
          ..compile(MultiplyNode(x.asExpr, y.asExpr))),
        throwsA(isA<ModelValidationException>()),
      );
    });
  });
}
