import 'assignment_problem.dart';
import 'blending_problem.dart';
import 'demo_problem.dart';
import 'diet_problem.dart';
import 'facility_problem.dart';
import 'farm_problem.dart';
import 'funding_problem.dart';
import 'knapsack_problem.dart';
import 'portfolio_problem.dart';
import 'production_problem.dart';
import 'scheduling_problem.dart';
import 'timetabling_problem.dart';
import 'transportation_problem.dart';

/// The 12 showcase problems, ordered easy → hard.
List<DemoProblem> buildCatalog() => [
  ProductionProblem(),
  DietProblem(),
  FarmProblem(),
  AssignmentProblem(),
  KnapsackProblem(),
  PortfolioProblem(),
  BlendingProblem(),
  TransportationProblem(),
  FundingProblem(),
  FacilityProblem(),
  TimetablingProblem(),
  SchedulingProblem(),
];
