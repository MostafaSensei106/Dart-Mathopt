import 'package:meta/meta.dart';

import 'config.dart';
import 'core/logger.dart';
import 'rust/frb_generated.dart';
import 'rust/loader.dart';

/// Single entry point for the `dart_mathopt` library.
///
/// ```dart
/// await DartMathOpt.init(); // once, before the first solve()
/// await DartMathOpt.init(config: MathOptConfig.fastLp());
/// ```
///
/// Replaces direct `RustLib.init()` calls: it resolves the native library
/// (bundled, explicit path, or source-checkout fallback), initializes the
/// Rust bridge exactly once, and stores the global [MathOptConfig] that
/// `MathOptModel.solve()` merges with per-call [SolveOptions].
class DartMathOpt {
  DartMathOpt._();

  static bool _initialized = false;
  static MathOptConfig _config = const MathOptConfig();

  /// Current global config (defaults until [init] is called with one).
  static MathOptConfig get config => _config;

  /// Whether [init] has completed (idempotent: repeated calls are cheap).
  static bool get isInitialized => _initialized;

  /// Initializes the native engines. Safe to call multiple times: the
  /// first call wins unless [reload] is true.
  ///
  /// When [config] is supplied it replaces the stored global config.
  static Future<void> init({
    MathOptConfig config = const MathOptConfig(),
    bool reload = false,
  }) async {
    if (_initialized && !reload) {
      _config = config;
      return;
    }
    await NativeLibraryLoader.init(explicitPath: config.libraryPath);
    _config = config;
    _initialized = true;
    mathOptLog.fine('DartMathOpt initialized ($config)');
  }

  /// Releases native resources (tests / hot-restart flows).
  static void dispose() {
    RustLib.dispose();
    _initialized = false;
  }

  /// Resets static state without touching native code (unit tests only).
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _config = const MathOptConfig();
  }
}
