/// UI responsiveness: solving must never block the event loop.
///
/// Two independent probes over the same heavy LP (factory 400x60, whose
/// Dart-side compile makes the round-trip hundreds of ms):
/// 1. A periodic [Timer] must keep firing while `await model.solve()`
///    is in flight (event-loop probe, no widgets needed).
/// 2. A repeating animation must advance across pumped frames while a
///    solve runs (frame probe — the closest automated equivalent of the
///    showcase's "progress indicator keeps animating" claim).
///
/// If `solve()` ever becomes synchronous/blocking, both tests fail.
@Timeout(Duration(minutes: 5))
library;

import 'dart:async';

import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/benchmark_models.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(ensureNativeInit);

  test('event loop stays responsive during a heavy solve', () async {
    final model = buildFactory(400, 60, 42);
    var ticks = 0;
    final timer = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) => ticks++,
    );
    late SolveResult r;
    try {
      r = await model.solve();
    } finally {
      timer.cancel();
    }
    expectOptimal(r);
    expect(
      ticks,
      greaterThan(5),
      reason: 'event loop was blocked during solve (ticks=$ticks)',
    );
    // ignore: avoid_print
    print(
      'heavy solve overlapped $ticks event-loop ticks '
      '(engine=${r.statistics.solveTimeMs}ms)',
    );
  });

  test('solve() startup does not synchronously block the caller', () async {
    final model = buildFactory(400, 60, 42);
    final sw = Stopwatch()..start();
    final future = model.solve();
    sw.stop();
    // Everything before the first await (validation + objective/variable
    // compile) must stay far below one frame; the heavy per-constraint
    // work yields to the event loop instead of blocking it.
    expect(
      sw.elapsedMilliseconds,
      lessThan(100),
      reason: 'solve() blocked synchronously for ${sw.elapsedMilliseconds}ms',
    );
    final r = await future;
    expectOptimal(r);
  });

  testWidgets('animation advances across frames during a solve', (
    tester,
  ) async {
    const vsync = TestVSync();
    final controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: vsync,
    );
    addTearDown(() {
      controller.stop();
      controller.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: controller,
          builder: (_, _) => Text('t=${controller.value.toStringAsFixed(3)}'),
        ),
      ),
    );
    controller.repeat();
    await tester.pump();

    await tester.runAsync(() async {
      final model = buildFactory(400, 60, 42);
      final future = model.solve();
      final samples = <double>[];
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        samples.add(controller.value);
      }
      final r = await future;
      expectOptimal(r);
      final distinct = samples.map((v) => (v * 1000).round()).toSet().length;
      expect(
        distinct,
        greaterThan(5),
        reason: 'animation froze during solve: $samples',
      );
      // ignore: avoid_print
      print(
        'animation advanced through $distinct distinct values '
        'during solve (engine=${r.statistics.solveTimeMs}ms)',
      );
      controller.stop();
    });
  });
}
