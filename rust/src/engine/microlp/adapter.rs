use std::time::Instant;

use anyhow::Context;
use async_trait::async_trait;
use good_lp::{
    solvers::{
        microlp::{microlp as microlp_solver, MicroLpProblem},
        ResolutionError, SolutionStatus,
    },
    variable, variables, Expression, Solution as _, SolverModel, Variable as GlVariable,
    WithTimeLimit,
};

use crate::engine::traits::{EngineCapabilities, SolverEngine};
use crate::errors::FrbSolverError;
use crate::models::dto_request::{FrbConstraintSense, FrbOptimizationSense, FrbSolveRequest};
use crate::models::dto_response::{FrbSolveResponse, FrbSolveStatistics, FrbSolveStatus};

/// Pure-Rust LP engine built on `good_lp` with its `microlp` solver.
///
/// Why a third LP engine next to HiGHS: zero C++ (no `highs-sys` native
/// build), so it stays available wherever a C++ toolchain is missing
/// notably Web/WASM. LP-only: integer variables are rejected by the
/// shared [`SolverEngine::validate`] gate before any work starts.
pub struct MicroLpEngine;

/// A built `good_lp` model plus the lookup tables needed to read the
/// solution back in variable-id order.
struct BuiltModel {
    model: MicroLpProblem,
    vars: Vec<GlVariable>,
    objective_terms: Vec<(usize, f64)>,
    objective_constant: f64,
}

#[async_trait]
impl SolverEngine for MicroLpEngine {
    fn name(&self) -> &'static str {
        "microlp"
    }

    fn description(&self) -> &'static str {
        "MicroLP pure-Rust LP engine via good_lp (no C++, LP-only)"
    }

    fn capabilities(&self) -> EngineCapabilities {
        EngineCapabilities {
            supports_milp: false,
            supports_qp: false,
            supports_socp: false,
        }
    }

    async fn solve(&self, request: &FrbSolveRequest) -> Result<FrbSolveResponse, FrbSolverError> {
        self.validate(request)?;
        let started = Instant::now();

        let built = build_model(request)
            .map_err(|e| FrbSolverError::EngineFailure(format!("MicroLP build failed: {e:#}")))?;
        let n = built.vars.len();

        let no_primal = || vec![f64::NAN; n];
        // good_lp does not expose simplex iteration counts.
        let stats = || FrbSolveStatistics::since(started, 0);

        match built.model.solve() {
            Err(ResolutionError::Infeasible) => Ok(FrbSolveResponse {
                status: FrbSolveStatus::Infeasible,
                objective_value: None,
                variable_values: no_primal(),
                dual_values: None,
                statistics: stats(),
            }),
            Err(ResolutionError::Unbounded) => Ok(FrbSolveResponse {
                status: FrbSolveStatus::Unbounded,
                objective_value: None,
                variable_values: no_primal(),
                dual_values: None,
                statistics: stats(),
            }),
            Err(other) => {
                // Time limits surface as `Other("Time limit ...")`; anything
                // else is a genuine engine failure.
                let msg = other.to_string();
                if msg.to_lowercase().contains("time limit") {
                    Ok(FrbSolveResponse {
                        status: FrbSolveStatus::TimeLimitExceeded,
                        objective_value: None,
                        variable_values: no_primal(),
                        dual_values: None,
                        statistics: stats(),
                    })
                } else {
                    Err(FrbSolverError::EngineFailure(format!(
                        "MicroLP solve failed: {msg}"
                    )))
                }
            }
            Ok(solution) => {
                let mut variable_values = Vec::with_capacity(n);
                for v in &built.vars {
                    variable_values.push(solution.value(*v));
                }
                let mut raw_objective = 0.0;
                for (id, coef) in &built.objective_terms {
                    raw_objective += coef * variable_values[*id];
                }
                let (status, objective_value) = match solution.status() {
                    SolutionStatus::Optimal => (
                        FrbSolveStatus::Optimal,
                        Some(raw_objective + built.objective_constant),
                    ),
                    // Feasible-but-not-proven points (time/gap limits) keep
                    // their primal values; the status stays honest.
                    SolutionStatus::TimeLimit | SolutionStatus::GapLimit => (
                        FrbSolveStatus::TimeLimitExceeded,
                        Some(raw_objective + built.objective_constant),
                    ),
                };
                Ok(FrbSolveResponse {
                    status,
                    objective_value,
                    variable_values,
                    // good_lp does not expose LP duals for microlp.
                    dual_values: None,
                    statistics: stats(),
                })
            }
        }
    }
}

