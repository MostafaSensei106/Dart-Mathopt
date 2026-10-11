/// Solver scaling suite (moved from `example/benchmark/`).
///
/// Same shapes and seeds as the old `scaling_benchmark.dart` harness, but
/// expressed as `flutter_test` cases with regression thresholds so `flutter
/// test` runs them like everything else. Each case reports user-perceived
/// latency (full Dart `await` round-trip) plus engine-only time.
///
/// Requires the release native library (once per checkout):
/// ```sh
/// cargo build --release --manifest-path rust/Cargo.toml
/// flutter test test/performance
/// ```
@Timeout(Duration(minutes: 5))
library;

import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/benchmark_models.dart';
import '../helpers/test_helpers.dart';

/// Solves [model], asserts optimality, logs the wall/engine split, and
/// enforces a generous wall-clock ceiling (regression tripwire, not a
/// strict perf gate — CI machines vary).
Future<void> expectScalingCase(
  String label,
  MathOptModel Function() build, {
  required Duration wallCeiling,
}) async {
  final model = build();
  final sw = Stopwatch()..start();
  final r = await model.solve();
  sw.stop();
  expectOptimal(r, reason: '$label should solve to optimality');
  // ignore: avoid_print
  print(
    '$label: wall=${sw.elapsedMilliseconds}ms '
    'engine=${r.statistics.solveTimeMs}ms iters=${r.statistics.iterations} '
    'objective=${r.objectiveValue?.toStringAsFixed(2)}',
  );
  expect(
    sw.elapsed,
    lessThan(wallCeiling),
    reason: '$label exceeded wall ceiling $wallCeiling',
  );
}

void main() {
  setUpAll(ensureNativeInit);

  group('transport LP scaling', () {
    test(
      '50v/15c',
      () => expectScalingCase(
        'transport 50v/15c',
        () => buildTransport(5, 10, 1),
        wallCeiling: const Duration(seconds: 60),
      ),
    );
    test(
      '200v/30c',
      () => expectScalingCase(
        'transport 200v/30c',
        () => buildTransport(10, 20, 1),
        wallCeiling: const Duration(seconds: 90),
      ),
    );
  });

  group('factory LP scaling', () {
    test(
      '100v/20c',
      () => expectScalingCase(
        'factory 100v/20c',
        () => buildFactory(100, 20, 2),
        wallCeiling: const Duration(seconds: 90),
      ),
    );
  });

  group('knapsack MILP scaling', () {
    test(
      '30 items',
      () => expectScalingCase(
        'knapsack 30v/1c',
        () => buildKnapsack(30, 3),
        wallCeiling: const Duration(seconds: 90),
      ),
    );
  });

  group('assignment MILP scaling', () {
    test(
      '25v/10c',
      () => expectScalingCase(
        'assignment 25v/10c',
        () => buildAssignment(5, 4),
        wallCeiling: const Duration(seconds: 90),
      ),
    );
    test(
      '64v/16c',
      () => expectScalingCase(
        'assignment 64v/16c',
        () => buildAssignment(8, 4),
        wallCeiling: const Duration(seconds: 120),
      ),
    );
  });
}
