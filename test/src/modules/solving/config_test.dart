import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global config: defaults, presets, and per-call override precedence.
/// Pure Dart — no native library needed.
void main() {
  setUp(DartMathOpt.resetForTesting);

  group('defaults', () {
    test('balanced is auto with no limits', () {
      const c = MathOptConfig.balanced;
      expect(c.defaultSolver, SolverPreference.auto);
      expect(c.defaultTimeLimitSec, isNull);
      expect(c.defaultThreadCount, isNull);
      expect(c.enableLogging, isFalse);
    });
  });

  group('presets', () {
    test('fastLp pins HiGHS', () {
      final c = MathOptConfig.fastLp();
      expect(c.defaultSolver, SolverPreference.highs);
    });

    test('accurateMilp carries a time budget', () {
      final c = MathOptConfig.accurateMilp();
      expect(c.defaultSolver, SolverPreference.highs);
      expect(c.defaultTimeLimitSec, 120);
    });

    test('lowMemory is single-threaded', () {
      final c = MathOptConfig.lowMemory();
      expect(c.defaultThreadCount, 1);
      expect(c.enableLogging, isFalse);
    });

    test('verbose enables logging', () {
      final c = MathOptConfig.verbose();
      expect(c.enableLogging, isTrue);
      expect(c.defaultTimeLimitSec, isNotNull);
    });
  });

  group('resolve precedence', () {
    test('per-call fields win over global config', () {
      const global = MathOptConfig(
        defaultSolver: SolverPreference.highs,
        defaultTimeLimitSec: 60,
        defaultThreadCount: 2,
      );
      const call = SolveOptions(
        timeLimitSec: 5,
        solver: SolverPreference.clarabel,
      );
      final effective = global.resolve(call);
      expect(effective.timeLimitSec, 5);
      expect(effective.solver, SolverPreference.clarabel);
      // Untouched fields fall back to global.
      expect(effective.threadCount, 2);
    });

    test('auto call inherits global solver', () {
      const global = MathOptConfig(defaultSolver: SolverPreference.clarabel);
      final effective = global.resolve(const SolveOptions());
      expect(effective.solver, SolverPreference.clarabel);
    });

    test('global logging is OR-ed with call logging', () {
      const global = MathOptConfig(enableLogging: true);
      final effective = global.resolve(const SolveOptions());
      expect(effective.enableLogging, isTrue);
    });

    test('null call resolves to pure global defaults', () {
      const global = MathOptConfig(
        defaultSolver: SolverPreference.highs,
        defaultTimeLimitSec: 9,
      );
      final effective = global.resolve(null);
      expect(effective.solver, SolverPreference.highs);
      expect(effective.timeLimitSec, 9);
    });
  });

  group('copyWith', () {
    test('nullable fields can be cleared explicitly', () {
      const base = MathOptConfig(defaultTimeLimitSec: 60);
      final cleared = base.copyWith(defaultTimeLimitSec: () => null);
      expect(cleared.defaultTimeLimitSec, isNull);
      final kept = base.copyWith();
      expect(kept.defaultTimeLimitSec, 60);
    });
  });
}
