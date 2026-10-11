import 'dart:io';

import 'package:dart_mathopt/src/rust/loader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Native library resolution that never touches a real `.so`:
/// platform names and the explicit-path failure mode.
void main() {
  group('NativeLibraryLoader.platformLibName', () {
    test('matches the host OS convention', () {
      final name = NativeLibraryLoader.platformLibName();
      expect(
        name,
        anyOf([
          'libdart_mathopt.so',
          'libdart_mathopt.dylib',
          'dart_mathopt.dll',
        ]),
      );
      if (Platform.isLinux) expect(name, 'libdart_mathopt.so');
      if (Platform.isMacOS) expect(name, 'libdart_mathopt.dylib');
      if (Platform.isWindows) expect(name, 'dart_mathopt.dll');
    });
  });

  group('NativeLibraryLoader.init', () {
    test('explicit but missing path fails with a build hint', () async {
      await expectLater(
        NativeLibraryLoader.init(explicitPath: '/does/not/exist.so'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('cargo build'),
          ),
        ),
      );
    });
  });
}
