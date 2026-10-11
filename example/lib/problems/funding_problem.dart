import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// Project funding (binary MILP): pick at most one project per category
/// under a capital budget for maximum return.
class FundingProblem extends DemoProblem {
  static const _namesA = ['App Redesign', 'Ad Campaign', 'CRM Upgrade'];
  static const _costA = [30.0, 40.0, 50.0];
  static const _profitA = [45.0, 55.0, 70.0];
  static const _namesB = ['Warehouse Bot', 'Solar Roof', 'Fleet Vans'];
  static const _costB = [20.0, 35.0, 45.0];
  static const _profitB = [30.0, 48.0, 60.0];
  static const _budget = 100.0;

  late List<Variable> _pickA;
  late List<Variable> _pickB;

  @override
  String get title => 'Project Funding';

  @override
  String get tagline => 'Fund at most one project per team, best return.';

  @override
  String get technique => 'Binary MILP • HiGHS';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.medium;

  @override
  String get story =>
      'Two teams pitch three projects each, but focus rules allow funding '
      'at most one project per team. Total capital is '
      '\$${_budget.toStringAsFixed(0)}k. Which projects maximize return?';

  @override
  String get difficultyReason =>
      'Medium: binary choices plus a shared budget row. The per-team '
      'exclusivity uses the atMostOne helper instead of hand-written rows.';

  @override
  List<String> get modelingNotes => const [
    'Variables: fund/don\'t-fund per project (binary).',
    'Objective: maximize Σ profit·pick.',
    'Constraints: atMostOne per team; total cost ≤ budget.',
  ];

  @override
  MathOptModel createModel() {
    final model = MathOptModel(name: 'Project_Funding');
    _pickA = [for (var i = 0; i < 3; i++) model.binary('fund_a$i')];
    _pickB = [for (var i = 0; i < 3; i++) model.binary('fund_b$i')];
    model.maximize(
      Expr.dotLists(_pickA, _profitA) + Expr.dotLists(_pickB, _profitB),
    );
    model.addAll([
      atMostOne(_pickA, name: 'focus_a'),
      atMostOne(_pickB, name: 'focus_b'),
      (Expr.dotLists(_pickA, _costA) + Expr.dotLists(_pickB, _costB) <= _budget)
          .named('budget'),
    ]);
    return model;
  }

  @override
  String describeResult(SolveResult result) {
    final funded = <String>[
      for (var i = 0; i < 3; i++)
        if (result.valueOf(_pickA[i]) > 0.5) _namesA[i],
      for (var i = 0; i < 3; i++)
        if (result.valueOf(_pickB[i]) > 0.5) _namesB[i],
    ];
    return 'Best return: \$${result.objectiveValue!.toStringAsFixed(0)}k\n'
        'Funded: ${funded.join(', ')}';
  }
}
