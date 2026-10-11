import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

/// Failure modes: bad input throws typed errors *before* any solve, and
/// pathological models report honest statuses instead of garbage.
void main() {
  setUpAll(ensureNativeInit);

  group('model validation (throws before FFI)', () {
    test('empty model', () async {
      await expectLater(
        MathOptModel(name: 'Empty').solve(),
        throwsA(isA<ModelValidationException>()),
      );
    });

    test('missing objective', () async {
      final model = MathOptModel(name: 'NoObj');
      model.continuous('x', lower: 0);
      await expectLater(
        model.solve(),
        throwsA(isA<ModelValidationException>()),
      );
    });

    test('inverted bounds at creation', () {
      final model = MathOptModel(name: 'Bad');
      expect(
        () => model.continuous('x', lower: 5, upper: 1),
        throwsA(isA<ModelValidationException>()),
      );
    });

    test('variable ids are dense and zero-based', () {
      final model = MathOptModel(name: 'Ids');
      final vars = [
        model.continuous('a'),
        model.integer('b'),
        model.binary('c'),
      ];
      expect(vars.map((v) => v.id).toList(), [0, 1, 2]);
      expect(model.variables, hasLength(3));
    });

    test('binary defaults to [0, 1]', () {
      final model = MathOptModel(name: 'Bin');
      final b = model.binary('b');
      expect(b.lowerBound, 0.0);
      expect(b.upperBound, 1.0);
    });

    test('non-linear multiplication rejected by the compiler', () async {
      final model = MathOptModel(name: 'Nonlinear');
      final x = model.continuous('x', lower: 0);
      final y = model.continuous('y', lower: 0);
      model.minimize(MultiplyNode(x.asExpr, y.asExpr));
      await expectLater(
        model.solve(),
        throwsA(isA<ModelValidationException>()),
      );
    });

    test('NaN bounds rejected at creation, infinities allowed', () async {
      final model = MathOptModel(name: 'Bounds');
      expect(
        () => model.continuous('nan', lower: double.nan),
        throwsA(isA<ModelValidationException>()),
      );
      final open = model.continuous(
        'open',
        lower: double.negativeInfinity,
        upper: double.infinity,
      );
      expect(open.lowerBound, double.negativeInfinity);
      model.add(open <= 5);
      model.maximize(open.asExpr);
      final r = await model.solve();
      expectOptimal(r);
      expectCloseTo(r.valueOf(open), 5.0);
    });

    test(
      'NaN coefficient rejected before FFI, naming the constraint',
      () async {
        final model = MathOptModel(name: 'NaN');
        final x = model.continuous('x', lower: 0);
        model.add((x * double.nan <= 1).named('bad_row'));
        model.maximize(x.asExpr);
        await expectLater(
          model.solve(),
          throwsA(
            isA<ModelValidationException>().having(
              (e) => e.message,
              'message',
              allOf(contains('bad_row'), contains('Non-finite')),
            ),
          ),
        );
      },
    );

    test('NaN objective constant rejected before FFI', () async {
      final model = MathOptModel(name: 'NaNObj');
      final x = model.continuous('x', lower: 0, upper: 1);
      model.add(x <= 1);
      model.maximize(x.asExpr + double.nan);
      await expectLater(
        model.solve(),
        throwsA(
          isA<ModelValidationException>().having(
            (e) => e.message,
            'message',
            contains('objective'),
          ),
        ),
      );
    });
  });

  group('constraint constant folding', () {
    test('constants move to the RHS: x + 3 <= 10 behaves as x <= 7', () async {
      final model = MathOptModel(name: 'Fold');
      final x = model.continuous('x', lower: 0);
      model.add((x.asExpr + 3.expr) <= 10);
      model.maximize(x.asExpr);

      final r = await model.solve();
      expectOptimal(r);
      expectCloseTo(r.valueOf(x), 7.0);
      expectCloseTo(r.objectiveValue!, 7.0);
    });

    test('negated constants fold: 5 - x >= 2 behaves as x <= 3', () async {
      final model = MathOptModel(name: 'FoldNeg');
      final x = model.continuous('x', lower: 0);
      model.add((5.expr - x.asExpr) >= 2);
      model.maximize(x.asExpr);

      final r = await model.solve();
      expectOptimal(r);
      expectCloseTo(r.valueOf(x), 3.0);
    });
  });

  group('pathological models (honest statuses)', () {
    test('contradictory bounds report infeasible, null objective', () async {
      final model = MathOptModel(name: 'Infeasible');
      final x = model.continuous('x', lower: 0);
      model.add(x <= 1);
      model.add(x >= 2);
      model.minimize(x.asExpr);

      final r = await model.solve();
      expect(r.status, SolveStatus.infeasible);
      expect(r.objectiveValue, isNull);
    });

    test('unbounded ray reports unbounded', () async {
      final model = MathOptModel(name: 'Unbounded');
      final x = model.continuous('x', lower: 0);
      model.add(x >= 1);
      model.maximize(x.asExpr);

      final r = await model.solve();
      expect(r.status, SolveStatus.unbounded);
    });

    test('MILP forced onto Clarabel is rejected before FFI', () async {
      final model = MathOptModel(name: 'WrongEngine');
      final b = model.binary('b');
      model.maximize(b.asExpr);

      // Dart-side capability negotiation (SolverRegistry) rejects this
      // with a clear validation error instead of a native failure.
      await expectLater(
        model.solve(
          options: const SolveOptions(solver: SolverPreference.clarabel),
        ),
        throwsA(isA<ModelValidationException>()),
      );
    });
  });
}
