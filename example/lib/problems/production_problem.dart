import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// Level 1  factory production planning (LP).
class ProductionProblem extends DemoProblem {
  late Variable _a;
  late Variable _b;

  @override
  String get title => 'Factory Production';

  @override
  String get tagline => 'How many units of A and B maximize profit?';

  @override
  String get technique => 'LP • HiGHS';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.easy;

  @override
  String get story =>
      'A factory makes two products. Product A earns \$30 and product B earns '
      '\$50. Each unit consumes machine hours and raw material, both limited '
      'per day. How many of each should we produce for maximum profit?';

  @override
  String get difficultyReason =>
      'Easy: only two continuous variables and two upper-bound constraints. '
      'The optimum sits at a corner of the feasible polygon.';

  @override
  List<String> get modelingNotes => const [
    'Variables: units of A and B (continuous, ≥ 0).',
    'Objective: maximize 30·A + 50·B.',
    'Constraints: machine hours 2·A + B ≤ 20, material A + 3·B ≤ 15.',
  ];

  @override
  MathOptModel createModel() {
    final model = MathOptModel(name: 'Production_Plan');
    _a = model.continuous('Product_A', lower: 0);
    _b = model.continuous('Product_B', lower: 0);
    model.maximize(_a * 30 + _b * 50);
    model.add(((_a * 2 + _b * 1) <= 20).named('machine_hours'));
    model.add(((_a * 1 + _b * 3) <= 15).named('raw_material'));
    return model;
  }

  @override
  SolveOptions get preferredOptions =>
      const SolveOptions(solver: SolverPreference.highs);

  @override
  String describeResult(SolveResult result) {
    final a = result.valueOf(_a);
    final b = result.valueOf(_b);
    return 'Optimal profit: \$${result.objectiveValue!.toStringAsFixed(1)}\n'
        'Produce A: ${a.toStringAsFixed(1)} units\n'
        'Produce B: ${b.toStringAsFixed(1)} units';
  }
}
