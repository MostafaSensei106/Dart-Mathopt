use crate::engine::clarabel::adapter::ClarabelEngine;
use crate::engine::highs::adapter::HighsEngine;
use crate::engine::traits::SolverEngine;
use crate::errors::FrbSolverError;
use crate::models::dto_request::FrbSolveRequest;

/// Routes a request to the appropriate engine.
///
/// Decision table:
/// - `solver == "clarabel"` forces Clarabel.
/// - `solver == "highs"` forces HiGHS.
/// - `"auto"` (default): Clarabel is currently LP-capable too, but HiGHS
///   remains the default for LP/MILP because of its mature MILP support.
///   (QP/SOCP shapes will route to Clarabel once quadratic DTOs land.)
pub fn route_request(
    request: &FrbSolveRequest,
) -> Result<&'static dyn SolverEngine, FrbSolverError> {
    static HIGHS: HighsEngine = HighsEngine;
    static CLARABEL: ClarabelEngine = ClarabelEngine;

    let preference = request.options.solver.to_lowercase();
    match preference.as_str() {
        "highs" => Ok(&HIGHS),
        "clarabel" => Ok(&CLARABEL),
        "auto" | "" => Ok(&HIGHS),
        other => Err(FrbSolverError::InvalidInput(format!(
            "Unknown solver preference: '{other}'. Expected 'auto', 'highs' or 'clarabel'."
        ))),
    }
}
