import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// Task assignment (Binary MILP): who does what cheapest?
class AssignmentProblem extends DemoProblem {
  static const _workers = ['Ali', 'Sara', 'Omar', 'Lina', 'Hadi'];
  static const _tasks = ['Cook', 'Serve', 'Clean', 'Stock', 'Host'];
  static const _cost = [
    [9.0, 2.0, 7.0, 8.0, 5.0],
    [6.0, 4.0, 3.0, 7.0, 9.0],
    [5.0, 8.0, 1.0, 8.0, 4.0],
    [7.0, 6.0, 9.0, 4.0, 2.0],
    [8.0, 5.0, 6.0, 9.0, 3.0],
  ];

  late List<List<Variable>> _assign;

  @override
  String get title => 'Task Assignment';

  @override
  String get tagline => 'Match 5 workers to 5 shifts cheapest.';

  @override
  String get technique => 'Binary MILP • HiGHS';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.medium;

  @override
  String get story =>
      'A restaurant has five workers and five evening shifts, each worker '
      'with a different "cost" (overtime, preference) per shift. Everyone '
      'takes exactly one shift and every shift gets exactly one worker — '
      'what is the cheapest valid roster?';

  @override
  String get difficultyReason =>
      'Medium: a square grid of yes/no variables with two matching '
      'families (every row sums to 1, every column sums to 1).';

  @override
  List<String> get modelingNotes => const [
    'Variables: assign[w][t] = 1 if worker w takes task t (binary).',
    'Objective: minimize Σ cost[w][t]·assign[w][t].',
    'Constraints: each row == 1 (one shift each), each column == 1.',
  ];

  @override
  MathOptModel createModel() {
    final n = _workers.length;
    final model = MathOptModel(name: 'Assignment');
    _assign = [
      for (var w = 0; w < n; w++)
        [for (var t = 0; t < n; t++) model.binary('do_${w}_$t')],
    ];
    for (var w = 0; w < n; w++) {
      ExpressionNode row = const ConstantNode(0);
      for (var t = 0; t < n; t++) {
        row += _assign[w][t].asExpr;
      }
      model.add((row.eq(1)).named('worker_$w'));
    }
    for (var t = 0; t < n; t++) {
      ExpressionNode col = const ConstantNode(0);
      for (var w = 0; w < n; w++) {
        col += _assign[w][t].asExpr;
      }
      model.add((col.eq(1)).named('task_$t'));
    }
    ExpressionNode total = const ConstantNode(0);
    for (var w = 0; w < n; w++) {
      for (var t = 0; t < n; t++) {
        total += _assign[w][t] * _cost[w][t];
      }
    }
    model.minimize(total);
    return model;
  }

  @override
  String describeResult(SolveResult result) {
    final lines = <String>[
      'Minimum cost: \$${result.objectiveValue!.toStringAsFixed(0)}',
    ];
    for (var w = 0; w < _workers.length; w++) {
      for (var t = 0; t < _tasks.length; t++) {
        if (result.valueOf(_assign[w][t]) > 0.5) {
          lines.add(
            '${_workers[w]} → ${_tasks[t]} '
            '(\$${_cost[w][t].toStringAsFixed(0)})',
          );
        }
      }
    }
    return lines.join('\n');
  }
}