/// Translates a solve request into a `good_lp` model.
///
/// `anyhow` carries context (which id/row failed) up to the single
/// `FrbSolverError` conversion at the call site; the FFI boundary itself
/// stays typed.
fn build_model(request: &FrbSolveRequest) -> anyhow::Result<BuiltModel> {
    let n = request.variables.len();
    if n == 0 {
        anyhow::bail!("Cannot solve a model with no variables");
    }

    let mut vars = variables!();
    let mut gl_vars = Vec::with_capacity(n);
    for (i, var) in request.variables.iter().enumerate() {
        if var.id as usize != i {
            anyhow::bail!(
                "Variable ids must be dense and zero-based; expected id {i} but found {} ('{}')",
                var.id,
                var.name
            );
        }
        let mut def = variable();
        if let Some(lb) = var.lower_bound {
            def = def.min(lb);
        }
        if let Some(ub) = var.upper_bound {
            def = def.max(ub);
        }
        // Integer/binary variables never reach here via `solve()` (the
        // capability gate rejects them); they map to continuous as a
        // documented fallback for direct adapter use.
        gl_vars.push(vars.add(def));
    }

    let lookup = |id: u32| {
        let idx = id as usize;
        if idx >= n {
            Err(anyhow::anyhow!("Term references unknown variable id {id}"))
        } else {
            Ok(gl_vars[idx])
        }
    };

    let mut objective = Expression::with_capacity(request.objective.terms.len());
    let mut objective_terms = Vec::with_capacity(request.objective.terms.len());
    for term in &request.objective.terms {
        let gl = lookup(term.variable_id).with_context(|| "bad objective term")?;
        objective.add_mul(term.coefficient, gl);
        objective_terms.push((term.variable_id as usize, term.coefficient));
    }
    let unsolved = match request.objective.sense {
        FrbOptimizationSense::Minimize => vars.minimise(objective),
        FrbOptimizationSense::Maximize => vars.maximise(objective),
    };
    let mut model = unsolved.using(microlp_solver);
    if let Some(limit) = request.options.time_limit_sec {
        anyhow::ensure!(limit.is_finite() && limit > 0.0, "time limit must be positive");
        model = model.with_time_limit(limit);
    }

    // good_lp's microlp backend maps every non-equality constraint to `<=`,
    // so `>=` rows are normalized here (negated coefficients and RHS).
    for (row, constraint) in request.constraints.iter().enumerate() {
        let negate = matches!(constraint.sense, FrbConstraintSense::GreaterThanOrEqual);
        let mut expr = Expression::with_capacity(constraint.terms.len());
        for term in &constraint.terms {
            let gl = lookup(term.variable_id)
                .with_context(|| format!("bad term in constraint row {row}"))?;
            let coef = if negate { -term.coefficient } else { term.coefficient };
            expr.add_mul(coef, gl);
        }
        let rhs = if negate { -constraint.rhs } else { constraint.rhs };
        if matches!(constraint.sense, FrbConstraintSense::Equal) {
            model.add_constraint(expr.eq(rhs));
        } else {
            model.add_constraint(expr.leq(rhs));
        }
    }

    Ok(BuiltModel {
        model,
        vars: gl_vars,
        objective_terms,
        objective_constant: request.objective.constant,
    })
}
