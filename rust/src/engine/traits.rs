use crate::errors::FrbSolverError;
use crate::models::dto_request::FrbSolveRequest;
use crate::models::dto_response::FrbSolveResponse;

/// Defines what a specific solver engine can process.
#[derive(Clone, Copy, Debug)]
pub struct EngineCapabilities {
    pub supports_milp: bool,
    pub supports_qp: bool,
    pub supports_socp: bool,
}

/// The core trait that EVERY solver engine must implement.
///
/// Must be `Send + Sync` because FRB executes on a thread pool.
#[async_trait::async_trait]
pub trait SolverEngine: Send + Sync {
    fn capabilities(&self) -> EngineCapabilities;

    /// Executes the solver. Takes a reference to avoid clones (see §11.1).
    async fn solve(&self, request: &FrbSolveRequest) -> Result<FrbSolveResponse, FrbSolverError>;
}
