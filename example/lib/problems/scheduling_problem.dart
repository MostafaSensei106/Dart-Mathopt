import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// Level 3  weekly staff scheduling (Integer MILP).
class SchedulingProblem extends DemoProblem {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _demand = [17, 13, 15, 19, 14, 16, 11];

  late List<Variable> _starters;

  @override
  String get title => 'Staff Scheduling';

  @override
  String get tagline => 'Cover every shift with the fewest workers.';

  @override
  String get technique => 'Integer MILP • HiGHS';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.hard;

  @override
  String get story =>
      'A restaurant needs a minimum crew every day (${_demand.join(', ')}). '
      'Each hire works 5 consecutive days. How many people should start on '
      'each weekday to cover demand with the smallest possible headcount?';

  @override
  String get difficultyReason =>
      'Hard: integer headcounts plus cyclic coverage  every day is covered '
      'by shifts started on 5 different days, wrapping around the week.';

  @override
  List<String> get modelingNotes => const [
    'Variables: starters[i] = hires beginning on day i (integer, ≥ 0).',
    'Objective: minimize Σ starters.',
    'Constraints: each day d gets starters[d] + previous 4 days ≥ demand[d].',
  ];

  @override
  MathOptModel createModel() {
    final model = MathOptModel(name: 'Staff_Schedule');
    _starters = [
      for (var i = 0; i < 7; i++) model.integer('start_${_days[i]}', lower: 0),
    ];
    ExpressionNode total = const ConstantNode(0);
    for (final s in _starters) {
      total += s.asExpr;
    }
    model.minimize(total);
    for (var d = 0; d < 7; d++) {
      ExpressionNode coverage = const ConstantNode(0);
      for (var offset = 0; offset < 5; offset++) {
        coverage += _starters[(d - offset + 7) % 7].asExpr;
      }
      model.add((coverage >= _demand[d]).named('cover_${_days[d]}'));
    }
    return model;
  }

  @override
  String describeResult(SolveResult result) {
    final lines = <String>[
      'Minimum staff: ${result.objectiveValue!.toStringAsFixed(0)}',
    ];
    for (var i = 0; i < 7; i++) {
      lines.add(
        'Start ${_days[i]}: '
        '${result.valueOf(_starters[i]).toStringAsFixed(0)} workers',
      );
    }
    return lines.join('\n');
  }
}
