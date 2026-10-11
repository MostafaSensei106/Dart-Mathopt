/// Stress tests: factory-scale and delivery-scale models with seeded
/// randomness (deterministic), validated by independent recomputation —
/// the same shapes as the showcase examples, 10–100x larger.
@Timeout(Duration(minutes: 3))
library;

import 'dart:math' as math;

import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUpAll(ensureNativeInit);

  group('factory scale: 400 products x 60 resources (LP)', () {
    test('optimal, feasible, objective independently recomputed', () async {
      const nProducts = 400;
      const nResources = 60;
      final rng = math.Random(42);

      final profit = List.generate(nProducts, (_) => 1 + rng.nextDouble() * 99);
      final use = List.generate(
        nProducts,
        (_) => List.generate(nResources, (_) => rng.nextDouble() * 5),
      );
      final demandCap = List.generate(
        nProducts,
        (_) => 5 + rng.nextDouble() * 15,
      );
      // Capacities at 60% of total appetite → binding but feasible.
      final capacity = List.generate(nResources, (j) {
        var total = 0.0;
        for (var i = 0; i < nProducts; i++) {
          total += use[i][j] * demandCap[i];
        }
        return total * 0.6;
      });

      final model = MathOptModel(name: 'Factory_Stress');
      final qty = [
        for (var i = 0; i < nProducts; i++)
          model.continuous('qty_$i', lower: 0, upper: demandCap[i]),
      ];
      ExpressionNode gain = const ConstantNode(0);
      for (var i = 0; i < nProducts; i++) {
        gain += qty[i] * profit[i];
      }
      model.maximize(gain);
      for (var j = 0; j < nResources; j++) {
        ExpressionNode load = const ConstantNode(0);
        for (var i = 0; i < nProducts; i++) {
          load += qty[i] * use[i][j];
        }
        model.add((load <= capacity[j]).named('res_$j'));
      }

      final sw = Stopwatch()..start();
      final r = await model.solve();
      sw.stop();
      expectOptimal(r, reason: 'factory LP should solve to optimality');
      // ignore: avoid_print
      print(
        'factory 400x60 solved in ${sw.elapsedMilliseconds} ms '
        '(engine: ${r.statistics.solveTimeMs} ms)',
      );

      // Full objective recomputation.
      var expected = 0.0;
      for (var i = 0; i < nProducts; i++) {
        final v = r.valueOf(qty[i]);
        expect(v, greaterThanOrEqualTo(-1e-6));
        expect(v, lessThanOrEqualTo(demandCap[i] + 1e-5));
        expected += v * profit[i];
      }
      expectCloseTo(r.objectiveValue!, expected, 1e-4);

      // Every resource respected (recomputed from scratch).
      for (var j = 0; j < nResources; j++) {
        var load = 0.0;
        for (var i = 0; i < nProducts; i++) {
          load += r.valueOf(qty[i]) * use[i][j];
        }
        expect(
          load,
          lessThanOrEqualTo(capacity[j] * (1 + 1e-7) + 1e-6),
          reason: 'resource $j over capacity: $load > ${capacity[j]}',
        );
      }
    });
  });

  group('delivery scale: 15 factories x 40 warehouses (LP)', () {
    test('balanced network ships exact with recomputed cost', () async {
      const nF = 15;
      const nW = 40;
      final rng = math.Random(7);

      final supply = List.generate(nF, (_) => 50 + rng.nextDouble() * 150);
      final demand = List.generate(nW, (_) => 20 + rng.nextDouble() * 80);
      // Balance totals by scaling demands to the supply sum (keeps every
      // demand positive and the model feasible by construction).
      final supplyTotal = supply.reduce((a, b) => a + b);
      final demandTotal = demand.reduce((a, b) => a + b);
      for (var j = 0; j < nW; j++) {
        demand[j] = demand[j] * supplyTotal / demandTotal;
      }

      final cost = List.generate(
        nF,
        (_) => List.generate(nW, (_) => 1 + rng.nextDouble() * 19),
      );

      final model = MathOptModel(name: 'Delivery_Stress');
      final ship = [
        for (var i = 0; i < nF; i++)
          [
            for (var j = 0; j < nW; j++)
              model.continuous('s_${i}_$j', lower: 0),
          ],
      ];
      for (var i = 0; i < nF; i++) {
        ExpressionNode out = const ConstantNode(0);
        for (var j = 0; j < nW; j++) {
          out += ship[i][j].asExpr;
        }
        model.add((out <= supply[i]).named('supply_$i'));
      }
      for (var j = 0; j < nW; j++) {
        ExpressionNode incoming = const ConstantNode(0);
        for (var i = 0; i < nF; i++) {
          incoming += ship[i][j].asExpr;
        }
        model.add(incoming.eq(demand[j]).named('demand_$j'));
      }
      ExpressionNode total = const ConstantNode(0);
      for (var i = 0; i < nF; i++) {
        for (var j = 0; j < nW; j++) {
          total += ship[i][j] * cost[i][j];
        }
      }
      model.minimize(total);

      final sw = Stopwatch()..start();
      final r = await model.solve();
      sw.stop();
      expectOptimal(r, reason: 'balanced transport must be optimal');
      // ignore: avoid_print
      print(
        'delivery 15x40 solved in ${sw.elapsedMilliseconds} ms '
        '(engine: ${r.statistics.solveTimeMs} ms)',
      );

      for (var i = 0; i < nF; i++) {
        var out = 0.0;
        for (var j = 0; j < nW; j++) {
          final v = r.valueOf(ship[i][j]);
          expect(v, greaterThanOrEqualTo(-1e-6));
          out += v;
        }
        expect(out, lessThanOrEqualTo(supply[i] + 1e-5));
      }
      for (var j = 0; j < nW; j++) {
        var incoming = 0.0;
        for (var i = 0; i < nF; i++) {
          incoming += r.valueOf(ship[i][j]);
        }
        expectCloseTo(incoming, demand[j], 1e-4);
      }
      var expected = 0.0;
      for (var i = 0; i < nF; i++) {
        for (var j = 0; j < nW; j++) {
          expected += r.valueOf(ship[i][j]) * cost[i][j];
        }
      }
      expectCloseTo(r.objectiveValue!, expected, 1e-3);
    });
  });

  group('knapsack scale: 80 items (MILP)', () {
    test('integral optimal packing within capacity', () async {
      const n = 80;
      final rng = math.Random(123);
      final weights = List.generate(n, (_) => 1 + rng.nextDouble() * 19);
      final values = List.generate(n, (_) => 10 + rng.nextDouble() * 490);
      final totalW = weights.reduce((a, b) => a + b);
      final capacity = totalW * 0.3;

      final model = MathOptModel(name: 'Knapsack_Stress');
      final take = [for (var i = 0; i < n; i++) model.binary('t$i')];
      ExpressionNode value = const ConstantNode(0);
      ExpressionNode weight = const ConstantNode(0);
      for (var i = 0; i < n; i++) {
        value += take[i] * values[i];
        weight += take[i] * weights[i];
      }
      model.maximize(value);
      model.add((weight <= capacity).named('capacity'));

      final sw = Stopwatch()..start();
      final r = await model.solve();
      sw.stop();
      expectOptimal(r, reason: '80-item knapsack should solve to optimality');
      // ignore: avoid_print
      print('knapsack x80 solved in ${sw.elapsedMilliseconds} ms');

      var w = 0.0, v = 0.0;
      for (var i = 0; i < n; i++) {
        final t = r.valueOf(take[i]);
        expect(
          t,
          anyOf(closeTo(0.0, 1e-6), closeTo(1.0, 1e-6)),
          reason: 'item $i not integral: $t',
        );
        w += t * weights[i];
        v += t * values[i];
      }
      expect(w, lessThanOrEqualTo(capacity + 1e-5));
      expectCloseTo(r.objectiveValue!, v, 1e-4);
      // Non-trivial: something actually packed.
      expect(v, greaterThan(0));
    });
  });
}
