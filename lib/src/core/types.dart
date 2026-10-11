/// Core domain types for mathematical optimization.
///
/// This library has no dependencies on other `dart_mathopt` layers.
library;

/// The domain of a mathematical variable.
enum VariableType {
  /// Any real value within bounds.
  continuous,

  /// Whole numbers within bounds.
  integer,

  /// Either 0 or 1.
  binary,
}

/// The direction of the optimization objective.
enum OptimizationSense {
  /// Find the smallest objective value.
  minimize,

  /// Find the largest objective value.
  maximize,
}

/// The relation operator in a constraint.
enum ConstraintSense {
  /// Left-hand side must be less than or equal to the right-hand side.
  lessThanOrEqual,

  /// Left-hand side must be greater than or equal to the right-hand side.
  greaterThanOrEqual,

  /// Both sides must be equal.
  equal,
}
