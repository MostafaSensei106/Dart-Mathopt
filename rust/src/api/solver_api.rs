use crate::engine::router::route_request;
use crate::errors::FrbSolverError;
use crate::models::dto_request::FrbSolveRequest;
use crate::models::dto_response::FrbSolveResponse;

/// FFI entry point: the ONLY function Dart calls to solve a model.
///
/// Runs off the main isolate (async on FRB's thread pool), so a large
/// MILP never blocks the UI. Routes to HiGHS/Clarabel, validates
/// capabilities, then executes.
///
/// NOTE: no `unwrap`/`expect`/`panic` on this path — every failure is a
/// typed [FrbSolverError] (see agents.md 11.2).
pub async fn execute_solve(request: FrbSolveRequest) -> Result<FrbSolveResponse, FrbSolverError> {
    // 1. Route to the appropriate engine.
    let engine = route_request(&request)?;

    // 2. Validate capabilities (defense in depth; adapters re-check
    // via the SolverEngine::validate default).
    engine.validate(&request)?;

    // 3. Execute (borrows the request: zero-copy, no clone).
    let response = engine.solve(&request).await?;

    Ok(response)
}
