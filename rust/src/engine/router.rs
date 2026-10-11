use crate::engine::registry;
use crate::engine::traits::SolverEngine;
use crate::errors::FrbSolverError;
use crate::models::dto_request::FrbSolveRequest;

/// Routes a request to the appropriate engine.
///
/// Thin compatibility shim over [`registry::route_request`]: the routing
/// table itself lives in `engine/registry.rs` so new solvers register in
/// exactly one place.
pub fn route_request(
    request: &FrbSolveRequest,
) -> Result<&'static dyn SolverEngine, FrbSolverError> {
    registry::route_request(request)
}
