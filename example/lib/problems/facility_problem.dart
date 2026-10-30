import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// Warehouse opening / facility location (fixed-charge MILP).
class FacilityProblem extends DemoProblem {
  static const _sites = ['North', 'East', 'West'];
  static const _stores = ['S1', 'S2', 'S3', 'S4', 'S5'];
  static const _fixed = [100.0, 150.0, 120.0];
  static const _capacity = [60.0, 80.0, 70.0];
  static const _demand = [20.0, 30.0, 25.0, 35.0, 15.0];
  static const _cost = [
    [4.0, 6.0, 8.0, 7.0, 5.0],
    [5.0, 3.0, 6.0, 9.0, 4.0],
    [7.0, 8.0, 4.0, 5.0, 6.0],
  ];

  late List<Variable> _open;
  late List<List<Variable>> _serve;

  @override
  String get title => 'Warehouse Opening';

  @override
  String get tagline => 'Which depots pay off, and who serves whom?';

  @override
  String get technique => 'Fixed-charge MILP • HiGHS';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.hard;

  @override
  String get story =>
      'A retailer can open regional depots (each with a fixed opening cost '
      'and a capacity) to supply five stores with known demand. Opening '
      'everywhere is flexible but expensive; which depots earn their rent, '
      'and how should stores be served?';

  @override
  String get difficultyReason =>
      'Hard: binary open/close choices linked to continuous flows  a '
      'closed depot must ship exactly zero (capacity × open trick).';

  @override
  List<String> get modelingNotes => const [
    'Variables: open[i] binary; serve[i][j] continuous ≥ 0.',
    'Objective: minimize Σ fixed·open + Σ cost·serve.',
    'Constraints: store totals == demand; depot totals ≤ capacity·open.',
  ];

  @override
  MathOptModel createModel() {
    final model = MathOptModel(name: 'Facility_Location');
    _open = [for (final s in _sites) model.binary('open_$s')];
    _serve = [
      for (var i = 0; i < _sites.length; i++)
        [
          for (var j = 0; j < _stores.length; j++)
            model.continuous('serve_${i}_$j', lower: 0),
        ],
    ];
    // Closed depots ship nothing: flow ≤ capacity × open (number × binary).
    for (var i = 0; i < _sites.length; i++) {
      ExpressionNode flow = const ConstantNode(0);
      for (var j = 0; j < _stores.length; j++) {
        flow += _serve[i][j].asExpr;
      }
      model.add((flow - _open[i] * _capacity[i]) <= 0);
    }
    for (var j = 0; j < _stores.length; j++) {
      ExpressionNode got = const ConstantNode(0);
      for (var i = 0; i < _sites.length; i++) {
        got += _serve[i][j].asExpr;
      }
      model.add((got.eq(_demand[j])).named('store_$j'));
    }
    ExpressionNode total = const ConstantNode(0);
    for (var i = 0; i < _sites.length; i++) {
      total += _open[i] * _fixed[i];
      for (var j = 0; j < _stores.length; j++) {
        total += _serve[i][j] * _cost[i][j];
      }
    }
    model.minimize(total);
    return model;
  }

  @override
  String describeResult(SolveResult result) {
    final lines = <String>[
      'Minimum cost: \$${result.objectiveValue!.toStringAsFixed(1)}',
    ];
    for (var i = 0; i < _sites.length; i++) {
      final opened = result.valueOf(_open[i]) > 0.5;
      lines.add('${_sites[i]} depot: ${opened ? 'OPEN' : 'closed'}');
      if (opened) {
        for (var j = 0; j < _stores.length; j++) {
          final v = result.valueOf(_serve[i][j]);
          if (v > 1e-6) {
            lines.add('  → ${_stores[j]}: ${v.toStringAsFixed(1)} units');
          }
        }
      }
    }
    return lines.join('\n');
  }
}
