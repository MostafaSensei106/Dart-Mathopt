import 'package:dart_mathopt/src/rust/models/dto_request.dart';
import 'package:dart_mathopt/src/rust/models/dto_response.dart';
import 'package:flutter_test/flutter_test.dart';

/// FFI DTO contracts: equality and fields survive the bridge codegen.
/// Guards regeneration drift (added/renamed fields break these).
void main() {
  group('FrbSolveStatistics', () {
    test('microsecond field round-trips through equality', () {
      const a = FrbSolveStatistics(
        solveTimeMs: 2,
        solveTimeUs: 2417,
        iterations: 22,
      );
      const b = FrbSolveStatistics(
        solveTimeMs: 2,
        solveTimeUs: 2417,
        iterations: 22,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.solveTimeUs, 2417);
    });

    test('sub-millisecond precision is preserved', () {
      const stats = FrbSolveStatistics(
        solveTimeMs: 0,
        solveTimeUs: 320,
        iterations: 0,
      );
      expect(stats.solveTimeMs, 0);
      expect(stats.solveTimeUs, 320);
    });
  });

  group('FrbTermDto', () {
    test('equality covers id and coefficient', () {
      const a = FrbTermDto(variableId: 3, coefficient: 1.5);
      expect(a, const FrbTermDto(variableId: 3, coefficient: 1.5));
      expect(a, isNot(const FrbTermDto(variableId: 3, coefficient: 1.6)));
    });
  });
}
