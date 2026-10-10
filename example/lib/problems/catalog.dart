import 'diet_problem.dart';
import 'demo_problem.dart';
import 'knapsack_problem.dart';
import 'portfolio_problem.dart';
import 'production_problem.dart';
import 'scheduling_problem.dart';
import 'transportation_problem.dart';

/// The 6 showcase problems, ordered easy → hard.
List<DemoProblem> buildCatalog() => [
  ProductionProblem(),
  DietProblem(),
  KnapsackProblem(),
  PortfolioProblem(),
  TransportationProblem(),
  SchedulingProblem(),
];
