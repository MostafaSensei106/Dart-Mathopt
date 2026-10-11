/// Shared deterministic model builders for performance tests.
///
/// Same shapes and seeds everywhere (scaling suite, latency percentiles,
/// UI responsiveness), so numbers stay comparable across files.
library;

import 'dart:math' as math;

import 'package:dart_mathopt/dart_mathopt.dart';

MathOptModel buildTransport(int factories, int warehouses, int seed) {
  final rng = math.Random(seed);
  final supply = List.generate(factories, (_) => 50 + rng.nextDouble() * 150);
  final demand = List.generate(warehouses, (_) => 20 + rng.nextDouble() * 80);
  final supplyTotal = supply.reduce((a, b) => a + b);
  final demandTotal = demand.reduce((a, b) => a + b);
  for (var j = 0; j < warehouses; j++) {
    demand[j] = demand[j] * supplyTotal / demandTotal;
  }
  final cost = List.generate(
    factories,
    (_) => List.generate(warehouses, (_) => 1 + rng.nextDouble() * 19),
  );
  final model = MathOptModel(name: 'Bench_Transport');
  final ship = [
    for (var i = 0; i < factories; i++)
      [
        for (var j = 0; j < warehouses; j++)
          model.continuous('s_${i}_$j', lower: 0),
      ],
  ];
  for (var i = 0; i < factories; i++) {
    ExpressionNode out = const ConstantNode(0);
    for (var j = 0; j < warehouses; j++) {
      out += ship[i][j].asExpr;
    }
    model.add(out <= supply[i]);
  }
  for (var j = 0; j < warehouses; j++) {
    ExpressionNode incoming = const ConstantNode(0);
    for (var i = 0; i < factories; i++) {
      incoming += ship[i][j].asExpr;
    }
    model.add(incoming.eq(demand[j]));
  }
  ExpressionNode total = const ConstantNode(0);
  for (var i = 0; i < factories; i++) {
    for (var j = 0; j < warehouses; j++) {
      total += ship[i][j] * cost[i][j];
    }
  }
  model.minimize(total);
  return model;
}

MathOptModel buildFactory(int products, int resources, int seed) {
  final rng = math.Random(seed);
  final profit = List.generate(products, (_) => 1 + rng.nextDouble() * 99);
  final use = List.generate(
    products,
    (_) => List.generate(resources, (_) => rng.nextDouble() * 5),
  );
  final cap = List.generate(products, (_) => 5 + rng.nextDouble() * 15);
  final capacity = List.generate(resources, (j) {
    var total = 0.0;
    for (var i = 0; i < products; i++) {
      total += use[i][j] * cap[i];
    }
    return total * 0.6;
  });
  final model = MathOptModel(name: 'Bench_Factory');
  final qty = [
    for (var i = 0; i < products; i++)
      model.continuous('q$i', lower: 0, upper: cap[i]),
  ];
  ExpressionNode gain = const ConstantNode(0);
  for (var i = 0; i < products; i++) {
    gain += qty[i] * profit[i];
  }
  model.maximize(gain);
  for (var j = 0; j < resources; j++) {
    ExpressionNode load = const ConstantNode(0);
    for (var i = 0; i < products; i++) {
      load += qty[i] * use[i][j];
    }
    model.add(load <= capacity[j]);
  }
  return model;
}

MathOptModel buildKnapsack(int items, int seed) {
  final rng = math.Random(seed);
  final weights = List.generate(items, (_) => 1 + rng.nextDouble() * 19);
  final values = List.generate(items, (_) => 10 + rng.nextDouble() * 490);
  final capacity = weights.reduce((a, b) => a + b) * 0.3;
  final model = MathOptModel(name: 'Bench_Knapsack');
  final take = [for (var i = 0; i < items; i++) model.binary('t$i')];
  ExpressionNode value = const ConstantNode(0);
  ExpressionNode weight = const ConstantNode(0);
  for (var i = 0; i < items; i++) {
    value += take[i] * values[i];
    weight += take[i] * weights[i];
  }
  model.maximize(value);
  model.add(weight <= capacity);
  return model;
}

MathOptModel buildAssignment(int n, int seed) {
  final rng = math.Random(seed);
  final cost = List.generate(
    n,
    (_) => List.generate(n, (_) => 1 + rng.nextDouble() * 9),
  );
  final model = MathOptModel(name: 'Bench_Assignment');
  final x = [
    for (var i = 0; i < n; i++)
      [for (var j = 0; j < n; j++) model.binary('x_${i}_$j')],
  ];
  for (var i = 0; i < n; i++) {
    ExpressionNode row = const ConstantNode(0);
    for (var j = 0; j < n; j++) {
      row += x[i][j].asExpr;
    }
    model.add(row.eq(1));
  }
  for (var j = 0; j < n; j++) {
    ExpressionNode col = const ConstantNode(0);
    for (var i = 0; i < n; i++) {
      col += x[i][j].asExpr;
    }
    model.add(col.eq(1));
  }
  ExpressionNode total = const ConstantNode(0);
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < n; j++) {
      total += x[i][j] * cost[i][j];
    }
  }
  model.minimize(total);
  return model;
}
