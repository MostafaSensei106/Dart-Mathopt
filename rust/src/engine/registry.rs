use crate::engine::clarabel::adapter::ClarabelEngine;
use crate::engine::highs::adapter::HighsEngine;
use crate::engine::microlp::adapter::MicroLpEngine;
use crate::engine::traits::SolverEngine;
use crate::errors::FrbSolverError;
use crate::models::dto_request::FrbSolveRequest;

/// One registered backend: a stable key plus its engine implementation.
///
/// Adding a solver = implement [`SolverEngine`] + append one entry here.
/// Nothing else (router, API, DTOs) needs to change for LP/MILP shapes;
/// new problem classes (QP/SOCP/…) extend the DTOs additively.
pub struct EngineEntry {
    /// Routing key (`"highs"`, `"clarabel"`, …). Lowercase, stable.
    pub key: &'static str,
    pub engine: &'static dyn SolverEngine,
}

static HIGHS: HighsEngine = HighsEngine;
static CLARABEL: ClarabelEngine = ClarabelEngine;
static MICROLP: MicroLpEngine = MicroLpEngine;

/// The built-in engine table (the only place that names concrete engines).
static BUILTINS: [EngineEntry; 3] = [
    EngineEntry {
        key: "highs",
        engine: &HIGHS,
    },
    EngineEntry {
        key: "clarabel",
        engine: &CLARABEL,
    },
    EngineEntry {
        key: "microlp",
        engine: &MICROLP,
    },
];

/// All registered engines (built-ins for now; custom registration via
/// `register_custom` is intentionally `#[cfg(test)]`-only until a
/// plugin API lands — production routing stays closed and auditable).
pub fn all_engines() -> &'static [EngineEntry] {
    &BUILTINS
}

/// Finds an engine by key (case-insensitive).
pub fn find(key: &str) -> Option<&'static dyn SolverEngine> {
    let lowered = key.to_lowercase();
    all_engines()
        .iter()
        .find(|e| e.key == lowered)
        .map(|e| e.engine)
}

/// Routing decision table:
/// - `"highs"`, `"clarabel"`, `"microlp"` force that engine (or a clear
///   `InvalidInput` error for unknown keys).
/// - `"auto"` (default): HiGHS for LP/MILP (mature integer support);
///   Clarabel once quadratic DTOs mark a QP/SOCP shape. `has_quadratic`
///   is plumbed for that future switch and currently always false.
pub fn route(
    preference: &str,
    has_quadratic: bool,
) -> Result<&'static dyn SolverEngine, FrbSolverError> {
    let pref = preference.to_lowercase();
    match pref.as_str() {
        "highs" | "clarabel" | "microlp" => find(&pref).ok_or_else(|| {
            FrbSolverError::InvalidInput(format!(
                "Engine '{pref}' is not registered. Available: {}.",
                available_keys()
            ))
        }),
        "auto" | "" => {
            if has_quadratic {
                find("clarabel").ok_or_else(|| {
                    FrbSolverError::InvalidInput(
                        "No QP-capable engine registered.".to_string(),
                    )
                })
            } else {
                find("highs").ok_or_else(|| {
                    FrbSolverError::InvalidInput(
                        "No LP/MILP engine registered.".to_string(),
                    )
                })
            }
        }
        other => Err(FrbSolverError::InvalidInput(format!(
            "Unknown solver preference: '{other}'. Expected 'auto', {}.",
            available_keys()
                .split(", ")
                .map(|k| format!("'{k}'"))
                .collect::<Vec<_>>()
                .join(", ")
        ))),
    }
}

/// Routes a full solve request (convenience over [`route`]).
pub fn route_request(
    request: &FrbSolveRequest,
) -> Result<&'static dyn SolverEngine, FrbSolverError> {
    // Quadratic shapes will set this once P-matrix DTOs land.
    let has_quadratic = false;
    route(&request.options.solver, has_quadratic)
}

fn available_keys() -> String {
    all_engines()
        .iter()
        .map(|e| e.key)
        .collect::<Vec<_>>()
        .join(", ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn auto_routes_to_highs() {
        let engine = route("auto", false).unwrap();
        assert_eq!(engine.name(), "highs");
    }

    #[test]
    fn explicit_preferences_resolve() {
        assert_eq!(route("highs", false).unwrap().name(), "highs");
        assert_eq!(route("clarabel", false).unwrap().name(), "clarabel");
        assert_eq!(route("microlp", false).unwrap().name(), "microlp");
        // Case-insensitive.
        assert_eq!(route("HiGHS", false).unwrap().name(), "highs");
    }

    #[test]
    fn unknown_preference_is_invalid_input() {
        match route("osqp", false) {
            Err(FrbSolverError::InvalidInput(_)) => {}
            other => panic!("expected InvalidInput, got {:?}", other.is_ok()),
        }
    }

    #[test]
    fn capability_table_is_honest() {
        let highs = find("highs").unwrap();
        assert!(highs.capabilities().supports_milp);
        let clarabel = find("clarabel").unwrap();
        assert!(!clarabel.capabilities().supports_milp);
        assert!(clarabel.capabilities().supports_qp);
        let microlp = find("microlp").unwrap();
        assert!(!microlp.capabilities().supports_milp);
        assert!(!microlp.capabilities().supports_qp);
    }
}
