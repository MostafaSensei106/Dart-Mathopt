/// Shared catalog tour: runs every showcase problem back to back.
///
/// Used by both console entry points (`example/example.dart` and the
/// legacy `lib/example.dart`) so their output can never drift apart.
library;

import 'package:dart_mathopt/dart_mathopt.dart';

import 'problems/catalog.dart';
import 'problems/demo_problem.dart';
import 'solve_time.dart';

/// Prints each story, solves it natively, prints the result and timing.
///
/// Wall time is measured here with microsecond precision; engine time
/// comes from the solver statistics. Both render through
/// [formatMicroseconds], so sub-millisecond solves show exact `µs`.
Future<void> runCatalogTour() async {
  final problems = buildCatalog();
  print('dart_mathopt console tour: ${problems.length} everyday problems.\n');

  for (var i = 0; i < problems.length; i++) {
    await runProblem(i + 1, problems[i]);
  }

  print('All ${problems.length} problems solved optimally.');
}

Future<void> runProblem(int number, DemoProblem problem) async {
  print(
    '=== [$number] ${problem.title} '
    '${problem.difficulty.stars} (${problem.technique}) ===',
  );
  print(problem.tagline);
  print(problem.story);

  final model = problem.createModel();
  final sw = Stopwatch()..start();
  final result = await model.solve(options: problem.preferredOptions);
  sw.stop();

  if (result.status != SolveStatus.optimal) {
    print('Solver finished with status: ${result.status.name}\n');
    return;
  }
  print(problem.describeResult(result));
  print(
    'solved in ${formatMicroseconds(sw.elapsedMicroseconds)} '
    '(engine ${formatMicroseconds(result.statistics.solveTimeUs)}, '
    '${result.statistics.iterations} iterations)\n',
  );
}
