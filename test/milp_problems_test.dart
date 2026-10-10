import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

/// Correctness of MILP models: exact optima plus integrality proofs.
/// MILP must NOT return duals (they are meaningless for integer models).
void main() {
  setUpAll(ensureNativeInit);

  group('knapsack (binary MILP)', () {
    test('packs the optimal subset, all decisions integral', () async {
      const weights = [2.0, 1.5, 0.8, 0.2];
      const values = [1000.0, 800.0, 400.0, 500.0];

      final model = MathOptModel(name: 'Knapsack');
      final packed = [for (var i = 0; i < 4; i++) model.binary('p$i')];
      ExpressionNode value = const ConstantNode(0);
      ExpressionNode weight = const ConstantNode(0);
      for (var i = 0; i < 4; i++) {
        value += packed[i] * values[i];
        weight += packed[i] * weights[i];
      }
      model.maximize(value);
      model.add((weight <= 3.0).named('capacity'));

      final r = await model.solve();
      expectOptimal(r);
      expectCloseTo(r.objectiveValue!, 1900.0);

      // Laptop + Tablet + Watch, Camera left behind.
      const expected = [1.0, 0.0, 1.0, 1.0];
      for (var i = 0; i < 4; i++) {
        final v = r.valueOf(packed[i]);
        expect(v, anyOf(closeTo(0.0, 1e-6), closeTo(1.0, 1e-6)),
            reason: 'binary variable p$i = $v is not integral');
        expectCloseTo(v, expected[i]);
      }

      // Capacity independently verified.
      var w = 0.0;
      for (var i = 0; i < 4; i++) {
        w += r.valueOf(packed[i]) * weights[i];
      }
      expect(w, lessThanOrEqualTo(3.0 + 1e-6));
      expect(r.dualValues, isNull,
          reason: 'MILP must not return duals');
    });
  });

  group('staff scheduling (integer MILP)', () {
    test('minimum headcount with every day covered', () async {
      const demand = [17, 13, 15, 19, 14, 16, 11];

      final model = MathOptModel(name: 'Staff_Schedule');
      final starters = [
        for (var i = 0; i < 7; i++) model.integer('s$i', lower: 0),
      ];
      ExpressionNode total = const ConstantNode(0);
      for (final s in starters) {
        total += s.asExpr;
      }
      model.minimize(total);
      for (var d = 0; d < 7; d++) {
        ExpressionNode cover = const ConstantNode(0);
        for (var o = 0; o < 5; o++) {
          cover += starters[(d - o + 7) % 7].asExpr;
        }
        model.add((cover >= demand[d]).named('day_$d'));
      }

      final r = await model.solve();
      expectOptimal(r);
      expectCloseTo(r.objectiveValue!, 23.0);

      // Integral headcounts…
      for (var i = 0; i < 7; i++) {
        final v = r.valueOf(starters[i]);
        expect(v, closeTo(v.roundToDouble(), 1e-6),
            reason: 'starter s$i = $v is not integral');
      }
      // …and independently verified daily coverage.
      for (var d = 0; d < 7; d++) {
        var onDuty = 0.0;
        for (var o = 0; o < 5; o++) {
          onDuty += r.valueOf(starters[(d - o + 7) % 7]);
        }
        expect(onDuty, greaterThanOrEqualTo(demand[d] - 1e-6),
            reason: 'day $d understaffed: $onDuty < ${demand[d]}');
      }
    });
  });

  group('mixed production (integer + continuous)', () {
    test('integer machines with continuous output', () async {
      // 2 machines (integer) produce 2 goods (continuous); each machine
      // yields at most 10 units; demand needs ≥ 12 units of each good.
      final model = MathOptModel(name: 'Mixed');
      final machines = model.integer('machines', lower: 0, upper: 5);
      final g1 = model.continuous('good1', lower: 0);
      final g2 = model.continuous('good2', lower: 0);
      // Capacity: total goods ≤ 10 per machine (RHS must stay numeric,
      // so the machine term is moved to the left-hand side).
      model.add((g1.asExpr + g2.asExpr - machines.asExpr * 10) <= 0);
      model.add(g1 >= 12);
      model.add(g2 >= 12);
      // Machine cost 100, goods profit 10 each → fewest machines, then
      // produce to full capacity (extra goods only reduce the objective).
      model.minimize(machines * 100 - g1 * 10 - g2 * 10);

      final r = await model.solve();
      expectOptimal(r);
      // 3 machines (capacity 30 ≥ demand 24), lines full: objective 0.
      expectCloseTo(r.valueOf(machines), 3.0);
      expectCloseTo(r.valueOf(g1) + r.valueOf(g2), 30.0);
      expect(r.valueOf(g1), greaterThanOrEqualTo(12.0 - 1e-6));
      expect(r.valueOf(g2), greaterThanOrEqualTo(12.0 - 1e-6));
      expectCloseTo(r.objectiveValue!, 0.0);
    });
  });
}
