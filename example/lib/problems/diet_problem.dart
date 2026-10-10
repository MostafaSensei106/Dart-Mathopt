import 'package:dart_mathopt/dart_mathopt.dart';

import 'demo_problem.dart';

/// NEW — daily diet on a budget (LP).
class DietProblem extends DemoProblem {
  static const _foods = ['Bread', 'Milk', 'Eggs'];
  static const _price = [0.5, 0.8, 0.6]; // $ per serving
  static const _calories = [100.0, 150.0, 70.0]; // per serving
  static const _protein = [4.0, 8.0, 6.0]; // grams per serving
  static const _minCalories = 500.0;
  static const _minProtein = 25.0;

  late List<Variable> _servings;

  @override
  String get title => 'Budget Diet';

  @override
  String get tagline => 'Cheapest meals hitting calorie + protein goals.';

  @override
  String get technique => 'LP • HiGHS';

  @override
  ProblemDifficulty get difficulty => ProblemDifficulty.easy;

  @override
  String get story =>
      'You want a day of eating with at least $_minCalories calories and '
      '$_minProtein g of protein, spending as little as possible. Bread, '
      'milk and eggs have different prices and nutrition per serving — '
      'what is the cheapest mix?';

  @override
  String get difficultyReason =>
      'Easy: three continuous variables with two "at least" constraints. '
      'Fractional servings are fine (half a glass of milk counts).';

  @override
  List<String> get modelingNotes => const [
    'Variables: servings of bread, milk, eggs (continuous, ≥ 0).',
    'Objective: minimize Σ price·servings.',
    'Constraints: Σ calories ≥ 500, Σ protein ≥ 25.',
  ];

  @override
  MathOptModel createModel() {
    final model = MathOptModel(name: 'Budget_Diet');
    _servings = [for (final f in _foods) model.continuous(f, lower: 0)];
    ExpressionNode cost = const ConstantNode(0);
    ExpressionNode cal = const ConstantNode(0);
    ExpressionNode protein = const ConstantNode(0);
    for (var i = 0; i < _foods.length; i++) {
      cost += _servings[i] * _price[i];
      cal += _servings[i] * _calories[i];
      protein += _servings[i] * _protein[i];
    }
    model.minimize(cost);
    model.add((cal >= _minCalories).named('calories'));
    model.add((protein >= _minProtein).named('protein'));
    return model;
  }

  @override
  String describeResult(SolveResult result) {
    final lines = <String>[
      'Cheapest day: \$${result.objectiveValue!.toStringAsFixed(2)}',
    ];
    for (var i = 0; i < _foods.length; i++) {
      lines.add(
        '${_foods[i]}: '
        '${result.valueOf(_servings[i]).toStringAsFixed(2)} servings',
      );
    }
    return lines.join('\n');
  }
}
