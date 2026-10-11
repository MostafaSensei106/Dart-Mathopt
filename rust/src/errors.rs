use thiserror::Error;

/// Central error type returned across the FRB boundary.
///
/// Every failure on the solve path converts into one of these variants,
/// so Dart receives typed errors instead of panics or strings.
/// Rules (see agents.md §11):
/// - No `panic!`/`unwrap()`/`expect()` in engine code; convert every
///   failure into one of these variants.
/// - Keep payloads to plain strings/numbers so FRB can map them to Dart.
/// - Timeouts are *statuses*, not errors: no variant exists for them.
#[derive(Debug, Clone, Error)]
pub enum FrbSolverError {
    /// The selected engine cannot handle this problem class.
    ///
    /// Produced before any native work starts, e.g. integer variables
    /// routed to Clarabel or MicroLP. Dart surfaces these as
    /// `ModelValidationException` (usage error), not engine failure.
    /// Payload: what was requested vs. what the engine supports.
    #[error("Capability error: {0}")]
    CapabilityError(String),

    /// The native engine rejected the input or failed the solve.
    ///
    /// Covers build failures (bad options, unknown variable ids),
    /// numerical breakdowns, and unexpected engine errors. Dart surfaces
    /// these as `SolverExecutionException`. Payload: the engine's own
    /// message with context about which step failed.
    #[error("Engine failure: {0}")]
    EngineFailure(String),

    /// Input failed validation before reaching the engine.
    ///
    /// Covers unknown solver keys, non-dense variable ids, out-of-range
    /// bounds, and builds compiled without the requested engine (e.g.
    /// `"highs"` on a `--no-default-features` web build). Dart surfaces
    /// these as `ModelValidationException`.
    #[error("Invalid input: {0}")]
    InvalidInput(String),

    /// Reserved: the solve exceeded the requested time limit.
    ///
    /// Currently unconstructed — adapters report limits as a
    /// time-limit *status* so incumbents survive. Kept so the error
    /// shape stays forward-compatible; Dart maps it to
    /// `SolverTimeoutException` if an engine ever returns it.
    #[error("Time limit exceeded after {0} seconds")]
    TimeLimitExceeded(f64),
}
