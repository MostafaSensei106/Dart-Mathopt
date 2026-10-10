/// The main console example for `dart_mathopt`.
///
/// Tours all six showcase problems (the same ones in the Flutter app):
/// prints each story, solves it natively, prints the result.
///
/// Run from the package root OR from `example/`:
///
/// ```sh
/// dart run example/example.dart   # from root
/// dart run example.dart           # from example/
/// ```
library;

import 'dart:io';

import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:dart_mathopt_example/problems/catalog.dart';
import 'package:dart_mathopt_example/problems/demo_problem.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

Future<void> main() async {
  await _initNativeLib();

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

/// Initializes the Rust engines for this script.
///
/// Tries the default loader first (works from the package root). If that
/// fails — e.g. the working directory is `example/` — it resolves the
/// freshly built native library relative to this script and retries.
///
/// Build the library once before running:
///
/// ```sh
/// cargo build --release --manifest-path rust/Cargo.toml
/// ```
Future<void> _initNativeLib() async {
  try {
    await RustLib.init();
    return;
  } catch (_) {
    // Fall through to script-relative resolution below.
  }

  // This script lives in `<root>/example/`; the workspace root is one
  // level up from there.
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final workspaceRoot = scriptDir.parent;
  final libName = switch (true) {
    _ when Platform.isLinux => 'libdart_mathopt.so',
    _ when Platform.isMacOS => 'libdart_mathopt.dylib',
    _ when Platform.isWindows => 'dart_mathopt.dll',
    _ => throw UnsupportedError('Unsupported OS: ${Platform.operatingSystem}'),
  };
  final sep = Platform.pathSeparator;
  final libPath =
      '${workspaceRoot.path}${sep}rust${sep}target${sep}release$sep$libName';

  if (!File(libPath).existsSync()) {
    throw StateError(
      'Native library not found at $libPath.\n'
      'Build it first: cargo build --release --manifest-path rust/Cargo.toml',
    );
  }
  await RustLib.init(externalLibrary: ExternalLibrary.open(libPath));
}
