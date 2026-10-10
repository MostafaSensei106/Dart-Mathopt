import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

/// Correctness of pure-LP models: the optimum is known analytically, and
/// every constraint is re-checked from the returned primal values.
void main() {
  setUpAll(ensureNativeInit);

  group('production planning (HiGHS LP)', () {
    test('maximizes profit at the expected corner', () async {
      final model = MathOptModel(name: 'Production_Plan');
      final a = model.continuous('A', lower: 0);
      final b = model.continuous('B', lower: 0);
      model.maximize(a * 30 + b * 50);
      model.add(((a * 2 + b * 1) <= 20).named('machine'));
      model.add(((a * 1 + b * 3) <= 15).named('material'));

      final r = await model.solve();
      expectOptimal(r);
      expectCloseTo(r.objectiveValue!, 370.0);
      expectCloseTo(r.valueOf(a), 9.0);
      expectCloseTo(r.valueOf(b), 2.0);

      // Independent feasibility re-check.
      expect(2 * r.valueOf(a) + r.valueOf(b), lessThanOrEqualTo(20.0 + 1e-6));
      expect(r.valueOf(a) + 3 * r.valueOf(b), lessThanOrEqualTo(15.0 + 1e-6));
      // Objective matches the reported value.
      expectCloseTo(
          30 * r.valueOf(a) + 50 * r.valueOf(b), r.objectiveValue!);
    });

    test('LP exposes dual values (shadow prices)', () async {
      final model = MathOptModel(name: 'Duals');
      final x = model.continuous('x', lower: 0);
      final y = model.continuous('y', lower: 0);
      model.maximize(x + y * 2);
      model.add((x.asExpr + y.asExpr) <= 4);

      final r = await model.solve();
      expectOptimal(r);
      expect(r.dualValues, isNotNull,
          reason: 'pure LP must return duals');
      expect(r.dualValues, hasLength(1));
    });
  });

  group('budget diet (HiGHS LP)', () {
    test('cheapest mix hits nutrition floors exactly', () async {
      const price = [0.5, 0.8, 0.6];
      const cal = [100.0, 150.0, 70.0];
      const protein = [4.0, 8.0, 6.0];

      final model = MathOptModel(name: 'Budget_Diet');
      final food = [
        for (var i = 0; i < 3; i++) model.continuous('food_$i', lower: 0),
      ];
      ExpressionNode cost = const ConstantNode(0);
      ExpressionNode calTot = const ConstantNode(0);
      ExpressionNode proTot = const ConstantNode(0);
      for (var i = 0; i < 3; i++) {
        cost += food[i] * price[i];
        calTot += food[i] * cal[i];
        proTot += food[i] * protein[i];
      }
      model.minimize(cost);
      model.add((calTot >= 500).named('calories'));
      model.add((proTot >= 25).named('protein'));

      final r = await model.solve();
      expectOptimal(r);
      expectCloseTo(r.objectiveValue!, 2.625);
      expectCloseTo(r.valueOf(food[0]), 1.25);
      expectCloseTo(r.valueOf(food[1]), 2.5);
      expectCloseTo(r.valueOf(food[2]), 0.0);

      // Floors hold (within tolerance).
      var c = 0.0, p = 0.0;
      for (var i = 0; i < 3; i++) {
        c += r.valueOf(food[i]) * cal[i];
        p += r.valueOf(food[i]) * protein[i];
      }
      expect(c, greaterThanOrEqualTo(500.0 - 1e-6));
      expect(p, greaterThanOrEqualTo(25.0 - 1e-6));
    });
  });

  group('transportation network (HiGHS LP, 2-D)', () {
    test('ships cheapest with supplies/demands exact', () async {
      const supply = [20.0, 30.0, 25.0];
      const demand = [15.0, 20.0, 18.0, 22.0];
      const cost = [
        [4.0, 6.0, 8.0, 7.0],
        [5.0, 3.0, 6.0, 9.0],
        [7.0, 8.0, 4.0, 5.0],
      ];

      final model = MathOptModel(name: 'Transportation');
      final routes = [
        for (var i = 0; i < 3; i++)
          [for (var j = 0; j < 4; j++) model.continuous('r_${i}_$j', lower: 0)],
      ];
      for (var i = 0; i < 3; i++) {
        ExpressionNode s = const ConstantNode(0);
        for (var j = 0; j < 4; j++) {
          s += routes[i][j].asExpr;
        }
        model.add((s <= supply[i]).named('supply_$i'));
      }
      for (var j = 0; j < 4; j++) {
        ExpressionNode d = const ConstantNode(0);
        for (var i = 0; i < 3; i++) {
          d += routes[i][j].asExpr;
        }
        model.add(d.eq(demand[j]).named('demand_$j'));
      }
      ExpressionNode total = const ConstantNode(0);
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 4; j++) {
          total += routes[i][j] * cost[i][j];
        }
      }
      model.minimize(total);

      final r = await model.solve();
      expectOptimal(r);
      expectCloseTo(r.objectiveValue!, 332.0);

      // Supplies respected, demands met exactly.
      for (var i = 0; i < 3; i++) {
        var shipped = 0.0;
        for (var j = 0; j < 4; j++) {
          shipped += r.valueOf(routes[i][j]);
        }
        expect(shipped, lessThanOrEqualTo(supply[i] + 1e-6));
      }
      for (var j = 0; j < 4; j++) {
        var received = 0.0;
        for (var i = 0; i < 3; i++) {
          received += r.valueOf(routes[i][j]);
        }
        expectCloseTo(received, demand[j]);
      }
      expect(r.dualValues, isNotNull);
      expect(r.dualValues, hasLength(7));
    });
  });

  group('portfolio (Clarabel LP)', () {
    test('forced Clarabel matches the analytical mix', () async {
      const ret = [0.08, 0.12, 0.05];
      const risk = [0.06, 0.10, 0.02];

      final model = MathOptModel(name: 'Portfolio');
      final x = [for (var i = 0; i < 3; i++) model.continuous('x$i', lower: 0)];
      ExpressionNode gain = const ConstantNode(0);
      ExpressionNode riskTot = const ConstantNode(0);
      ExpressionNode sum = const ConstantNode(0);
      for (var i = 0; i < 3; i++) {
        gain += x[i] * ret[i];
        riskTot += x[i] * risk[i];
        sum += x[i].asExpr;
      }
      model.maximize(gain);
      model.add(sum.eq(10000).named('budget'));
      model.add((riskTot <= 500).named('risk'));
      model.add((x[2] >= 2000).named('min_bonds'));
      model.add((x[1] <= 5000).named('max_hot'));

      final r = await model.solve(
        options: const SolveOptions(solver: SolverPreference.clarabel),
      );
      expectOptimal(r);
      expectCloseTo(r.objectiveValue!, 762.5, 1e-3);
      expectCloseTo(r.valueOf(x[0]), 0.0, 1e-3);
      expectCloseTo(r.valueOf(x[1]), 3750.0, 1e-3);
      expectCloseTo(r.valueOf(x[2]), 6250.0, 1e-3);
    });
  });
}
