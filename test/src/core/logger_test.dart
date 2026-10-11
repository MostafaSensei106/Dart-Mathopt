import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

/// Central logger: named channel, attachable console listener.
void main() {
  group('mathOptLog', () {
    test('uses the package logger name', () {
      expect(mathOptLog.name, 'dart_mathopt');
    });

    test('initMathOptLogging attaches and detaches safely', () {
      final cancelFirst = initMathOptLogging();
      final cancelSecond = initMathOptLogging(level: Level.SEVERE);
      expect(cancelFirst, isA<void Function()>());
      expect(cancelSecond, isA<void Function()>());
      cancelFirst();
      cancelSecond();
    });
  });
}
