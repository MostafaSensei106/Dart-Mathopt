import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// Level 2 — knapsack / packing (Binary MILP).
class KnapsackProblem extends DemoProblem {
  static const _names = ['Laptop', 'Camera', 'Tablet', 'Watch'];
  static const _weights = [2.0, 1.5, 0.8, 0.2];
  static const _values = [1000.0, 800.0, 400.0, 500.0];
  static const _capacity = 3.0;

  late List<Variable> _packed;

  @override
  String get title => 'Backpack Packing';

  @override
  String get tagline => 'Pick items for max value within 3 kg.';

  @override
  String get technique => 'Binary MILP • HiGHS';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.medium;

  @override
  String get story =>
      'You are packing a bag that holds $_capacity kg. Four gadgets compete '
      'for space, each with a weight and a value. Which combination maximizes '
      'total value without breaking the weight limit?';

  @override
  String get difficultyReason =>
      'Medium: yes/no choices need binary (0/1) variables, turning the LP '
      'into a MILP with a combinatorial search space.';

  @override
  List<String> get modelingNotes => const [
    'Variables: one binary per item (1 = packed, 0 = skipped).',
    'Objective: maximize Σ value·packed.',
    'Constraint: Σ weight·packed ≤ 3.0 (single capacity row).',
  ];

  @override
  MathOptModel createModel() {
    final model = MathOptModel(name: 'Knapsack');
    _packed = [for (final n in _names) model.binary('pack_$n')];
    ExpressionNode value = const ConstantNode(0);
    ExpressionNode weight = const ConstantNode(0);
    for (var i = 0; i < _names.length; i++) {
      value += _packed[i] * _values[i];
      weight += _packed[i] * _weights[i];
    }
    model.maximize(value);
    model.add((weight <= _capacity).named('capacity'));
    return model;
  }

  @override
  String describeResult(SolveResult result) {
    final lines = <String>[
      'Optimal value: \$${result.objectiveValue!.toStringAsFixed(0)}',
    ];
    for (var i = 0; i < _names.length; i++) {
      final take = result.valueOf(_packed[i]) > 0.5;
      lines.add(
        '${take ? 'PACK ' : 'skip '} ${_names[i]} '
        '(w=${_weights[i]}, v=\$${_values[i].toStringAsFixed(0)})',
      );
    }
    return lines.join('\n');
  }
}
