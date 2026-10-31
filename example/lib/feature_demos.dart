import 'package:dart_mathopt/dart_mathopt.dart';

/// Shared live recipes for the app and console. Each run owns its model.
class FeatureDemo {
  const FeatureDemo(this.title, this.description, this.run);

  final String title;
  final String description;
  final Future<String> Function() run;
}

MathOptModel _lp() {
  final model = MathOptModel(name: 'Engine_comparison');
  final x = model.continuous('x', lower: 0, upper: 10);
  model.maximize(x * 3);
  return model;
}

List<FeatureDemo> buildFeatureDemos() => [
  FeatureDemo(
    'Compare LP engines',
    'Solve the same LP with each available engine; compare objective, '
        'status, timing, and LP dual availability.',
    () async {
      final lines = <String>[];
      for (final engine in SolverPreference.values) {
        if (SolverRegistry.isWeb && engine == SolverPreference.highs) {
          lines.add('highs: unavailable in this WASM build');
          continue;
        }
        final result = await _lp().solve(options: SolveOptions(solver: engine));
        lines.add(
          '${engine.name}: ${result.status.name}, '
          'objective=${result.objectiveValue}, '
          'duals=${result.dualValues}, '
          '${result.statistics.solveTimeUs} µs',
        );
      }
      return lines.join('\n');
    },
  ),
  FeatureDemo(
    'Automatic integer routing',
    'A binary choice uses HiGHS on native. Web reports the MILP '
        'limitation before calling the bridge.',
    () async {
      final model = MathOptModel(name: 'Auto_integer');
      final choices = [model.binary('a'), model.binary('b')];
      model.add(exactlyOne(choices));
      model.maximize(Expr.dotLists(choices, [5, 9]));
      try {
        final result = await model.solve();
        return 'auto → HiGHS\nstatus=${result.status.name}\n'
            'objective=${result.objectiveValue}\n'
            'hasSolution=${result.hasSolution}';
      } on ModelValidationException catch (error) {
        if (!SolverRegistry.isWeb) rethrow;
        return 'Expected web limitation:\n$error';
      }
    },
  ),
  FeatureDemo(
    'Repeated solves and cache invalidation',
    'Solve twice, then add a constraint and solve again. The compiled '
        'request is reused only while the model is unchanged.',
    () async {
      final model = _lp();
      final lines = <String>[];
      for (var i = 0; i < 3; i++) {
        if (i == 2) model.add(model.variables.single <= 4);
        final result = await model.solve();
        lines.add(
          'solve ${i + 1}: cached=${model.lastSolveWasCached}, '
          'objective=${result.objectiveValue}',
        );
      }
      return lines.join('\n');
    },
  ),
  FeatureDemo(
    'Infeasible result and solution guard',
    'Contradictory bounds produce an infeasible status. '
        'requireSolution rejects a result with no usable solution.',
    () async {
      final model = _lp();
      model.add(model.variables.single >= 20);
      final result = await model.solve();
      try {
        result.requireSolution();
      } on SolverExecutionException catch (error) {
        return 'status=${result.status.name}\n'
            'hasSolution=${result.hasSolution}\n$error';
      }
      throw StateError('Expected no solution for contradictory bounds.');
    },
  ),
  FeatureDemo(
    'Unsupported engine validation',
    'Request a binary model on Clarabel, or HiGHS on web. '
        'Both are rejected before FFI.',
    () async {
      final model = MathOptModel(name: 'Unsupported_engine');
      final x = model.binary('x');
      model.maximize(x.asExpr);
      try {
        await model.solve(
          options: SolveOptions(
            solver: SolverRegistry.isWeb
                ? SolverPreference.highs
                : SolverPreference.clarabel,
          ),
        );
      } on ModelValidationException catch (error) {
        return 'Expected validation error:\n$error';
      }
      throw StateError('Expected unsupported engine rejection.');
    },
  ),
];
