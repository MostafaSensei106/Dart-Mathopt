import 'package:dart_mathopt_example/solve_time.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exact adaptive formatting: unit follows magnitude, values are exact.
void main() {
  group('formatMicroseconds', () {
    test('sub-millisecond stays in microseconds', () {
      expect(formatMicroseconds(0), '0 µs');
      expect(formatMicroseconds(320), '320 µs');
      expect(formatMicroseconds(999), '999 µs');
    });

    test('milliseconds print exactly, no rounding', () {
      expect(formatMicroseconds(1000), '1.0 ms');
      expect(formatMicroseconds(15312), '15.312 ms');
      expect(formatMicroseconds(999999), '999.999 ms');
    });

    test('seconds and above', () {
      expect(formatMicroseconds(1000000), '1.0 s');
      expect(formatMicroseconds(1500000), '1.5 s');
    });

    test('negative input clamps to zero', () {
      expect(formatMicroseconds(-5), '0 µs');
    });
  });
}
