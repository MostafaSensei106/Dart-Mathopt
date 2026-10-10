use async_trait::async_trait;
use clarabel::algebra::CscMatrix;
use clarabel::solver::{
    DefaultSettings, DefaultSolver, IPSolver, NonnegativeConeT, SolverStatus, SupportedConeT,
    ZeroConeT,
};

use crate::engine::traits::{EngineCapabilities, SolverEngine};
use crate::errors::FrbSolverError;
use crate::models::dto_request::{FrbConstraintSense, FrbOptimizationSense, FrbSolveRequest};
use crate::models::dto_response::{FrbSolveResponse, FrbSolveStatistics, FrbSolveStatus};

pub struct ClarabelEngine;

/// Sparse LP system `(A, b, cones)` in Clarabel standard form.
pub type CscSystem = (CscMatrix<f64>, Vec<f64>, Vec<SupportedConeT<f64>>);

#[async_trait]
impl SolverEngine for ClarabelEngine {
    fn capabilities(&self) -> EngineCapabilities {
        EngineCapabilities {
            supports_milp: false,
            supports_qp: true,
            supports_socp: true,
        }
    }

    async fn solve(&self, request: &FrbSolveRequest) -> Result<FrbSolveResponse, FrbSolverError> {
        if request.has_integer() {
            return Err(FrbSolverError::CapabilityError(
                "Clarabel does not support integer/binary variables; use HiGHS for MILP"
                    .to_string(),
            ));
        }

        let n = request.variables.len();
        if n == 0 {
            return Err(FrbSolverError::InvalidInput(
                "Cannot solve a model with no variables".to_string(),
            ));
        }
        for (i, var) in request.variables.iter().enumerate() {
            if var.id as usize != i {
                return Err(FrbSolverError::InvalidInput(format!(
                    "Variable ids must be dense and zero-based; expected id {i} but found {}",
                    var.id
                )));
            }
        }

        // ---- 1. Objective vector q (negated for maximization) ----
        let maximize = matches!(request.objective.sense, FrbOptimizationSense::Maximize);
        let mut q = vec![0.0_f64; n];
        for term in &request.objective.terms {
            let idx = term.variable_id as usize;
            if idx >= n {
                return Err(FrbSolverError::InvalidInput(format!(
                    "Objective term references unknown variable id {}",
                    term.variable_id
                )));
            }
            q[idx] += term.coefficient;
        }
        if maximize {
            for v in q.iter_mut() {
                *v = -*v;
            }
        }

        // ---- 2. Build A/b/cones in Clarabel standard form ----
        // Clarabel: minimize q'x s.t. Ax + s = b, s in K.
        let (a, b, cones) = build_csc_system(request)?;

        // ---- 3. Zero quadratic term (LP); QP wiring lands with P DTOs ----
        let p = CscMatrix::<f64>::zeros((n, n));

        let mut settings = DefaultSettings {
            verbose: request.options.enable_logging,
            ..DefaultSettings::default()
        };
        if let Some(limit) = request.options.time_limit_sec {
            settings.time_limit = limit;
        }

        let mut solver = DefaultSolver::new(&p, &q, &a, &b, &cones, settings)
            .map_err(|e| FrbSolverError::EngineFailure(format!("Clarabel setup failed: {e}")))?;

        // ---- 4. Solve (blocking; runs on FRB's thread pool) ----
        solver.solve();

        // ---- 5. Status mapping ----
        let status = match solver.solution.status {
            SolverStatus::Solved | SolverStatus::AlmostSolved => FrbSolveStatus::Optimal,
            SolverStatus::PrimalInfeasible | SolverStatus::AlmostPrimalInfeasible => {
                FrbSolveStatus::Infeasible
            }
            SolverStatus::DualInfeasible | SolverStatus::AlmostDualInfeasible => {
                FrbSolveStatus::Unbounded
            }
            SolverStatus::MaxTime => FrbSolveStatus::TimeLimitExceeded,
            SolverStatus::MaxIterations => FrbSolveStatus::TimeLimitExceeded,
            SolverStatus::NumericalError | SolverStatus::InsufficientProgress => {
                FrbSolveStatus::NumericalError
            }
            _ => FrbSolveStatus::Unknown,
        };

        // ---- 6. Solution extraction ----
        let mut variable_values = solver.solution.x.clone();
        // Guard against short returns on failure paths.
        variable_values.resize(n, f64::NAN);

        let objective_value = match status {
            FrbSolveStatus::Optimal => {
                let raw = solver.solution.obj_val;
                let oriented = if maximize { -raw } else { raw };
                Some(oriented + request.objective.constant)
            }
            _ => None,
        };

        Ok(FrbSolveResponse {
            status,
            objective_value,
            variable_values,
            // Clarabel duals (z) live in conic space, not per-constraint-row
            // LP duals; exposing them raw would mislead. Reserved for later.
            dual_values: None,
            statistics: FrbSolveStatistics {
                solve_time_ms: (solver.solution.solve_time * 1000.0) as i64,
                iterations: solver.solution.iterations as i64,
            },
        })
    }
}

