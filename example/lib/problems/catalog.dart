import 'assignment_problem.dart';
import 'diet_problem.dart';
import 'demo_problem.dart';
import 'facility_problem.dart';
import 'knapsack_problem.dart';
import 'portfolio_problem.dart';
import 'production_problem.dart';
import 'scheduling_problem.dart';
import 'transportation_problem.dart';

/// The 8 showcase problems, ordered easy → hard.
List<DemoProblem> buildCatalog() => [
  ProductionProblem(),
  DietProblem(),
  AssignmentProblem(),
  KnapsackProblem(),
  PortfolioProblem(),
  TransportationProblem(),
  FacilityProblem(),
  SchedulingProblem(),
];
