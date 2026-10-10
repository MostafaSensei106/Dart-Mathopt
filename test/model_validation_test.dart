import 'package:dart_mathopt/src/core/exceptions.dart';
import 'package:dart_mathopt/src/modules/modeling/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MathOptModel validation', () {
    test('solving an empty model throws', () async {
      final model = MathOptModel();
      expect(() => model.solve(), throwsA(isA<ModelValidationException>()));
    });

    test('solving without an objective throws', () async {
      final model = MathOptModel();
      model.continuous('x', lower: 0);
      expect(() => model.solve(), throwsA(isA<ModelValidationException>()));
    });

    test('inverted bounds throw at variable creation', () {
      final model = MathOptModel();
      expect(
        () => model.continuous('x', lower: 5, upper: 1),
        throwsA(isA<ModelValidationException>()),
      );
    });

    test('variable ids are dense and zero-based', () {
      final model = MathOptModel();
      final x = model.continuous('x');
      final y = model.integer('y');
      final z = model.binary('z');
      expect([x.id, y.id, z.id], [0, 1, 2]);
      expect([x.name, y.name, z.name], ['x', 'y', 'z']);
    });

    test('binary defaults to [0, 1] bounds', () {
      final model = MathOptModel();
      final b = model.binary('b');
      expect(b.lowerBound, 0.0);
      expect(b.upperBound, 1.0);
    });
  });
}
