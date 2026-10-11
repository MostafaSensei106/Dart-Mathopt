import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:dart_mathopt/src/modules/modeling/compiler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

/// Mixed-operand expressions: `x + y`, `x - 2`, `expr + var`.
/// Compile-level checks are pure Dart; one small solve proves the
/// end-to-end path with the clean syntax.
void main() {
  setUpAll(ensureNativeInit);

  Map<int, double> compile(ExpressionNode e) =>
      (LinearExpressionCompiler()..compile(e)).terms;

  group('variable mixed operands', () {
    test('x + y accumulates both', () {
      final model = MathOptModel(name: 'Ops');
      final x = model.continuous('x');
      final y = model.continuous('y');
      expect(compile(x + y), {x.id: 1.0, y.id: 1.0});
    });

    test('x - y negates the second', () {
      final model = MathOptModel(name: 'Ops');
      final x = model.continuous('x');
      final y = model.continuous('y');
      expect(compile(x - y), {x.id: 1.0, y.id: -1.0});
    });

    test('x + 2 folds the number into the constant', () {
      final model = MathOptModel(name: 'Ops');
      final x = model.continuous('x');
      final c = LinearExpressionCompiler()..compile(x + 2);
      expect(c.terms, {x.id: 1.0});
      expect(c.constant, 2.0);
    });

    test('x * 3 scales; x * y throws immediately', () {
      final model = MathOptModel(name: 'Ops');
      final x = model.continuous('x');
      final y = model.continuous('y');
      expect(compile(x * 3), {x.id: 3.0});
      expect(() => x * y, throwsA(isA<ModelValidationException>()));
    });

    test('unsupported operand type throws', () {
      final model = MathOptModel(name: 'Ops');
      final x = model.continuous('x');
      expect(() => x + 'nope', throwsA(isA<ModelValidationException>()));
    });
  });

  group('expression mixed operands', () {
    test('(x * 2) + y distributes', () {
      final model = MathOptModel(name: 'Ops');
      final x = model.continuous('x');
      final y = model.continuous('y');
      expect(compile(x * 2 + y), {x.id: 2.0, y.id: 1.0});
    });

    test('(x + 1) - y keeps the constant', () {
      final model = MathOptModel(name: 'Ops');
      final x = model.continuous('x');
      final y = model.continuous('y');
      final c = LinearExpressionCompiler()..compile((x + 1) - y);
      expect(c.terms, {x.id: 1.0, y.id: -1.0});
      expect(c.constant, 1.0);
    });
  });

  group('clean-syntax solve', () {
    test('x + y <= 10 with x * 3 + y * 5 objective', () async {
      final model = MathOptModel(name: 'Clean');
      final x = model.continuous('x', lower: 0);
      final y = model.continuous('y', lower: 0);
      model.add(x + y <= 10);
      model.maximize(x * 3 + y * 5);

      final r = await model.solve();
      expectOptimal(r);
      expectCloseTo(r.objectiveValue!, 50.0);
      expectCloseTo(r.valueOf(y), 10.0);
      expect(r.tryValueOf(x), isNotNull);
    });
  });

  group('tryValueOf', () {
    test('null for unknown variables, value for known ones', () async {
      final model = MathOptModel(name: 'Lookup');
      final x = model.continuous('x', lower: 0, upper: 5);
      model.maximize(x.asExpr);
      final r = await model.solve();
      expectOptimal(r);
      expect(r.tryValueOf(x), isNotNull);

      final outsider = MathOptModel(name: 'Other').continuous('z');
      expect(r.tryValueOf(outsider), isNull);
      expect(r.valueOf(outsider), isNaN);
    });
  });
}
