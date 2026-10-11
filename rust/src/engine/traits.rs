use crate::errors::FrbSolverError;
use crate::models::dto_request::FrbSolveRequest;
use crate::models::dto_response::FrbSolveResponse;

/// Defines what a specific solver engine can process.
///
/// Capabilities are declared, not inferred: each adapter states exactly
/// which problem classes it accepts, and both routers (Dart-side and
/// Rust-side) refuse anything else before native work starts.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct EngineCapabilities {
    /// Accepts integer/binary variables (MILP). Only HiGHS sets this.
    pub supports_milp: bool,
    /// Accepts quadratic objectives. Reserved: no quadratic DTOs exist yet.
    pub supports_qp: bool,
    /// Accepts second-order cone constraints. Reserved like `supports_qp`.
    pub supports_socp: bool,
}

impl EngineCapabilities {
    /// Plain continuous-linear engine: no integers, no quadratics,
    /// no cones. Shared by Clarabel and MicroLP declarations.
    pub const fn lp_only() -> Self {
        Self {
            supports_milp: false,
            supports_qp: false,
            supports_socp: false,
        }
    }
}

/// The core trait that EVERY solver engine must implement.
///
/// Must be `Send + Sync` because FRB executes on a thread pool.
///
/// # Adding a new solver (3 steps)
/// 1. Implement this trait for the new engine type.
/// 2. Append one entry to `BUILTINS` in `engine/registry.rs`.
/// 3. Declare honest [`EngineCapabilities`] — the default
///    [`validate`](SolverEngine::validate) rejects unsupported shapes
///    before any native work starts.
#[async_trait::async_trait]
pub trait SolverEngine: Send + Sync {
    /// Stable routing key (`"highs"`, `"clarabel"`, `"microlp"`).
    /// Must match the Dart-side `SolverPreference` name.
    fn name(&self) -> &'static str;

    /// Human-readable one-liner for logs and diagnostics.
    fn description(&self) -> &'static str {
        self.name()
    }

    /// The problem classes this engine accepts. Keep it honest:
    /// over-claiming produces wrong answers, not just errors.
    fn capabilities(&self) -> EngineCapabilities;

    /// Pre-solve capability check (defense in depth: the router calls
    /// this too). The default rejects integer variables on engines
    /// without MILP support with a clear error.
    fn validate(&self, request: &FrbSolveRequest) -> Result<(), FrbSolverError> {
        let caps = self.capabilities();
        if request.has_integer() && !caps.supports_milp {
            return Err(FrbSolverError::CapabilityError(format!(
                "Engine '{}' does not support integer/binary variables; use HiGHS for MILP",
                self.name()
            )));
        }
        Ok(())
    }

    /// Executes the solver. Takes a reference to avoid clones (see §11.1).
    async fn solve(&self, request: &FrbSolveRequest) -> Result<FrbSolveResponse, FrbSolverError>;
}
