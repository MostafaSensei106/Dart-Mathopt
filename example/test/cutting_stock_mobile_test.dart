import 'package:dart_mathopt_example/screens/cutting_stock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mobile layout guard: the cutting screen must render cleanly on a
/// 360px phone with no overflow exceptions — form, both bottom sheets.
void main() {
  testWidgets('cutting screen fits a 360px phone', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: CuttingStockScreen()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Window sheet opens and fits.
    await tester.ensureVisible(find.text('Add window'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add window'));
    await tester.pumpAndSettle();
    expect(find.text('Add to order'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Add to order'));
    await tester.pumpAndSettle();

    // Custom-piece sheet opens and fits.
    await tester.ensureVisible(find.text('Add piece'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add piece'));
    await tester.pumpAndSettle();
    expect(find.text('Add to order'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
