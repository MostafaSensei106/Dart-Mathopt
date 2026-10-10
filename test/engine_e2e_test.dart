import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end test through the real Rust engines (HiGHS + Clarabel).
///
/// Requires the native library (built automatically by cargokit when
/// running under `flutter test`).
void main() {
  setUpAll(() async {
    await RustLib.init();
  });

  test('HiGHS solves a simple LP (max x + 2y s.t. x + y <= 4)', () async {
    final model = MathOptModel(name: 'lp_demo');
    final x = model.continuous('x', lower: 0);
    final y = model.continuous('y', lower: 0);
    model.add((x.asExpr + y.asExpr) <= 4);
    model.maximize(x.asExpr + y.asExpr * 2);

    final result = await model.solve();
    expect(result.status, SolveStatus.optimal);
    expect(result.objectiveValue, closeTo(8.0, 1e-6));
    expect(result.valueOf(x), closeTo(0.0, 1e-6));
    expect(result.valueOf(y), closeTo(4.0, 1e-6));
  });

  test('HiGHS solves a binary MILP', () async {
    final model = MathOptModel(name: 'milp_demo');
    final x = model.binary('x');
    final y = model.binary('y');
    model.add((x.asExpr + y.asExpr) <= 1);
    model.maximize(x.asExpr + y.asExpr * 2);

    final result = await model.solve();
    expect(result.status, SolveStatus.optimal);
    expect(result.objectiveValue, closeTo(2.0, 1e-6));
    expect(result.valueOf(y), closeTo(1.0, 1e-6));
    expect(result.valueOf(x), closeTo(0.0, 1e-6));
  });

  test('Clarabel solves the same LP when forced', () async {
    final model = MathOptModel(name: 'lp_clarabel');
    final x = model.continuous('x', lower: 0);
    final y = model.continuous('y', lower: 0);
    model.add((x.asExpr + y.asExpr) <= 4);
    model.maximize(x.asExpr + y.asExpr * 2);

    final result = await model.solve(
      options: const SolveOptions(solver: SolverPreference.clarabel),
    );
    expect(result.status, SolveStatus.optimal);
    expect(result.objectiveValue, closeTo(8.0, 1e-4));
  });

  test('infeasible model reports infeasible', () async {
    final model = MathOptModel(name: 'infeasible');
    final x = model.continuous('x', lower: 0);
    model.add(x <= 1);
    model.add(x >= 2);
    model.minimize(x.asExpr);

    final result = await model.solve();
    expect(result.status, SolveStatus.infeasible);
  });
}
