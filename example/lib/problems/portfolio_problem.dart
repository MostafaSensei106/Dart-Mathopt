import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// NEW — investment portfolio (LP with risk + policy constraints).
class PortfolioProblem extends DemoProblem {
  static const _assets = ['Stocks A', 'Stocks B', 'Bonds C'];
  static const _returns = [0.08, 0.12, 0.05]; // expected yearly return
  static const _risks = [0.06, 0.10, 0.02]; // risk score per dollar
  static const _budget = 10000.0;
  static const _maxRisk = 500.0; // average risk ≤ 5% of budget
  static const _minSafe = 2000.0; // at least $2k in safe bonds
  static const _maxB = 5000.0; // at most $5k in risky stocks B

  late List<Variable> _amounts;

  @override
  String get title => 'Investment Mix';

  @override
  String get tagline => 'Best \$10k portfolio under a risk cap.';

  @override
  String get technique => 'LP • Clarabel';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.medium;

  @override
  String get story =>
      'You have \$${_budget.toStringAsFixed(0)} to split between two stock '
      'funds and safe bonds. Policy says: keep average risk ≤ 5%, hold at '
      'least \$$_minSafe in bonds, put at most \$$_maxB in the hot fund B. '
      'Maximize expected yearly return.';

  @override
  String get difficultyReason =>
      'Medium: one equality plus three different policy rows, and the '
      'winner is not obvious — the hottest fund eats the risk budget '
      'fastest. Solved here with Clarabel to show engine choice.';

  @override
  List<String> get modelingNotes => const [
    'Variables: dollars in A, B, C (continuous, ≥ 0).',
    'Objective: maximize Σ return·amount.',
    'Constraints: amounts sum to \$10k; risk ≤ 500; C ≥ \$2k; B ≤ \$5k.',
  ];

  @override
  MathOptModel createModel() {
    final model = MathOptModel(name: 'Portfolio');
    _amounts = [for (final a in _assets) model.continuous(a, lower: 0)];
    ExpressionNode gain = const ConstantNode(0);
    ExpressionNode risk = const ConstantNode(0);
    ExpressionNode total = const ConstantNode(0);
    for (var i = 0; i < _assets.length; i++) {
      gain += _amounts[i] * _returns[i];
      risk += _amounts[i] * _risks[i];
      total += _amounts[i].asExpr;
    }
    model.maximize(gain);
    model.add((total.eq(_budget)).named('budget'));
    model.add((risk <= _maxRisk).named('risk_cap'));
    model.add((_amounts[2] >= _minSafe).named('min_bonds'));
    model.add((_amounts[1] <= _maxB).named('max_hot_stocks'));
    return model;
  }

  /// Portfolio is showcased on Clarabel to demonstrate engine choice.
  @override
  SolveOptions? get preferredOptions =>
      const SolveOptions(solver: SolverPreference.clarabel);

  @override
  String describeResult(SolveResult result) {
    final lines = <String>[
      'Expected return: \$${result.objectiveValue!.toStringAsFixed(2)}/yr',
    ];
    for (var i = 0; i < _assets.length; i++) {
      lines.add(
        '${_assets[i]}: '
        '\$${result.valueOf(_amounts[i]).toStringAsFixed(0)}',
      );
    }
    return lines.join('\n');
  }
}
