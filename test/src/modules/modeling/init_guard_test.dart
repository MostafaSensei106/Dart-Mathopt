import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

/// Initialization guard: `solve()` without `DartMathOpt.init()` fails
/// fast with an actionable error instead of a cryptic bridge failure.
///
/// Isolated in its own file: it deliberately leaves the entry point
/// uninitialized, which must not leak into other suites (one isolate
/// per test file).
void main() {
  group('MathOptModel initialization guard', () {
    test('solve without init throws ModelValidationException', () async {
      DartMathOpt.resetForTesting();
      final model = MathOptModel(name: 'NoInit');
      final x = model.continuous('x', lower: 0, upper: 1);
      model.maximize(x.asExpr);
      await expectLater(
        model.solve(),
        throwsA(
          isA<ModelValidationException>().having(
            (e) => e.message,
            'message',
            contains('DartMathOpt.init()'),
          ),
        ),
      );
    });
  });
}
