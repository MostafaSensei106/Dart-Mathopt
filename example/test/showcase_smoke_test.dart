import 'package:dart_mathopt_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test: the showcase renders all twelve problem cards without
/// touching the native solvers (no solve is tapped).
void main() {
  testWidgets('home lists all twelve problems', (tester) async {
    // Tall viewport so the lazy list builds every card (no scrolling).
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MathOptShowcaseApp());
    await tester.pumpAndSettle();

    for (final title in [
      'Factory Production',
      'Budget Diet',
      'Farm Planning',
      'Task Assignment',
      'Backpack Packing',
      'Investment Mix',
      'Juice Blending',
      'Delivery Network',
      'Project Funding',
      'Warehouse Opening',
      'Lecture Timetabling',
      'Staff Scheduling',
    ]) {
      expect(find.text(title), findsOneWidget);
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
