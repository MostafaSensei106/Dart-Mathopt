use crate::engine::clarabel::adapter::ClarabelEngine;
#[cfg(not(target_arch = "wasm32"))]
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

#[cfg(not(target_arch = "wasm32"))]
static HIGHS: HighsEngine = HighsEngine;
static CLARABEL: ClarabelEngine = ClarabelEngine;
static MICROLP: MicroLpEngine = MicroLpEngine;

/// The built-in engine table (the only place that names concrete engines).
///
/// HiGHS is compiled only on native targets: it is C++ and cannot be
/// built for WebAssembly. Web builds therefore expose the pure-Rust
/// Clarabel + MicroLP engines, and `route` rejects MILP with a clear
/// [`FrbSolverError::CapabilityError`].
#[cfg(not(target_arch = "wasm32"))]
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

#[cfg(target_arch = "wasm32")]
static BUILTINS: [EngineEntry; 2] = [
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
/// plugin API lands  production routing stays closed and auditable).
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
///   `InvalidInput` error for unknown keys  including `"highs"` on web,
///   where the C++ HiGHS dependency is not compiled in).
/// - `"auto"` (default): integer models (MILP) go to HiGHS on native
///   platforms; continuous LP/QP models go to Clarabel on every platform.
///   MILP on the web has no capable engine and returns
///   [`FrbSolverError::CapabilityError`] with an actionable message.
///
/// `has_quadratic` is plumbed for the future QP DTO switch and currently
/// always false; `has_integer` is derived from the request variables.
pub fn route(
    preference: &str,
    has_integer: bool,
    has_quadratic: bool,
) -> Result<&'static dyn SolverEngine, FrbSolverError> {
    let pref = preference.to_lowercase();
    match pref.as_str() {
        "highs" | "clarabel" | "microlp" => {
            find(&pref).ok_or_else(|| FrbSolverError::InvalidInput(unavailable_message(&pref)))
        }
        "auto" | "" => {
            if has_integer {
                // Only HiGHS handles discrete variables, and it exists
                // exclusively on native targets.
                find("highs").ok_or_else(|| {
                    FrbSolverError::CapabilityError(
                        "Integer/binary (MILP) models require HiGHS, which is only \
                         available on native platforms (Android, iOS, Windows, \
                         macOS, Linux). Web builds support continuous LP only: \
                         relax the integer variables or solve the model natively."
                            .to_string(),
                    )
                })
            } else if has_quadratic {
                find("clarabel").ok_or_else(|| {
                    FrbSolverError::InvalidInput("No QP-capable engine registered.".to_string())
                })
            } else {
                find("clarabel").ok_or_else(|| {
                    FrbSolverError::InvalidInput(
                        "No LP engine registered in this build.".to_string(),
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
    route(
        &request.options.solver,
        request.has_integer(),
        has_quadratic,
    )
}

/// Explains why an explicitly requested engine is missing from this build.
fn unavailable_message(key: &str) -> String {
    let detail = match key {
        #[cfg(target_arch = "wasm32")]
        "highs" => {
            "HiGHS is C++ and cannot be compiled to WebAssembly. Use 'clarabel' \
             or 'microlp' for LP models, or build natively to solve MILP."
        }
        _ => "",
    };
    if detail.is_empty() {
        format!(
            "Engine '{key}' is not registered. Available: {}.",
            available_keys()
        )
    } else {
        format!("Engine '{key}' is not available on this platform: {detail}")
    }
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
    fn auto_routes_lp_to_clarabel() {
        assert_eq!(route("auto", false, false).unwrap().name(), "clarabel");
    }

    #[test]
    fn auto_routes_qp_to_clarabel() {
        assert_eq!(route("auto", false, true).unwrap().name(), "clarabel");
    }

    #[cfg(not(target_arch = "wasm32"))]
    #[test]
    fn auto_routes_milp_to_highs() {
        assert_eq!(route("auto", true, false).unwrap().name(), "highs");
    }

    #[cfg(target_arch = "wasm32")]
    #[test]
    fn auto_milp_on_web_is_a_capability_error() {
        assert!(matches!(
            route("auto", true, false),
            Err(FrbSolverError::CapabilityError(_))
        ));
    }

    #[test]
    fn explicit_preferences_resolve() {
        #[cfg(not(target_arch = "wasm32"))]
        assert_eq!(route("highs", false, false).unwrap().name(), "highs");
        #[cfg(target_arch = "wasm32")]
        assert!(matches!(
            route("highs", false, false),
            Err(FrbSolverError::InvalidInput(_))
        ));
        assert_eq!(route("clarabel", false, false).unwrap().name(), "clarabel");
        assert_eq!(route("microlp", false, false).unwrap().name(), "microlp");
        // Case-insensitive.
        #[cfg(not(target_arch = "wasm32"))]
        assert_eq!(route("HiGHS", false, false).unwrap().name(), "highs");
    }

    #[test]
    fn unknown_preference_is_invalid_input() {
        assert!(matches!(
            route("osqp", false, false),
            Err(FrbSolverError::InvalidInput(_))
        ));
    }

    #[test]
    fn capability_table_is_honest() {
        #[cfg(not(target_arch = "wasm32"))]
        {
            let highs = find("highs").unwrap();
            assert!(highs.capabilities().supports_milp);
        }
        #[cfg(target_arch = "wasm32")]
        assert!(find("highs").is_none());
        let clarabel = find("clarabel").unwrap();
        assert!(!clarabel.capabilities().supports_milp);
        assert!(clarabel.capabilities().supports_qp);
        let microlp = find("microlp").unwrap();
        assert!(!microlp.capabilities().supports_milp);
        assert!(!microlp.capabilities().supports_qp);
    }
}
