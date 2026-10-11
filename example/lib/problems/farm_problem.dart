import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// Farm planning (LP on the pure-Rust MicroLP engine).
class FarmProblem extends DemoProblem {
  static const _crops = ['Wheat', 'Corn', 'Olives'];
  static const _profit = [40.0, 60.0, 90.0]; // $ per acre
  static const _water = [2.0, 3.0, 4.0]; // water units per acre
  static const _labor = [1.0, 2.0, 3.0]; // work days per acre
  static const _land = 100.0; // acres
  static const _waterCap = 240.0;
  static const _laborCap = 180.0;

  late List<Variable> _acres;

  @override
  String get title => 'Farm Planning';

  @override
  String get tagline => 'Best crop mix for 100 acres — solved in pure Rust.';

  @override
  String get technique => 'LP • MicroLP';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.easy;

  @override
  String get story =>
      'A farm has ${_land.toStringAsFixed(0)} acres, ${_waterCap.toStringAsFixed(0)} '
      'units of irrigation water, and ${_laborCap.toStringAsFixed(0)} work days. '
      'Three crops compete for these resources with different profits. '
      'How many acres of each maximize the harvest value?';

  @override
  String get difficultyReason =>
      'Easy: three continuous variables and three upper-bound rows. '
      'Solved here with MicroLP to show the pure-Rust engine (no C++) '
      'on a classic LP.';

  @override
  List<String> get modelingNotes => const [
    'Variables: acres per crop (continuous, ≥ 0).',
    'Objective: maximize Σ profit·acres (dot product).',
    'Constraints: land, water, and labor caps as dot products.',
  ];

  @override
  MathOptModel createModel() {
    final model = MathOptModel(name: 'Farm_Plan');
    _acres = [
      for (var i = 0; i < _crops.length; i++)
        model.continuous(_crops[i], lower: 0),
    ];
    model.maximize(Expr.dotLists(_acres, _profit));
    model.addAll([
      (Expr.sumVars(_acres) <= _land).named('land'),
      (Expr.dotLists(_acres, _water) <= _waterCap).named('water'),
      (Expr.dotLists(_acres, _labor) <= _laborCap).named('labor'),
    ]);
    return model;
  }

  /// Showcases the pure-Rust MicroLP engine (no C++ toolchain needed).
  @override
  SolveOptions? get preferredOptions =>
      const SolveOptions(solver: SolverPreference.microlp);

  @override
  String describeResult(SolveResult result) {
    final lines = <String>[
      'Harvest value: \$${result.objectiveValue!.toStringAsFixed(0)}',
    ];
    for (var i = 0; i < _crops.length; i++) {
      lines.add(
        '${_crops[i]}: ${result.valueOf(_acres[i]).toStringAsFixed(1)} acres',
      );
    }
    return lines.join('\n');
  }
}
