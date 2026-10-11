use crate::errors::FrbSolverError;
use crate::models::dto_request::FrbSolveRequest;
use crate::models::dto_response::FrbSolveResponse;

/// Defines what a specific solver engine can process.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct EngineCapabilities {
    pub supports_milp: bool,
    pub supports_qp: bool,
    pub supports_socp: bool,
}

impl EngineCapabilities {
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
/// 2. Add one line in `engine/registry.rs` (`register_builtin`).
/// 3. Declare honest [`EngineCapabilities`] — the default
///    [`validate`](SolverEngine::validate) rejects unsupported shapes
///    before any native work starts.
#[async_trait::async_trait]
pub trait SolverEngine: Send + Sync {
    fn name(&self) -> &'static str;

    fn description(&self) -> &'static str {
        self.name()
    }

    fn capabilities(&self) -> EngineCapabilities;
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
