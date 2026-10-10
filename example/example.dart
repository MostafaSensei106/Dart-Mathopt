/// The main console example for `dart_mathopt`.
///
/// Tours all eight showcase problems (the same ones in the Flutter app):
/// prints each story, solves it natively, prints the result.
///
/// Run from the package root OR from `example/`:
///
/// ```sh
/// dart run example/example.dart   # from root
/// dart run example.dart           # from example/
/// ```
library;

import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:dart_mathopt_example/problems/catalog.dart';
import 'package:dart_mathopt_example/problems/demo_problem.dart';

import 'tool/native_init.dart';

Future<void> main() async {
  await initNativeLib();

  final problems = buildCatalog();
  print('dart_mathopt console tour: ${problems.length} everyday problems.\n');

  for (var i = 0; i < problems.length; i++) {
    await _runProblem(i + 1, problems[i]);
  }

  print('All ${problems.length} problems solved optimally.');
  RustLib.dispose();
}

Future<void> _runProblem(int number, DemoProblem problem) async {
  print(
    '=== [$number] ${problem.title} '
    '${problem.difficulty.stars} (${problem.technique}) ===',
  );
  print(problem.tagline);
  print(problem.story);

  final model = problem.createModel();
  final result = await model.solve(options: problem.preferredOptions);

  if (result.status != SolveStatus.optimal) {
    print('Solver finished with status: ${result.status.name}\n');
    return;
  }
  print(problem.describeResult(result));
  print(
    'solved in ${result.statistics.solveTimeMs} ms '
    '(${result.statistics.iterations} iterations)\n',
  );
}
