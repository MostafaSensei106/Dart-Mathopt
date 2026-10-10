import 'package:meta/meta.dart';

import '../../core/types.dart';
import 'options.dart';
import 'solver_interface.dart';

/// Selects which native engine should handle a request.
///
/// Mirrors the Rust-side `router::route_request` decision so callers can
/// predict routing without crossing the bridge. The authoritative decision
/// still happens in Rust.
@internal
class SolverRegistry {
  const SolverRegistry._();

  /// Returns `'highs'` or `'clarabel'` for the given problem shape.
  static String route({
    required bool hasInteger,
    required bool hasQuadratic,
    SolverPreference preference = SolverPreference.auto,
  }) {
    switch (preference) {
      case SolverPreference.highs:
        return 'highs';
      case SolverPreference.clarabel:
        return 'clarabel';
      case SolverPreference.auto:
        if (hasQuadratic) return 'clarabel';
        return 'highs';
    }
  }

  /// `true` if any variable is integer or binary.
  static bool hasIntegerVariables(Iterable<VariableType> types) =>
      types.any((t) => t != VariableType.continuous);
}

/// Extension to expose variable-type checks on DTO lists.
extension SolverVariableListX on List<SolverVariableDto> {
  bool get hasInteger =>
      any((v) => v.varTypeIndex != VariableType.continuous.index);
}
