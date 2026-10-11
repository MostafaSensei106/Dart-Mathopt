/// Response-side Data Transfer Objects (Rust -> Dart).
///
/// Mirrored to Dart by flutter_rust_bridge like the request side.
/// Two layout rules matter to callers:
/// - `variable_values` is index-aligned with the request's variable IDs:
///   `variable_values[id]` is the primal value of variable `id`. This
///   array layout avoids HashMap overhead across the bridge.
/// - On failure statuses the engine may return NaNs or stale numbers;
///   Dart decides usability from `status`, never from the values alone.

#[derive(Clone, Debug)]
pub struct FrbSolveResponse {
    /// Termination status. Only [`FrbSolveStatus::Optimal`] (and, with
    /// care, [`FrbSolveStatus::TimeLimitExceeded`]) carries usable primals.
    pub status: FrbSolveStatus,
    /// Objective value including the request's constant offset, or `None`
    /// when the engine proved nothing (infeasible, unbounded, errors).
    pub objective_value: Option<f64>,
    /// Primal values indexed by variable ID. Always full-length so the
    /// Dart side can map them positionally; contents are meaningless
    /// unless `status` says otherwise.
    pub variable_values: Vec<f64>,
    /// Dual values per constraint row, or `None` whenever duals don't
    /// apply: integer models (duals are meaningless there) and engines
    /// that don't expose them (Clarabel's conic duals, MicroLP).
    pub dual_values: Option<Vec<f64>>,
    /// Engine-reported timing and iteration counts.
    pub statistics: FrbSolveStatistics,
}

#[derive(Clone, Debug)]
pub enum FrbSolveStatus {
    /// Proven optimal. Values, objective, and (where offered) duals
    /// are usable.
    Optimal,
    /// No point satisfies the constraints. Objective is `None`;
    /// primals must be ignored.
    Infeasible,
    /// The objective improves without bound. Objective is `None`;
    /// primals must be ignored.
    Unbounded,
    /// The time limit hit first. Primals may hold a usable incumbent
    /// (Dart accepts them only when every value is finite); the
    /// objective may be set or `None` depending on the engine.
    TimeLimitExceeded,
    /// The engine failed numerically. Everything except `status` is
    /// unreliable.
    NumericalError,
    /// Termination state the adapter could not classify. Treated as
    /// unusable downstream.
    Unknown,
}

#[derive(Clone, Debug, Default)]
pub struct FrbSolveStatistics {
    /// Engine-reported solve time, millisecond resolution (kept for
    /// backward compatibility).
    pub solve_time_ms: i64,
    /// Microsecond resolution: exact for sub-millisecond solves that
    /// would otherwise report `0 ms`. Additive field, never renamed.
    pub solve_time_us: i64,
    /// Native solver iteration count, or `0` when the engine hides it
    /// (good_lp does not expose simplex counts).
    pub iterations: i64,
}

impl FrbSolveStatistics {
    /// Builds statistics from a start instant, saturating at `i64::MAX`.
    pub fn since(started: std::time::Instant, iterations: i64) -> Self {
        let micros = started.elapsed().as_micros().min(i64::MAX as u128) as i64;
        Self::from_micros(micros, iterations)
    }

    /// Builds statistics from a measured microsecond count, deriving
    /// the millisecond field by truncation. Used when the engine reports
    /// its own time (e.g. Clarabel) instead of wall time.
    pub fn from_micros(micros: i64, iterations: i64) -> Self {
        Self {
            solve_time_ms: micros / 1000,
            solve_time_us: micros,
            iterations,
        }
    }
}
