import 'package:dart_mathopt_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test: the showcase renders all six problem cards without
/// touching the native solvers (no solve is tapped).
void main() {
  testWidgets('home lists all six problems', (tester) async {
    await tester.pumpWidget(const MathOptShowcaseApp());
    await tester.pumpAndSettle();

    for (final title in [
      'Factory Production',
      'Budget Diet',
      'Backpack Packing',
      'Investment Mix',
      'Delivery Network',
      'Staff Scheduling',
    ]) {
      expect(find.text(title, skipOffstage: false), findsOneWidget);
    }
    // Difficulty stars render on the cards.
    expect(find.textContaining('★'), findsWidgets);
    // Tapping a card opens its detail screen.
    await tester.tap(find.text('Budget Diet'));
    await tester.pumpAndSettle();
    expect(find.text('How it becomes math'), findsOneWidget);
    expect(find.text('Solve now'), findsOneWidget);
  });
}
