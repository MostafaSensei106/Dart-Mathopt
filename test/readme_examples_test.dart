import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

/// The code snippets in the root README, executed verbatim (modulo test
/// scaffolding). If a snippet stops compiling or its result changes,
/// this file — not just the docs — fails.
void main() {
  setUpAll(ensureNativeInit);

  test('README quick example', () async {
    final model = MathOptModel(name: 'demo');
    final x = model.continuous('x', lower: 0);
    final y = model.continuous('y', lower: 0);
    model.add(x + y <= 4);
    model.maximize(x * 3 + y * 5);

    final result = await model.solve();
    expect(result.isOptimal, isTrue);
    expectCloseTo(result.objectiveValue!, 20.0);
    expectCloseTo(result.valueOf(y), 4.0);
  });

  test('README LP example: production planning', () async {
    final model = MathOptModel(name: 'Production_Plan');
    final a = model.continuous('A', lower: 0);
    final b = model.continuous('B', lower: 0);
    model.maximize(a * 30 + b * 50);
    model.add((a * 2 + b * 1) <= 20);
    model.add((a * 1 + b * 3) <= 15);

    final r = await model.solve();
    expect(r.isOptimal, isTrue);
    expectCloseTo(r.objectiveValue!, 370.0);
    expect(r.dualValues, isNotNull);
  });

  test('README integer example: knapsack', () async {
    final model = MathOptModel(name: 'Knapsack');
    const weights = [2.0, 1.5, 0.8, 0.2];
    const values = [1000.0, 800.0, 400.0, 500.0];
    final packed = [for (var i = 0; i < 4; i++) model.binary('p$i')];
    model.maximize(Expr.dotLists(packed, values));
    model.add(Expr.dotLists(packed, weights) <= 3.0);

    final r = await model.solve();
    expect(r.isOptimal, isTrue);
    expectCloseTo(r.objectiveValue!, 1900.0);
    expect(r.dualValues, isNull);
  });
}
