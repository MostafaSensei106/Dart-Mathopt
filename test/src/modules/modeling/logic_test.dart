import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:dart_mathopt/src/modules/modeling/compiler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

/// Logical choice helpers: math, validation, and engine equivalence.
/// Helpers return plain constraints through the standard compile path.
void main() {
  setUpAll(ensureNativeInit);

  Map<int, double> compile(Constraint c) =>
      (LinearExpressionCompiler()..compile(c.expression)).terms;

  group('math', () {
    test('exactlyOne is sum == 1', () {
      final model = MathOptModel(name: 'Logic');
      final bs = [for (var i = 0; i < 3; i++) model.binary('b$i')];
      final c = exactlyOne(bs, name: 'pick');
      expect(c.sense, ConstraintSense.equal);
      expect(c.rhs, 1.0);
      expect(c.name, 'pick');
      expect(compile(c).values, everyElement(1.0));
    });

    test('atMostOne is sum <= 1, atLeastOne is sum >= 1', () {
      final model = MathOptModel(name: 'Logic');
      final bs = [for (var i = 0; i < 2; i++) model.binary('b$i')];
      expect(atMostOne(bs).sense, ConstraintSense.lessThanOrEqual);
      expect(atLeastOne(bs).sense, ConstraintSense.greaterThanOrEqual);
    });
  });

  group('validation', () {
    test('empty input throws', () {
      expect(
        () => exactlyOne(const []),
        throwsA(isA<ModelValidationException>()),
      );
    });

    test('non-binary variables are named in the error', () {
      final model = MathOptModel(name: 'Logic');
      final x = model.continuous('x');
      final b = model.binary('b');
      expect(
        () => atMostOne([x, b]),
        throwsA(
          isA<ModelValidationException>().having(
            (e) => e.message,
            'message',
            contains('x'),
          ),
        ),
      );
    });

    test('integer variables are rejected too', () {
      final model = MathOptModel(name: 'Logic');
      final n = model.integer('n', lower: 0, upper: 2);
      expect(() => atLeastOne([n]), throwsA(isA<ModelValidationException>()));
    });
  });

  group('engine equivalence (HiGHS)', () {
    test('exactlyOne picks the cheapest alternative', () async {
      final model = MathOptModel(name: 'Pick');
      final alt = [for (var i = 0; i < 3; i++) model.binary('a$i')];
      model.add(exactlyOne(alt));
      model.minimize(Expr.dotLists(alt, [5.0, 2.0, 8.0]));

      final r = await model.solve();
      final s = r.requireSolution();
      expectCloseTo(s.objectiveValue!, 2.0);
      expectCloseTo(s.valueOf(alt[1]), 1.0);
    });

    test('atMostOne allows none; atLeastOne forces one', () async {
      Future<double?> solveWith(
        Constraint Function(List<Variable>) helper,
      ) async {
        final model = MathOptModel(name: 'Bound');
        final alt = [for (var i = 0; i < 2; i++) model.binary('a$i')];
        model.add(helper(alt));
        model.maximize(Expr.dotLists(alt, [3.0, 4.0]));
        final r = await model.solve();
        expectOptimal(r);
        return r.objectiveValue;
      }

      // Profits positive: at most one takes the best (4.0)...
      expectCloseTo((await solveWith(atMostOne))!, 4.0);
      // ...at least one takes both when unconstrained above (7.0).
      expectCloseTo((await solveWith(atLeastOne))!, 7.0);
    });
  });
}
