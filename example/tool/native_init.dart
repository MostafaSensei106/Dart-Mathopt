/// Shared native-library bootstrap for console entry points
/// (`example.dart`, `benchmark/`).
///
/// Tries the default loader first (works from the package root). Otherwise
/// walks up from the running script until a directory containing
/// `rust/Cargo.toml` is found, and loads the freshly built library from
/// its `rust/target/release/`.
///
/// Build the library once before running:
///
/// ```sh
/// cargo build --release --manifest-path rust/Cargo.toml
/// ```
library;

import 'dart:io';

import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

/// Initializes the Rust engines. Safe to call instead of `RustLib.init()`.
Future<void> initNativeLib() async {
  try {
    await RustLib.init();
    return;
  } catch (_) {
    // Fall through to script-relative resolution below.
  }

  var dir = File(Platform.script.toFilePath()).parent;
  for (var i = 0; i < 4; i++) {
    if (File('${dir.path}${Platform.pathSeparator}rust'
            '${Platform.pathSeparator}Cargo.toml')
        .existsSync()) {
      break;
    }
    dir = dir.parent;
  }
  final libName = switch (true) {
    _ when Platform.isLinux => 'libdart_mathopt.so',
    _ when Platform.isMacOS => 'libdart_mathopt.dylib',
    _ when Platform.isWindows => 'dart_mathopt.dll',
    _ => throw UnsupportedError('Unsupported OS: ${Platform.operatingSystem}'),
  };
  final sep = Platform.pathSeparator;
  final libPath =
      '${dir.path}${sep}rust${sep}target${sep}release$sep$libName';

  if (!File(libPath).existsSync()) {
    throw StateError(
      'Native library not found at $libPath.\n'
      'Build it first: cargo build --release --manifest-path rust/Cargo.toml',
    );
  }
  await RustLib.init(externalLibrary: ExternalLibrary.open(libPath));
}
