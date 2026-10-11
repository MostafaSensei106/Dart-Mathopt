/// Latency distribution: p50/p95 of user-perceived (wall) and engine-only
/// time over repeated seeded solves.
///
/// The printed percentiles are the deliverable (compare across runs /
/// machines); the p95 ceiling is a deliberately generous regression
/// tripwire, not a strict perf gate.
///
/// Requires the release native library:
/// ```sh
/// cargo build --release --manifest-path rust/Cargo.toml
/// flutter test test/performance/latency_percentiles_test.dart
/// ```
@Timeout(Duration(minutes: 5))
library;

import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/benchmark_models.dart';
import '../helpers/test_helpers.dart';

double percentile(List<double> sorted, double p) {
  assert(sorted.isNotEmpty);
  assert(p >= 0 && p <= 100);
  if (sorted.length == 1) return sorted.single;
  final rank = p / 100 * (sorted.length - 1);
  final low = rank.floor();
  final high = rank.ceil();
  if (low == high) return sorted[low];
  final frac = rank - low;
  return sorted[low] * (1 - frac) + sorted[high] * frac;
}

Future<void> expectLatencyDistribution({
  required String label,
  required MathOptModel Function() build,
  required int iterations,
  required Duration p95Ceiling,
}) async {
  final walls = <double>[];
  final engines = <double>[];
  for (var i = 0; i < iterations; i++) {
    final model = build();
    final sw = Stopwatch()..start();
    final r = await model.solve();
    sw.stop();
    expectOptimal(r, reason: '$label iteration $i should be optimal');
    walls.add(sw.elapsedMicroseconds / 1000);
    engines.add(r.statistics.solveTimeMs.toDouble());
  }
  walls.sort();
  engines.sort();
  final wallP50 = percentile(walls, 50);
  final wallP95 = percentile(walls, 95);
  final engineP50 = percentile(engines, 50);
  final engineP95 = percentile(engines, 95);
  // ignore: avoid_print
  print(
    '$label (n=$iterations): '
    'wall p50=${wallP50.toStringAsFixed(1)}ms '
    'p95=${wallP95.toStringAsFixed(1)}ms | '
    'engine p50=${engineP50.toStringAsFixed(1)}ms '
    'p95=${engineP95.toStringAsFixed(1)}ms',
  );
  expect(
    wallP95,
    lessThan(p95Ceiling.inMilliseconds.toDouble()),
    reason: '$label wall p95 ${wallP95.toStringAsFixed(1)}ms '
        'exceeded $p95Ceiling',
  );
}

void main() {
  setUpAll(ensureNativeInit);

  test(
    'transport 50v latency distribution (15 seeded solves)',
    () => expectLatencyDistribution(
      label: 'transport 50v/15c',
      build: () => buildTransport(5, 10, 1),
      iterations: 15,
      p95Ceiling: const Duration(seconds: 30),
    ),
  );

  test(
    'factory 100v latency distribution (11 seeded solves)',
    () => expectLatencyDistribution(
      label: 'factory 100v/20c',
      build: () => buildFactory(100, 20, 2),
      iterations: 11,
      p95Ceiling: const Duration(seconds: 60),
    ),
  );
}
