import 'package:meta/meta.dart';

import '../../core/exceptions.dart';
import '../../core/types.dart';
import 'options.dart';
import 'solver_interface.dart';

/// A named backend registered for model routing.
///
/// Adding a future solver (e.g. OSQP) means registering one of these —
/// no changes to `MathOptModel` or the compiler are required.
@immutable
class SolverRegistration {
  const SolverRegistration({
    required this.name,
    required this.capabilities,
    this.description = '',
  });
  final String name;
  final SolverCapabilities capabilities;
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

  /// All registered engine names (unmodifiable view).
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
  /// requested engine cannot handle the problem shape or is unknown.
  static SolverRegistration resolve({
    required bool hasInteger,
    required bool hasQuadratic,
    SolverPreference preference = SolverPreference.auto,
  }) {
    final preferred = switch (preference) {
      SolverPreference.highs => 'highs',
      SolverPreference.clarabel => 'clarabel',
      SolverPreference.microlp => 'microlp',
      SolverPreference.auto => hasQuadratic ? 'clarabel' : 'highs',
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
