import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

/// Constraint value objects: construction, naming, and display.
void main() {
  group('Constraint', () {
    test('named returns a copy with the name set', () {
      final model = MathOptModel(name: 'C');
      final x = model.continuous('x', lower: 0);
      final c = ((x.asExpr) <= 5).named('cap');
      expect(c.name, 'cap');
      expect(c.rhs, 5.0);
      expect(c.sense, ConstraintSense.lessThanOrEqual);
    });

    test('toString shows every sense', () {
      final model = MathOptModel(name: 'C');
      final x = model.continuous('x', lower: 0);
      expect((x <= 1).toString(), contains('<='));
      expect((x >= 1).toString(), contains('>='));
      expect(x.eq(1).toString(), contains('=='));
    });

    test('equal constraints hold expression, sense, and rhs', () {
      final model = MathOptModel(name: 'C');
      final x = model.continuous('x', lower: 0);
      final c = x.eq(2);
      expect(c, x.eq(2));
      expect(c, isNot(x.eq(3)));
    });
  });

  group('Objective', () {
    test('holds expression and sense', () {
      final model = MathOptModel(name: 'C');
      final x = model.continuous('x', lower: 0);
      const sense = OptimizationSense.maximize;
      final a = Objective(x.asExpr, sense);
      final b = Objective(x.asExpr, sense);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
