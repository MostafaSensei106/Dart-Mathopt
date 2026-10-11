import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// Juice blending (LP on Clarabel): hit flavor targets at minimum cost.
class BlendingProblem extends DemoProblem {
  static const _juices = ['Orange', 'Grape', 'Apple'];
  static const _cost = [1.2, 0.9, 1.0]; // $ per litre
  static const _acid = [0.8, 0.4, 0.6]; // acidity per litre
  static const _batch = 100.0; // litres to produce
  static const _minAcid = 60.0; // total acidity floor
  static const _minOrange = 20.0; // orange floor (flavor identity)
  static const _maxGrape = 50.0; // grape ceiling (too sweet otherwise)

  late List<Variable> _litres;

  @override
  String get title => 'Juice Blending';

  @override
  String get tagline => 'Cheapest 100 L blend hitting flavor targets.';

  @override
  String get technique => 'LP • Clarabel';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.medium;

  @override
  String get story =>
      'A juice factory blends three raw juices into ${_batch.toStringAsFixed(0)} L '
      'batches. The blend needs enough acidity, real orange character, and '
      'not too much grape. Each juice has its own price. What is the '
      'cheapest recipe?';

  @override
  String get difficultyReason =>
      'Medium: an equality plus mixed <=/>= rows pull in opposite '
      'directions. Solved here with Clarabel to show a second LP engine.';

  @override
  List<String> get modelingNotes => const [
    'Variables: litres per juice (continuous, ≥ 0).',
    'Objective: minimize Σ cost·litres.',
    'Constraints: total == 100 L; acidity ≥ 60; orange ≥ 20 L; grape ≤ 50 L.',
  ];

  @override
  MathOptModel createModel() {
    final model = MathOptModel(name: 'Juice_Blend');
    _litres = [for (final j in _juices) model.continuous(j, lower: 0)];
    model.minimize(Expr.dotLists(_litres, _cost));
    model.addAll([
      (Expr.sumVars(_litres).eq(_batch)).named('batch'),
      (Expr.dotLists(_litres, _acid) >= _minAcid).named('acidity'),
      (_litres[0] >= _minOrange).named('orange_floor'),
      (_litres[1] <= _maxGrape).named('grape_ceiling'),
    ]);
    return model;
  }

  @override
  SolveOptions? get preferredOptions =>
      const SolveOptions(solver: SolverPreference.clarabel);

  @override
  String describeResult(SolveResult result) {
    final lines = <String>[
      'Batch cost: \$${result.objectiveValue!.toStringAsFixed(2)}',
    ];
    for (var i = 0; i < _juices.length; i++) {
      lines.add(
        '${_juices[i]}: ${result.valueOf(_litres[i]).toStringAsFixed(1)} L',
      );
    }
    return lines.join('\n');
  }
}
