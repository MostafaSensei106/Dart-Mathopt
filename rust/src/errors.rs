use thiserror::Error;

/// Central error type returned across the FRB boundary.
///
/// Rules (see agents.md 11):
/// - No `panic!`/`unwrap()`/`expect()` in engine code; convert every
///   failure into one of these variants.
/// - Keep payloads to plain strings/ints so FRB can map them to Dart.
#[derive(Debug, Clone, Error)]
pub enum FrbSolverError {
    /// The selected engine cannot handle this problem class
    /// (e.g. MILP sent to a pure-LP build).
    #[error("Capability error: {0}")]
    CapabilityError(String),

    /// The native engine rejected or failed the solve.
    #[error("Engine failure: {0}")]
    EngineFailure(String),

    /// Input failed validation before reaching the engine.
    #[error("Invalid input: {0}")]
    InvalidInput(String),

    /// The solve exceeded the requested time limit.
    #[error("Time limit exceeded after {0} seconds")]
    TimeLimitExceeded(f64),
}
