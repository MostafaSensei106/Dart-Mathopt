import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:dart_mathopt_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Real solve flow on the host: opens a problem, taps Solve, and reads
/// the native result. Runs with `flutter test integration_test/` (the
/// integration binding uses real async, so the FRB solve completes).
///
/// Budget Diet is the subject: a millisecond-scale HiGHS LP with stable,
/// famously asserted output (cheapest day $2.63).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('solve flow', () {
    testWidgets('budget diet solves to optimal in-app', (tester) async {
      // Arrange: native engines first (pumpWidget does not run main(),
      // so the app-level init must happen here), tall viewport builds
      // every card without scrolling.
      await DartMathOpt.init();
      addTearDown(DartMathOpt.dispose);
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MathOptShowcaseApp());
      await tester.pumpAndSettle();

      // Act: open the problem and solve it natively.
      await tester.tap(find.text('Budget Diet'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('solve_button')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('solve_button')));
      await tester.pumpAndSettle();

      // Assert: result card and stats rendered from the native solution.
      expect(find.byKey(const ValueKey('solve_output')), findsOneWidget);
      expect(find.byKey(const ValueKey('solve_stats')), findsOneWidget);
      expect(find.textContaining('2.63'), findsOneWidget);
      expect(find.textContaining('status: optimal'), findsOneWidget);
    });
  });
}
