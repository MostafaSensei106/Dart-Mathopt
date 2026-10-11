import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

/// `SolveOptions`: defaults, `copyWith` precedence, and diagnostics.
void main() {
  group('SolveOptions defaults', () {
    test('auto solver, no limits, quiet', () {
      const o = SolveOptions();
      expect(o.solver, SolverPreference.auto);
      expect(o.timeLimitSec, isNull);
      expect(o.threadCount, isNull);
      expect(o.enableLogging, isFalse);
    });

    test('SolverPreference lists every backend', () {
      expect(
        SolverPreference.values,
        containsAll([
          SolverPreference.auto,
          SolverPreference.highs,
          SolverPreference.clarabel,
          SolverPreference.microlp,
        ]),
      );
    });
  });

  group('SolveOptions.copyWith', () {
    test('set fields win, the rest is preserved', () {
      const base = SolveOptions(
        timeLimitSec: 60,
        solver: SolverPreference.highs,
      );
      final next = base.copyWith(timeLimitSec: 5, enableLogging: true);
      expect(next.timeLimitSec, 5);
      expect(next.enableLogging, isTrue);
      expect(next.solver, SolverPreference.highs);
      expect(next.threadCount, isNull);
    });

    test('empty copyWith is identical', () {
      const base = SolveOptions(
        timeLimitSec: 9,
        threadCount: 2,
        solver: SolverPreference.clarabel,
      );
      final same = base.copyWith();
      expect(same.timeLimitSec, 9);
      expect(same.threadCount, 2);
      expect(same.solver, SolverPreference.clarabel);
    });
  });

  group('SolveOptions diagnostics', () {
    test('toString names every field', () {
      const o = SolveOptions(timeLimitSec: 5);
      expect(o.toString(), contains('timeLimitSec: 5'));
      expect(o.toString(), contains('solver: SolverPreference.auto'));
    });
  });
}
