/// Core domain types for mathematical optimization.
///
/// This library has no dependencies on other `dart_mathopt` layers.
library;

/// The domain of a mathematical variable.
enum VariableType { continuous, integer, binary }

/// The direction of the optimization objective.
enum OptimizationSense { minimize, maximize }

/// The relation operator in a constraint.
enum ConstraintSense {
  lessThanOrEqual, // <=
  greaterThanOrEqual, // >=
  equal, // ==
}
