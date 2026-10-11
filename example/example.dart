/// The main console example for `dart_mathopt`.
///
/// Two parts, runnable together or separately:
///
/// - Usage patterns (`patterns`): short API recipes — minimal LP, indexed
///   grids, logical helpers, one model on three engines, honest statuses,
///   and the repeated-solve cache.
/// - Catalog tour (`tour`): all twelve showcase problems (the same ones in
///   the Flutter app): story, live native solve, result, timing.
///
/// Run from the package root OR from `example/`:
///
/// ```sh
/// dart run example/example.dart            # from root: everything
/// dart run example/example.dart tour       # catalog tour only
/// dart run example/example.dart patterns   # usage patterns only
/// dart run example.dart                    # from example/
/// ```
library;

import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:dart_mathopt_example/solve_time.dart';
import 'package:dart_mathopt_example/tour.dart';

Future<void> main(List<String> args) async {
  await DartMathOpt.init();

  final runTour = args.isEmpty || args.contains('tour');
  final runPatterns = args.isEmpty || args.contains('patterns');

  if (runPatterns) await _runPatterns();
  if (runTour) await _runTour();

  DartMathOpt.dispose();
}

// ---------------------------------------------------------------------------
// Part 1 — usage patterns.
// ---------------------------------------------------------------------------

Future<void> _runPatterns() async {
  print('=== Usage patterns ===\n');
  await _minimalLp();
  await _indexedTransport();
  await _logicalChoice();
  await _oneModelThreeEngines();
  await _honestStatuses();
  await _repeatCache();
}

/// Minimal LP: variables, one constraint, objective, guarded result read.
Future<void> _minimalLp() async {
  print('--- 1. Minimal LP ---');
  final model = MathOptModel(name: 'Patterns_Demo');
  final x = model.continuous('x', lower: 0);
  final y = model.continuous('y', lower: 0);
  model.add(x + y <= 4);
  model.maximize(x * 3 + y * 5);

  final result = await model.solve();
  if (result.isOptimal) {
    print('objective=${result.objectiveValue} y=${result.valueOf(y)}\n');
  }
}

/// Indexed grid: rows/columns replace nested index bookkeeping.
Future<void> _indexedTransport() async {
  print('--- 2. Indexed transport (2 factories x 3 warehouses) ---');
  const supply = [20.0, 30.0];
  const demand = [10.0, 15.0, 12.0];
  const cost = [
    [4.0, 6.0, 8.0],
    [5.0, 3.0, 6.0],
  ];
  final model = MathOptModel(name: 'Patterns_Transport');
  final ship = model.continuousGrid('s', rows: 2, cols: 3, lower: 0);
  model.addAll([
    for (var i = 0; i < 2; i++) ship.row(i).sum <= supply[i],
    for (var j = 0; j < 3; j++) Expr.sumVars(ship.column(j)).eq(demand[j]),
  ]);
  model.minimize(
    Expr.dotLists(ship.toList(), [for (final row in cost) ...row]),
  );

  final r = await model.solve();
  print('cost=${r.objectiveValue} optimal=${r.isOptimal}\n');
}

/// Logical helpers: exactly one alternative, no hand-written rows.
Future<void> _logicalChoice() async {
  print('--- 3. exactlyOne picks the cheapest ---');
  final model = MathOptModel(name: 'Patterns_Choice');
  final alt = [for (var i = 0; i < 3; i++) model.binary('a$i')];
  model.add(exactlyOne(alt));
  model.minimize(Expr.dotLists(alt, [5.0, 2.0, 8.0]));

  final s = (await model.solve()).requireSolution();
  final picked = alt.indexWhere((v) => s.valueOf(v) > 0.5);
  print('picked=a$picked cost=${s.objectiveValue}\n');
}

/// Engine choice: the same LP on all three backends.
Future<void> _oneModelThreeEngines() async {
  print('--- 4. One model, three engines ---');
  Future<double?> solveOn(SolverPreference engine) async {
    final model = MathOptModel(name: 'Patterns_Engines');
    final a = model.continuous('A', lower: 0);
    final b = model.continuous('B', lower: 0);
    model.maximize(a * 30 + b * 50);
    model.add((a * 2 + b * 1) <= 20);
    model.add((a * 1 + b * 3) <= 15);
    final r = await model.solve(options: SolveOptions(solver: engine));
    return r.isOptimal ? r.objectiveValue : null;
  }

  for (final engine in [
    SolverPreference.highs,
    SolverPreference.clarabel,
    SolverPreference.microlp,
  ]) {
    print('${engine.name}: objective=${await solveOn(engine)}');
  }
  print('');
}

/// Honest statuses: infeasible models report, they don't throw.
Future<void> _honestStatuses() async {
  print('--- 5. Infeasible is a status, not an exception ---');
  final model = MathOptModel(name: 'Patterns_Infeasible');
  final x = model.continuous('x', lower: 0);
  model.add(x <= 1);
  model.add(x >= 2);
  model.minimize(x.asExpr);

  final r = await model.solve();
  print('status=${r.status.name} hasSolution=${r.hasSolution}');
  try {
    r.requireSolution();
  } on SolverExecutionException catch (e) {
    print('requireSolution threw: ${e.runtimeType}\n');
  }
}

/// Repeated solves reuse the compiled request while the model is frozen.
Future<void> _repeatCache() async {
  print('--- 6. Repeated solves hit the cache ---');
  final model = MathOptModel(name: 'Patterns_Cache');
  final x = model.continuous('x', lower: 0, upper: 4);
  model.maximize(x.asExpr);
  for (var i = 0; i < 2; i++) {
    final sw = Stopwatch()..start();
    await model.solve();
    sw.stop();
    print(
      'solve ${i + 1}: ${formatMicroseconds(sw.elapsedMicroseconds)} '
      'cached=${model.lastSolveWasCached}',
    );
  }
  print('');
}

// ---------------------------------------------------------------------------
// Part 2 — catalog tour (shared with lib/example.dart).
// ---------------------------------------------------------------------------

Future<void> _runTour() => runCatalogTour();
