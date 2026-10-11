import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

/// Typed solutions: availability vs quality.
/// Status-driven cases are pure unit checks on constructed results;
/// engine-backed cases prove the mapping end to end.
void main() {
  setUpAll(ensureNativeInit);

  SolveResult fake({
    required SolveStatus status,
    double? objective,
    required Map<Variable, double> values,
  }) => SolveResult(
    status: status,
    objectiveValue: objective,
    variableValues: values,
    dualValues: null,
    statistics: const SolveStatistics(),
  );

  group('hasSolution (unit)', () {
    test('optimal qualifies', () {
      final model = MathOptModel(name: 'U');
      final x = model.continuous('x');
      final r = fake(
        status: SolveStatus.optimal,
        objective: 1.0,
        values: {x: 1.0},
      );
      expect(r.hasSolution, isTrue);
      expect(r.isOptimal, isTrue);
      final s = r.requireSolution();
      expect(s.isOptimal, isTrue);
      expect(s.status, SolveStatus.optimal);
      expect(s.objectiveValue, 1.0);
      expect(s.valueOf(x), 1.0);
    });

    test('time limit with finite values qualifies as incumbent', () {
      final model = MathOptModel(name: 'U');
      final x = model.continuous('x');
      final r = fake(
        status: SolveStatus.timeLimitExceeded,
        objective: 2.0,
        values: {x: 2.0},
      );
      expect(r.hasSolution, isTrue);
      expect(r.isOptimal, isFalse);
      final s = r.requireSolution();
      expect(s.isOptimal, isFalse);
      expect(s.objectiveValue, 2.0);
    });

    test('time limit with NaN values does not qualify', () {
      final model = MathOptModel(name: 'U');
      final x = model.continuous('x');
      final r = fake(
        status: SolveStatus.timeLimitExceeded,
        values: {x: double.nan},
      );
      expect(r.hasSolution, isFalse);
      expect(r.requireSolution, throwsA(isA<SolverExecutionException>()));
    });

    test('infeasible never qualifies, even with finite numbers', () {
      final model = MathOptModel(name: 'U');
      final x = model.continuous('x');
      final r = fake(status: SolveStatus.infeasible, values: {x: 0.0});
      expect(r.hasSolution, isFalse);
      expect(r.requireSolution, throwsA(isA<SolverExecutionException>()));
    });

    test('unbounded and unknown do not qualify', () {
      final model = MathOptModel(name: 'U');
      final x = model.continuous('x');
      for (final status in [
        SolveStatus.unbounded,
        SolveStatus.numericalError,
        SolveStatus.unknown,
      ]) {
        final r = fake(status: status, values: {x: 1.0});
        expect(r.hasSolution, isFalse, reason: '$status');
        expect(r.requireSolution, throwsA(isA<SolverExecutionException>()));
      }
    });
  });

  group('engine-backed', () {
    test('optimal end to end', () async {
      final model = MathOptModel(name: 'E2E');
      final x = model.continuous('x', lower: 0, upper: 4);
      model.maximize(x.asExpr);
      final r = await model.solve();
      final s = r.requireSolution();
      expect(s.isOptimal, isTrue);
      expectCloseTo(s.objectiveValue!, 4.0);
      expectCloseTo(s.valueOf(x), 4.0);
    });

    test('infeasible throws on requireSolution', () async {
      final model = MathOptModel(name: 'E2E');
      final x = model.continuous('x', lower: 0);
      model.add(x <= 1);
      model.add(x >= 2);
      model.minimize(x.asExpr);
      final r = await model.solve();
      expect(r.hasSolution, isFalse);
      expect(r.requireSolution, throwsA(isA<SolverExecutionException>()));
    });
  });
}
