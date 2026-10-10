/// Response-side Data Transfer Objects (Rust -> Dart).
///
/// `variable_values` is index-aligned with the request's variable IDs:
/// `variable_values[id]` is the primal value of variable `id`. This
/// array-based layout avoids HashMap overhead across the bridge.

#[derive(Clone, Debug)]
pub struct FrbSolveResponse {
    pub status: FrbSolveStatus,
    pub objective_value: Option<f64>,
    /// Primal values indexed by variable ID.
    pub variable_values: Vec<f64>,
    /// Dual values per constraint row (only for pure LP).
    pub dual_values: Option<Vec<f64>>,
    pub statistics: FrbSolveStatistics,
}

#[derive(Clone, Debug)]
pub enum FrbSolveStatus {
    Optimal,
    Infeasible,
    Unbounded,
    TimeLimitExceeded,
    NumericalError,
    Unknown,
}

#[derive(Clone, Debug, Default)]
pub struct FrbSolveStatistics {
    pub solve_time_ms: i64,
    pub iterations: i64,
}
