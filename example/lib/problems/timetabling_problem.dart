import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// Lecture timetabling (binary MILP): every course gets exactly one slot,
/// rooms hold at most two courses per slot, preferences decide the rest.
class TimetablingProblem extends DemoProblem {
  static const _courses = ['Math', 'Physics', 'History'];
  static const _slots = ['Mon 9am', 'Tue 11am', 'Thu 2pm'];

  /// Preference cost: lower means the lecturer likes that slot more.
  static const _cost = [
    [1.0, 4.0, 3.0], // Math
    [5.0, 1.0, 2.0], // Physics
    [2.0, 3.0, 1.0], // History
  ];
  static const _roomCap = 2; // courses per slot

  late VarGrid _assign;

  @override
  String get title => 'Lecture Timetabling';

  @override
  String get tagline => 'One slot per course, rooms fit two, happiest staff.';

  @override
  String get technique => 'Binary MILP • HiGHS';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.hard;

  @override
  String get story =>
      'Three courses need one lecture slot each across three time slots. '
      'Rooms fit up to $_roomCap courses per slot, and every lecturer '
      'ranked the slots. Assign slots to minimize total dissatisfaction.';

  @override
  String get difficultyReason =>
      'Hard: a 3×3 binary grid with row-wise exactlyOne plus column '
      'capacities. The indexed grid and the exactlyOne helper carry the '
      'structure; HiGHS proves the optimum.';

  @override
  List<String> get modelingNotes => const [
    'Variables: 3×3 binary grid (course × slot).',
    'Objective: minimize Σ preference-cost·assign.',
    'Constraints: exactlyOne slot per course row; ≤ 2 per slot column.',
  ];

  @override
  MathOptModel createModel() {
    final model = MathOptModel(name: 'Lecture_Timetable');
    _assign = model.binaryGrid('slot', rows: 3, cols: 3);
    model.addAll([
      for (var c = 0; c < 3; c++) exactlyOne(_assign.row(c), name: 'course_$c'),
      for (var s = 0; s < 3; s++)
        (Expr.sumVars(_assign.column(s)) <= _roomCap).named('room_$s'),
    ]);
    model.minimize(
      Expr.dotLists(_assign.toList(), [for (final row in _cost) ...row]),
    );
    return model;
  }

  @override
  String describeResult(SolveResult result) {
    final lines = <String>[
      'Dissatisfaction: ${result.objectiveValue!.toStringAsFixed(0)}',
    ];
    for (var c = 0; c < 3; c++) {
      for (var s = 0; s < 3; s++) {
        if (result.valueOf(_assign.at([c, s])) > 0.5) {
          lines.add('${_courses[c]} → ${_slots[s]}');
        }
      }
    }
    return lines.join('\n');
  }
}
