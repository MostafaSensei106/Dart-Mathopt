/// Solver scaling benchmarks: how fast does `dart_mathopt` answer as the
/// model grows? Each case solves the same shape at several sizes and the
/// harness reports user-perceived latency (Dart `await` round-trip).
///
/// What to look at:
/// - `engine ms` (from statistics) vs wall time → the gap is Dart/FFI
///   overhead (AST compile + bridge crossing). If the gap dominates on big
///   models, batching DTOs is the next optimization.
/// - LP scales ~linearly; MILP can jump — watch knapsack/assignment rows.
///
/// Run (release native library required):
///
/// ```sh
/// cargo build --release --manifest-path rust/Cargo.toml
/// dart run example/benchmark/scaling_benchmark.dart   # from root
/// dart run benchmark/scaling_benchmark.dart           # from example/
/// ```
library;

import 'dart:math' as math;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dart_mathopt/dart_mathopt.dart';

import '../tool/native_init.dart';

/// One benchmark case: builds the model in [setup], solves in [run].
class _SolveBenchmark extends AsyncBenchmarkBase {
  final String caseName;
  final MathOptModel Function() build;
  final int varCount;
  final int constraintCount;
  late MathOptModel _model;
  SolveResult? lastResult;

  _SolveBenchmark(
    this.caseName,
    this.build, {
    required this.varCount,
    required this.constraintCount,
  }) : super('$caseName (${varCount}v/${constraintCount}c)');

  @override
  Future<void> setup() async {
    _model = build();
  }

  @override
  Future<void> run() async {
    lastResult = await _model.solve();
    if (lastResult!.status != SolveStatus.optimal) {
      throw StateError('$caseName finished ${lastResult!.status}');
    }
  }
}

MathOptModel _transport(int factories, int warehouses, int seed) {
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
      [for (var j = 0; j < warehouses; j++) model.continuous('s_${i}_$j', lower: 0)],
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

MathOptModel _factory(int products, int resources, int seed) {
  final rng = math.Random(seed);
  final profit = List.generate(products, (_) => 1 + rng.nextDouble() * 99);
  final use = List.generate(
    products,
    (_) => List.generate(resources, (_) => rng.nextDouble() * 5),
  );
  final cap =
      List.generate(products, (_) => 5 + rng.nextDouble() * 15);
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

MathOptModel _knapsack(int items, int seed) {
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

MathOptModel _assignment(int n, int seed) {
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

Future<void> main() async {
  await initNativeLib();

  final cases = [
    _SolveBenchmark('transport', () => _transport(5, 10, 1),
        varCount: 50, constraintCount: 15),
    _SolveBenchmark('transport', () => _transport(10, 20, 1),
        varCount: 200, constraintCount: 30),
    _SolveBenchmark('transport', () => _transport(20, 40, 1),
        varCount: 800, constraintCount: 60),
    _SolveBenchmark('factory', () => _factory(100, 20, 2),
        varCount: 100, constraintCount: 20),
    _SolveBenchmark('factory', () => _factory(400, 60, 2),
        varCount: 400, constraintCount: 60),
    _SolveBenchmark('knapsack', () => _knapsack(30, 3),
        varCount: 30, constraintCount: 1),
    _SolveBenchmark('knapsack', () => _knapsack(100, 3),
        varCount: 100, constraintCount: 1),
    _SolveBenchmark('assignment', () => _assignment(5, 4),
        varCount: 25, constraintCount: 10),
    _SolveBenchmark('assignment', () => _assignment(8, 4),
        varCount: 64, constraintCount: 16),
  ];

  for (final c in cases) {
    await c.report();
    final r = c.lastResult!;
    // ignore: avoid_print
    print('  → objective=${r.objectiveValue!.toStringAsFixed(2)} '
        'engine=${r.statistics.solveTimeMs}ms '
        'iters=${r.statistics.iterations}\n');
  }

  RustLib.dispose();
}
