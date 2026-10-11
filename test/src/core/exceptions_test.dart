import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exception contracts: every failure mode carries a readable message.
void main() {
  group('MathOptException', () {
    test('toString names the type and message', () {
      const e = ModelValidationException('bad model');
      expect(e.toString(), contains('ModelValidationException'));
      expect(e.toString(), contains('bad model'));
      expect(e.message, 'bad model');
    });

    test('SolverExecutionException carries an error code', () {
      const e = SolverExecutionException('boom', -1);
      expect(e.errorCode, -1);
      expect(e.toString(), contains('boom'));
    });

    test('SolverTimeoutException reports its limit', () {
      final e = SolverTimeoutException(const Duration(seconds: 30));
      expect(e.timeLimit, const Duration(seconds: 30));
      expect(e.toString(), contains('0:00:30'));
    });
  });
}
