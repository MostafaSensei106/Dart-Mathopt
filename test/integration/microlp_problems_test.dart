import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

/// MicroLP engine (pure Rust via good_lp): LP correctness against known
/// optima, `>=` normalization, and MILP rejection.
void main() {
  setUpAll(ensureNativeInit);

  const microlp = SolveOptions(solver: SolverPreference.microlp);

  group('microlp LP', () {
    test('solves the demo LP at the expected corner', () async {
      final model = MathOptModel(name: 'MicroLP_Demo');
      final x = model.continuous('x', lower: 0);
      final y = model.continuous('y', lower: 0);
      model.add((x.asExpr + y.asExpr) <= 4);
      model.maximize(x.asExpr + y * 2);

      final r = await model.solve(options: microlp);
      expectOptimal(r);
      expectCloseTo(r.objectiveValue!, 8.0);
      expectCloseTo(r.valueOf(y), 4.0);
    });

    test('handles >= and == constraints (normalization)', () async {
      final model = MathOptModel(name: 'MicroLP_Mixed_Senses');
      final x = model.continuous('x', lower: 0);
      final y = model.continuous('y', lower: 0);
      model.add((x.asExpr + y.asExpr) >= 2);
      model.add((x.asExpr + y * 2) <= 6);
      model.add(x.asExpr.eq(1));
      model.maximize(y.asExpr);

      final r = await model.solve(options: microlp);
      expectOptimal(r);
      // x = 1, y as large as x + 2y <= 6 allows: y = 2.5.
      expectCloseTo(r.valueOf(x), 1.0);
      expectCloseTo(r.valueOf(y), 2.5);
      expectCloseTo(r.objectiveValue!, 2.5);
    });

    test('matches HiGHS on production planning', () async {
      Future<double?> solveWith(SolverPreference solver) async {
        final model = MathOptModel(name: 'Production_MicroLP');
        final a = model.continuous('A', lower: 0);
        final b = model.continuous('B', lower: 0);
        model.maximize(a * 30 + b * 50);
        model.add(((a * 2 + b * 1) <= 20).named('machine'));
        model.add(((a * 1 + b * 3) <= 15).named('material'));
        final r = await model.solve(options: SolveOptions(solver: solver));
        expectOptimal(r);
        return r.objectiveValue;
      }

      expectCloseTo(
        (await solveWith(SolverPreference.microlp))!,
        (await solveWith(SolverPreference.highs))!,
      );
    });
  });

  group('microlp limits', () {
    test('MILP is rejected before FFI', () async {
      final model = MathOptModel(name: 'MicroLP_MILP');
      final b = model.binary('b');
      model.maximize(b.asExpr);
      await expectLater(
        model.solve(options: microlp),
        throwsA(isA<ModelValidationException>()),
      );
    });

    test('infeasible reports infeasible with null objective', () async {
      final model = MathOptModel(name: 'MicroLP_Infeasible');
      final x = model.continuous('x', lower: 0);
      model.add(x <= 1);
      model.add(x >= 2);
      model.minimize(x.asExpr);
      final r = await model.solve(options: microlp);
      expect(r.status, SolveStatus.infeasible);
      expect(r.objectiveValue, isNull);
    });

    test('unbounded reports unbounded', () async {
      final model = MathOptModel(name: 'MicroLP_Unbounded');
      final x = model.continuous('x', lower: 0);
      model.add(x >= 1);
      model.maximize(x.asExpr);
      final r = await model.solve(options: microlp);
      expect(r.status, SolveStatus.unbounded);
    });
  });
}
