import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// Level 4  transportation / logistics network (LP on a 2-D grid).
class TransportationProblem extends DemoProblem {
  static const _factories = ['F1', 'F2', 'F3'];
  static const _warehouses = ['W1', 'W2', 'W3', 'W4'];
  static const _supply = [20.0, 30.0, 25.0];
  static const _demand = [15.0, 20.0, 18.0, 22.0];
  static const _cost = [
    [4.0, 6.0, 8.0, 7.0],
    [5.0, 3.0, 6.0, 9.0],
    [7.0, 8.0, 4.0, 5.0],
  ];

  late List<List<Variable>> _routes;

  @override
  String get title => 'Delivery Network';

  @override
  String get tagline => 'Ship from 3 factories to 4 warehouses cheapest.';

  @override
  String get technique => 'LP • HiGHS (+ duals)';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.medium;

  @override
  String get story =>
      'Three factories supply four warehouses with limited stock '
      '(${_supply.join(', ')}) and fixed orders (${_demand.join(', ')}). '
      'Shipping costs differ per route. How much goes on each truck?';

  @override
  String get difficultyReason =>
      'Medium: a 2-D grid of variables with two constraint families '
      '(supply ≤, demand ==). Pure LP, so we also get shadow prices.';

  @override
  List<String> get modelingNotes => const [
    'Variables: routes[i][j] = units shipped factory i → warehouse j.',
    'Objective: minimize Σ cost[i][j]·routes[i][j].',
    'Constraints: factory totals ≤ supply; warehouse totals == demand.',
  ];

  @override
  MathOptModel createModel() {
    final model = MathOptModel(name: 'Transportation');
    _routes = [
      for (var i = 0; i < _factories.length; i++)
        [
          for (var j = 0; j < _warehouses.length; j++)
            model.continuous(
              'ship_${_factories[i]}_${_warehouses[j]}',
              lower: 0,
            ),
        ],
    ];
    for (var i = 0; i < _factories.length; i++) {
      ExpressionNode shipped = const ConstantNode(0);
      for (var j = 0; j < _warehouses.length; j++) {
        shipped += _routes[i][j].asExpr;
      }
      model.add((shipped <= _supply[i]).named('supply_${_factories[i]}'));
    }
    for (var j = 0; j < _warehouses.length; j++) {
      ExpressionNode received = const ConstantNode(0);
      for (var i = 0; i < _factories.length; i++) {
        received += _routes[i][j].asExpr;
      }
      model.add((received.eq(_demand[j])).named('demand_${_warehouses[j]}'));
    }
    ExpressionNode total = const ConstantNode(0);
    for (var i = 0; i < _factories.length; i++) {
      for (var j = 0; j < _warehouses.length; j++) {
        total += _routes[i][j] * _cost[i][j];
      }
    }
    model.minimize(total);
    return model;
  }

  @override
  String describeResult(SolveResult result) {
    final lines = <String>[
      'Minimum cost: \$${result.objectiveValue!.toStringAsFixed(1)}',
      '',
    ];
    for (var i = 0; i < _factories.length; i++) {
      final row = [
        for (var j = 0; j < _warehouses.length; j++)
          result.valueOf(_routes[i][j]).toStringAsFixed(1).padLeft(6),
      ].join(' ');
      lines.add('${_factories[i]}:$row');
    }
    final duals = result.dualValues;
    if (duals != null) {
      lines.add('');
      lines.add('Shadow prices (extra supply/demand value):');
      for (var k = 0; k < duals.length; k++) {
        lines.add('row $k: ${duals[k].toStringAsFixed(3)}');
      }
    }
    return lines.join('\n');
  }
}
