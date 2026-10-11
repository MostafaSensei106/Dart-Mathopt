import 'dart:io';

import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

/// `DartMathOpt` lifecycle against the real native library:
/// init, explicit-path init, dispose, and re-init as one ordered flow
/// (a single test — lifecycle steps are inherently sequential).
void main() {
  group('DartMathOpt lifecycle', () {
    test('init, dispose, and re-init', () async {
      // Arrange: locate the release library built for development.
      final libName = Platform.isLinux
          ? 'libdart_mathopt.so'
          : Platform.isMacOS
              ? 'libdart_mathopt.dylib'
              : 'dart_mathopt.dll';
      final sep = Platform.pathSeparator;
      final libPath =
          '${Directory.current.path}${sep}rust${sep}target${sep}release$sep$libName';
      if (!File(libPath).existsSync()) {
        markTestSkipped('native library not built: $libPath');
      }

      // Act + Assert: explicit-path init works and stores config.
      await DartMathOpt.init(
        config: MathOptConfig(libraryPath: libPath),
        reload: true,
      );
      expect(DartMathOpt.isInitialized, isTrue);
      expect(DartMathOpt.config.libraryPath, libPath);

      // Dispose releases; a plain re-init recovers.
      DartMathOpt.dispose();
      expect(DartMathOpt.isInitialized, isFalse);
      await DartMathOpt.init();
      expect(DartMathOpt.isInitialized, isTrue);
      expect(DartMathOpt.config.libraryPath, isNull);
    });
  });
}
