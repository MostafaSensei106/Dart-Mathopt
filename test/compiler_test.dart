import 'package:dart_mathopt/src/core/exceptions.dart';
import 'package:dart_mathopt/src/modules/modeling/ast/arithmetic_nodes.dart';
import 'package:dart_mathopt/src/modules/modeling/ast/node.dart';
import 'package:dart_mathopt/src/modules/modeling/compiler.dart';
import 'package:dart_mathopt/src/modules/modeling/variable.dart';
import 'package:dart_mathopt/src/core/types.dart';
import 'package:flutter_test/flutter_test.dart';

Variable _v(int id, String name) =>
    Variable(id: id, name: name, type: VariableType.continuous);

void main() {
  group('ExpressionNode operators', () {
    test('builds Add/Multiply/Negate nodes immutably', () {
      final x = _v(0, 'x');
      final y = _v(1, 'y');

      final sum = x + y.asExpr;
      expect(sum, isA<AddNode>());

      final scaled = x.asExpr * 2;
      expect(scaled, isA<MultiplyNode>());

      final neg = -x.asExpr;
      expect(neg, isA<NegateNode>());

      final diff = x.asExpr - y.asExpr;
      expect(diff, isA<AddNode>());
    });

    test('constraint builders produce typed constraints', () {
      final x = _v(0, 'x');
      final c1 = (x.asExpr + 1.expr) <= 5;
      expect(c1.sense, ConstraintSense.lessThanOrEqual);
      expect(c1.rhs, 5.0);

      final c2 = x >= 2;
      expect(c2.sense, ConstraintSense.greaterThanOrEqual);

      final c3 = x.asExpr.eq(3);
      expect(c3.sense, ConstraintSense.equal);
    });

    test('num extension supports literal constants in expressions', () {
      final x = _v(0, 'x');
      final expr = x.asExpr * 2 + 1.expr;
      final compiler = LinearExpressionCompiler()..compile(expr);
      expect(compiler.terms[0], 2.0);
      expect(compiler.constant, 1.0);
    });
  });

  group('LinearExpressionCompiler', () {
    test('accumulates repeated variables and constants', () {
      final x = _v(0, 'x');
      final y = _v(1, 'y');
      // 2x + 3 + y + x  -> 3x + y + 3
      final expr = x.asExpr * 2 + 3.expr + y.asExpr + x.asExpr;
      final compiler = LinearExpressionCompiler()..compile(expr);
      expect(compiler.terms[0], 3.0);
      expect(compiler.terms[1], 1.0);
      expect(compiler.constant, 3.0);
    });

    test('handles nested multiplication 2 * (x + y)', () {
      final x = _v(0, 'x');
      final y = _v(1, 'y');
      final inner = x.asExpr + y.asExpr;
      final expr = inner * 2;
      final compiler = LinearExpressionCompiler()..compile(expr);
      expect(compiler.terms[0], 2.0);
      expect(compiler.terms[1], 2.0);
      expect(compiler.constant, 0.0);
    });

    test('handles negation and subtraction', () {
      final x = _v(0, 'x');
      final y = _v(1, 'y');
      final expr = x.asExpr - y.asExpr - 4.expr;
      final compiler = LinearExpressionCompiler()..compile(expr);
      expect(compiler.terms[0], 1.0);
      expect(compiler.terms[1], -1.0);
      expect(compiler.constant, -4.0);
    });

    test('rejects non-linear multiplication', () {
      final x = _v(0, 'x');
      final y = _v(1, 'y');
      final expr = MultiplyNode(x.asExpr, y.asExpr);
      expect(
        () => LinearExpressionCompiler().compile(expr),
        throwsA(isA<ModelValidationException>()),
      );
    });

    test('sortedTerms are ordered by variable id', () {
      final x = _v(2, 'x');
      final y = _v(0, 'y');
      final z = _v(1, 'z');
      final expr = x.asExpr + y.asExpr + z.asExpr;
      final compiler = LinearExpressionCompiler()..compile(expr);
      final ids = compiler.sortedTerms.map((e) => e.key).toList();
      expect(ids, [0, 1, 2]);
    });
  });

  group('Constraint constant folding', () {
    test('named() attaches a label', () {
      final x = _v(0, 'x');
      final c = ((x.asExpr + 1.expr) <= 5).named('c1');
      expect(c.name, 'c1');
    });
  });
}
