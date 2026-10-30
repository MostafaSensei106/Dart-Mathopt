import 'package:flutter/foundation.dart';

import '../../core/exceptions.dart';
import '../../core/types.dart';
import 'options.dart';
import 'solver_interface.dart';

/// A named backend registered for model routing.
///
/// Adding a future solver (e.g. OSQP) means registering one of these
/// no changes to `MathOptModel` or the compiler are required.
@immutable
class SolverRegistration {
  /// Registers routing metadata for the named backend.
  const SolverRegistration({
    required this.name,
    required this.capabilities,
    this.description = '',
  });

  /// Routing key (`highs`, `clarabel`, `microlp`, ...).
  final String name;

  /// Capability flags used for pre-FFI validation.
  final SolverCapabilities capabilities;

  /// Human-readable backend description for diagnostics.
  final String description;
}

/// Selects which native engine handles a request.
///
/// The built-in table mirrors the Rust-side `router` decision so callers
/// can predict routing without crossing the bridge. The authoritative
/// decision still happens in Rust (defense in depth); this registry
/// performs the Dart-side capability check that produces clear,
/// pre-FFI errors for unsupported shapes (e.g. MILP on Clarabel).
///
/// Custom backends (including test fakes) can [register] themselves;
/// [unregister] / [resetToDefaults] exist for test isolation.
class SolverRegistry {
  const SolverRegistry._();

  static final Map<String, SolverRegistration> _entries = {
    'highs': const SolverRegistration(
      name: 'highs',
      capabilities: SolverCapabilities(supportsMilp: true),
      description: 'HiGHS LP/MILP engine.',
    ),
    'clarabel': const SolverRegistration(
      name: 'clarabel',
      capabilities: SolverCapabilities(supportsQp: true, supportsSocp: true),
      description: 'Clarabel LP/QP/SOCP engine (no integer variables).',
    ),
    'microlp': const SolverRegistration(
      name: 'microlp',
      capabilities: SolverCapabilities(),
      description: 'MicroLP pure-Rust LP engine via good_lp (no C++).',
    ),
  };

  /// Test hook that simulates a web build on the Dart VM.
  ///
  /// `null` (the default) means "use [kIsWeb]"; [resetToDefaults] clears it.
  @visibleForTesting
  static bool? debugIsWeb;

  /// `true` when the app runs on the web (WebAssembly).
  ///
  /// The C++ HiGHS engine is not compiled into WASM builds, so every
  /// web-only routing decision is gated on this flag.
  static bool get isWeb => debugIsWeb ?? kIsWeb;

  /// `true` when the current platform ships a MILP-capable engine (HiGHS).
  static bool get supportsMilp => !isWeb;

  /// All registered engine names (unmodifiable view).
  ///
  /// Includes `highs` even on the web: the entry describes the engine's
  /// capabilities, while [resolve] rejects it at routing time with a
  /// platform-specific message.
  static Iterable<String> get names => List.unmodifiable(_entries.keys);

  /// Looks up a registration by engine name (case-insensitive).
  static SolverRegistration? lookup(String name) =>
      _entries[name.toLowerCase()];

  /// Overrides routing metadata used for pre-FFI capability validation.
  ///
  /// Primarily test isolation (register a stub, assert routing, reset).
  /// This does NOT add an executable backend: `solve()` always executes
  /// through the native engines, so an unknown name still fails at the
  /// bridge with an `InvalidInput` error. Shipping a new engine means
  /// implementing it in Rust and registering it in `engine/registry.rs`
  /// (MicroLP is the reference); mirror its capabilities here.
  static void register(SolverRegistration registration) {
    _entries[registration.name.toLowerCase()] = registration;
  }

  /// Removes a routing-metadata override (test isolation).
  static bool unregister(String name) =>
      _entries.remove(name.toLowerCase()) != null;

  /// Restores the built-in `highs`/`clarabel`/`microlp` table.
  @visibleForTesting
  static void resetToDefaults() {
    debugIsWeb = null;
    _entries
      ..clear()
      ..['highs'] = const SolverRegistration(
        name: 'highs',
        capabilities: SolverCapabilities(supportsMilp: true),
        description: 'HiGHS LP/MILP engine.',
      )
      ..['clarabel'] = const SolverRegistration(
        name: 'clarabel',
        capabilities: SolverCapabilities(supportsQp: true, supportsSocp: true),
        description: 'Clarabel LP/QP/SOCP engine (no integer variables).',
      )
      ..['microlp'] = const SolverRegistration(
        name: 'microlp',
        capabilities: SolverCapabilities(),
        description: 'MicroLP pure-Rust LP engine via good_lp (no C++).',
      );
  }

  /// Returns the engine name for the given problem shape.
  /// Kept for backward compatibility.
  static String route({
    required bool hasInteger,
    required bool hasQuadratic,
    SolverPreference preference = SolverPreference.auto,
  }) {
    return resolve(
      hasInteger: hasInteger,
      hasQuadratic: hasQuadratic,
      preference: preference,
    ).name;
  }

  /// Resolves the registration that should handle a request, throwing a
  /// [ModelValidationException] with an actionable message when the
  /// requested engine cannot handle the problem shape, is unknown, or is
  /// not compiled into this platform (HiGHS on the web).
  static SolverRegistration resolve({
    required bool hasInteger,
    required bool hasQuadratic,
    SolverPreference preference = SolverPreference.auto,
  }) {
    if (isWeb && preference == SolverPreference.highs) {
      throw const ModelValidationException(
        'HiGHS is not available on the web: it is C++ and cannot be '
        'compiled to WebAssembly. Use SolverPreference.clarabel or '
        'SolverPreference.microlp for continuous LP models, or run the '
        'model on a native platform (Android, iOS, Windows, macOS, Linux) '
        'for MILP.',
      );
    }
    if (isWeb && preference == SolverPreference.auto && hasInteger) {
      throw const ModelValidationException(
        'Integer/binary (MILP) models require HiGHS, which is only '
        'available on native platforms (Android, iOS, Windows, macOS, '
        'Linux). Web builds support continuous LP only: relax the integer '
        'variables or solve the model natively.',
      );
    }
    final preferred = switch (preference) {
      SolverPreference.highs => 'highs',
      SolverPreference.clarabel => 'clarabel',
      SolverPreference.microlp => 'microlp',
      // HiGHS owns MILP on native; every continuous LP/QP goes to Clarabel.
      SolverPreference.auto => hasInteger ? 'highs' : 'clarabel',
    };
    final reg = lookup(preferred);
    if (reg == null) {
      throw ModelValidationException(
        "Unknown solver preference: '$preferred'. "
        'Registered engines: ${names.join(', ')}.',
      );
    }
    if (hasInteger && !reg.capabilities.supportsMilp) {
      throw ModelValidationException(
        "Engine '${reg.name}' does not support integer/binary variables; "
        'use HiGHS (or SolverPreference.highs) for MILP models.',
      );
    }
    if (hasQuadratic && !reg.capabilities.supportsQp) {
      throw ModelValidationException(
        "Engine '${reg.name}' does not support quadratic objectives; "
        'use Clarabel (or SolverPreference.clarabel) for QP models.',
      );
    }
    return reg;
  }

  /// `true` if any variable is integer or binary.
  static bool hasIntegerVariables(Iterable<VariableType> types) =>
      types.any((t) => t != VariableType.continuous);
}
