/// Shared native-library bootstrap for console entry points
/// (`example.dart`).
///
/// Thin compatibility wrapper over [DartMathOpt.init]: the resolution
/// logic (bundled → explicit path → source-checkout fallback) now lives
/// inside the library (`lib/src/rust/loader.dart`) so apps, tests, and
/// benchmarks share one path.
///
/// Build the library once before running:
/// ```sh
/// cargo build --release --manifest-path rust/Cargo.toml
/// ```
library;

import 'package:dart_mathopt/dart_mathopt.dart';

/// Initializes the Rust engines. Prefer [DartMathOpt.init] in new code.
Future<void> initNativeLib({MathOptConfig config = const MathOptConfig()}) =>
    DartMathOpt.init(config: config);
