use crate::engine::router::route_request;
use crate::errors::FrbSolverError;
use crate::models::dto_request::FrbSolveRequest;
use crate::models::dto_response::FrbSolveResponse;

/// FFI entry point: the ONLY function Dart calls to solve a model.
///
/// Runs off the main isolate (async on FRB's thread pool), so a large
/// MILP never blocks the UI. The three steps never change order:
///
/// 1. **Route** to the engine named by `request.options.solver`
///    (`"auto"` sends MILP to HiGHS on native targets and continuous
///    LP/QP to Clarabel everywhere).
/// 2. **Validate** capabilities through the engine trait default
///    (integer models on LP-only engines fail here, before any
///    native work, with `FrbSolverError::CapabilityError`).
/// 3. **Execute** by lending the engine a borrow of the request
///    zero-copy, no clone (see §11.1).
///
/// NOTE: no `unwrap`/`expect`/`panic` on this path  every failure is a
/// typed `FrbSolverError` (see agents.md §11.2). Timeouts are not
/// errors: they come back inside the response as a time-limit status.
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
