import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

/// Compiled-model cache: repeated solves skip AST recompilation, any
/// structural mutation invalidates, results stay identical.
void main() {
  setUpAll(ensureNativeInit);

  group('MathOptModel compiled-request cache', () {
    MathOptModel smallLp() {
      final model = MathOptModel(name: 'Cache_Probe');
      final x = model.continuous('x', lower: 0);
      final y = model.continuous('y', lower: 0);
      model.add((x.asExpr + y.asExpr) <= 4);
      model.maximize(x.asExpr + y * 2);
      return model;
    }

    test('first solve compiles, second solve hits the cache', () async {
      final model = smallLp();
      expect(model.lastSolveWasCached, isFalse);

      final first = await model.solve();
      expect(model.lastSolveWasCached, isFalse);
      expectOptimal(first);

      final second = await model.solve();
      expect(model.lastSolveWasCached, isTrue);
      expectOptimal(second);
      expect(second.objectiveValue, first.objectiveValue);
      expect(
        second.valueOf(second.variableValues.keys.first),
        first.valueOf(first.variableValues.keys.first),
      );
    });

    test('adding a constraint invalidates the cache', () async {
      final model = smallLp();
      await model.solve();
      await model.solve();
      expect(model.lastSolveWasCached, isTrue);

      final x = model.variables.first;
      model.add((x.asExpr) <= 1);
      final r = await model.solve();
      expect(model.lastSolveWasCached, isFalse);
      expectOptimal(r);
      // x <= 1 is non-binding here (y dominates the objective), so the
      // optimum is unchanged — but it must come from a fresh compile.
      expectCloseTo(r.objectiveValue!, 8.0);
      expect(r.valueOf(x), lessThanOrEqualTo(1.0 + 1e-6));
    });

    test('changing the objective invalidates the cache', () async {
      final model = smallLp();
      await model.solve();
      expect(model.lastSolveWasCached, isFalse);

      final x = model.variables.first;
      final y = model.variables.last;
      model.minimize(x.asExpr + y.asExpr);
      final r = await model.solve();
      expect(model.lastSolveWasCached, isFalse);
      expectOptimal(r);
      expectCloseTo(r.objectiveValue!, 0.0);
    });

    test('per-call options stay fresh on cache hits', () async {
      final model = smallLp();
      await model.solve();
      // Same structure, different options: cache hit, options honored.
      final r = await model.solve(
        options: const SolveOptions(solver: SolverPreference.highs),
      );
      expect(model.lastSolveWasCached, isTrue);
      expectOptimal(r);
      expectCloseTo(r.objectiveValue!, 8.0);
    });

    test('cached repeated solves agree on a larger model', () async {
      final model = MathOptModel(name: 'Cache_Factory');
      final a = model.continuous('A', lower: 0);
      final b = model.continuous('B', lower: 0);
      model.maximize(a * 30 + b * 50);
      model.add(((a * 2 + b * 1) <= 20).named('machine'));
      model.add(((a * 1 + b * 3) <= 15).named('material'));

      var expected = 0.0;
      for (var i = 0; i < 3; i++) {
        final r = await model.solve();
        expectOptimal(r);
        if (i == 0) {
          expect(model.lastSolveWasCached, isFalse);
          expected = r.objectiveValue!;
        } else {
          expect(model.lastSolveWasCached, isTrue);
          expectCloseTo(r.objectiveValue!, expected);
        }
      }
    });
  });
}
