import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../example/lib/feature_demos.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(ensureNativeInit);

  test('live feature recipes exercise the native engines and guards', () async {
    final demos = buildFeatureDemos();
    final comparison = await demos[0].run();
    for (final engine in ['auto', 'highs', 'clarabel', 'microlp']) {
      expect(comparison, contains('$engine: optimal'));
    }
    expect(await demos[1].run(), contains('objective=9.0'));
    final cache = await demos[2].run();
    expect(cache, contains('solve 1: cached=false'));
    expect(cache, contains('solve 2: cached=true'));
    expect(cache, contains('solve 3: cached=false'));
    expect(await demos[3].run(), contains('status=infeasible'));
    expect(await demos[4].run(), contains('Expected validation error'));
  });

  test('web feature recipes explain unavailable native requests', () async {
    SolverRegistry.debugIsWeb = true;
    addTearDown(SolverRegistry.resetToDefaults);
    final demos = buildFeatureDemos();
    expect(await demos[0].run(), contains('highs: unavailable'));
    expect(await demos[1].run(), contains('Expected web limitation'));
    expect(await demos[4].run(), contains('Expected validation error'));
  });
}