/// Converts constraints + variable bounds to `(A, b, cones)`.
///
/// Row conventions (see module docs):
///   - `a.x <= rhs` -> `(a, rhs, Nonnegative)`
///   - `a.x >= rhs` -> `(-a, -rhs, Nonnegative)`
///   - `a.x == rhs` -> `(a, rhs, Zero)`
///
/// Variable bounds become extra single-entry rows.
pub fn build_csc_system(request: &FrbSolveRequest) -> Result<CscSystem, FrbSolverError> {
    let n = request.variables.len();
    let mut rows_i: Vec<usize> = Vec::new();
    let mut cols_j: Vec<usize> = Vec::new();
    let mut vals_v: Vec<f64> = Vec::new();
    let mut b: Vec<f64> = Vec::new();
    let mut cones: Vec<SupportedConeT<f64>> = Vec::new();

    let push_row = |col_ids: &[usize],
                    coefs: &[f64],
                    rhs: f64,
                    sense: &FrbConstraintSense,
                    rows_i: &mut Vec<usize>,
                    cols_j: &mut Vec<usize>,
                    vals_v: &mut Vec<f64>,
                    b: &mut Vec<f64>,
                    cones: &mut Vec<SupportedConeT<f64>>| {
        let row = b.len();
        match sense {
            FrbConstraintSense::LessThanOrEqual => {
                for (c, v) in col_ids.iter().zip(coefs.iter()) {
                    rows_i.push(row);
                    cols_j.push(*c);
                    vals_v.push(*v);
                }
                b.push(rhs);
                cones.push(NonnegativeConeT(1));
            }
            FrbConstraintSense::GreaterThanOrEqual => {
                for (c, v) in col_ids.iter().zip(coefs.iter()) {
                    rows_i.push(row);
                    cols_j.push(*c);
                    vals_v.push(-*v);
                }
                b.push(-rhs);
                cones.push(NonnegativeConeT(1));
            }
            FrbConstraintSense::Equal => {
                for (c, v) in col_ids.iter().zip(coefs.iter()) {
                    rows_i.push(row);
                    cols_j.push(*c);
                    vals_v.push(*v);
                }
                b.push(rhs);
                cones.push(ZeroConeT(1));
            }
        }
    };

    // User constraints.
    for constraint in &request.constraints {
        let mut col_ids = Vec::with_capacity(constraint.terms.len());
        let mut coefs = Vec::with_capacity(constraint.terms.len());
        for term in &constraint.terms {
            let idx = term.variable_id as usize;
            if idx >= n {
                return Err(FrbSolverError::InvalidInput(format!(
                    "Constraint references unknown variable id {}",
                    term.variable_id
                )));
            }
            col_ids.push(idx);
            coefs.push(term.coefficient);
        }
        push_row(
            &col_ids,
            &coefs,
            constraint.rhs,
            &constraint.sense,
            &mut rows_i,
            &mut cols_j,
            &mut vals_v,
            &mut b,
            &mut cones,
        );
    }

    // Variable bounds as extra rows.
    for (i, var) in request.variables.iter().enumerate() {
        if let Some(lb) = var.lower_bound {
            if lb.is_finite() {
                push_row(
                    &[i],
                    &[1.0],
                    lb,
                    &FrbConstraintSense::GreaterThanOrEqual,
                    &mut rows_i,
                    &mut cols_j,
                    &mut vals_v,
                    &mut b,
                    &mut cones,
                );
            }
        }
        if let Some(ub) = var.upper_bound {
            if ub.is_finite() {
                push_row(
                    &[i],
                    &[1.0],
                    ub,
                    &FrbConstraintSense::LessThanOrEqual,
                    &mut rows_i,
                    &mut cols_j,
                    &mut vals_v,
                    &mut b,
                    &mut cones,
                );
            }
        }
    }

    let m = b.len();
    let a = CscMatrix::new_from_triplets(m, n, rows_i, cols_j, vals_v);
    Ok((a, b, cones))
}
