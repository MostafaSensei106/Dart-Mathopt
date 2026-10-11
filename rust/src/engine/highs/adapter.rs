use std::num::NonZeroU32;
use std::time::Instant;

use async_trait::async_trait;
use highs::{HighsModelStatus, RowProblem, Sense};

use crate::engine::traits::{EngineCapabilities, SolverEngine};
use crate::errors::FrbSolverError;
use crate::models::dto_request::{
    FrbConstraintSense, FrbOptimizationSense, FrbSolveRequest, FrbVariableType,
};
use crate::models::dto_response::{FrbSolveResponse, FrbSolveStatistics, FrbSolveStatus};

pub struct HighsEngine;

#[async_trait]
impl SolverEngine for HighsEngine {
    fn name(&self) -> &'static str {
        "highs"
    }

    fn description(&self) -> &'static str {
        "HiGHS LP/MILP engine"
    }

    fn capabilities(&self) -> EngineCapabilities {
        EngineCapabilities {
            supports_milp: true,
            supports_qp: false,
            supports_socp: false,
        }
    }

    async fn solve(&self, request: &FrbSolveRequest) -> Result<FrbSolveResponse, FrbSolverError> {
        let started = Instant::now();

        let highs_sense = match request.objective.sense {
            FrbOptimizationSense::Minimize => Sense::Minimise,
            FrbOptimizationSense::Maximize => Sense::Maximise,
        };

        let mut problem = RowProblem::default();
        // Objective coefficients default to 0.0 when absent.
        let mut obj_coef = vec![0.0_f64; request.variables.len()];
        for term in &request.objective.terms {
            let idx = term.variable_id as usize;
            if idx >= obj_coef.len() {
                return Err(FrbSolverError::InvalidInput(format!(
                    "Objective term references unknown variable id {}",
                    term.variable_id
                )));
            }
            obj_coef[idx] += term.coefficient;
        }

        let mut col_indices = Vec::with_capacity(request.variables.len());
        for (i, var) in request.variables.iter().enumerate() {
            if var.id as usize != i {
                return Err(FrbSolverError::InvalidInput(format!(
                    "Variable ids must be dense and zero-based; expected id {i} but found {} ('{}')",
                    var.id, var.name
                )));
            }
            let lb = var.lower_bound.unwrap_or(f64::NEG_INFINITY);
            let ub = var.upper_bound.unwrap_or(f64::INFINITY);
            if lb > ub {
                return Err(FrbSolverError::InvalidInput(format!(
                    "Variable '{}' has lower bound {lb} > upper bound {ub}",
                    var.name
                )));
            }
            let is_integer = matches!(
                var.var_type,
                FrbVariableType::Integer | FrbVariableType::Binary
            );
            if matches!(var.var_type, FrbVariableType::Binary) && (lb < 0.0 || ub > 1.0) {
                // HiGHS does not enforce 0/1 implicitly; the Dart layer
                // normally sets [0,1]. Warn-level guard only documents intent;
                // we still solve with the user-supplied bounds.
            }
            let col = problem.add_column_with_integrality(obj_coef[i], lb..=ub, is_integer);
            col_indices.push(col);
        }

        for constraint in &request.constraints {
            let mut row_factors = Vec::with_capacity(constraint.terms.len());
            for term in &constraint.terms {
                let idx = term.variable_id as usize;
                if idx >= col_indices.len() {
                    return Err(FrbSolverError::InvalidInput(format!(
                        "Constraint references unknown variable id {}",
                        term.variable_id
                    )));
                }
                row_factors.push((col_indices[idx], term.coefficient));
            }
            match constraint.sense {
                FrbConstraintSense::LessThanOrEqual => {
                    problem.add_row(..=constraint.rhs, &row_factors);
                }
                FrbConstraintSense::GreaterThanOrEqual => {
                    problem.add_row(constraint.rhs.., &row_factors);
                }
                FrbConstraintSense::Equal => {
                    problem.add_row(constraint.rhs..=constraint.rhs, &row_factors);
                }
            }
        }

        let mut model = problem.try_optimise(highs_sense).map_err(|e| {
            FrbSolverError::EngineFailure(format!("HiGHS model build failed: {e:?}"))
        })?;

        if let Some(limit) = request.options.time_limit_sec {
            model.try_set_option("time_limit", limit).map_err(|e| {
                FrbSolverError::EngineFailure(format!("HiGHS time_limit option failed: {e:?}"))
            })?;
        }
        model
            .try_set_option("output_flag", request.options.enable_logging)
            .map_err(|e| {
                FrbSolverError::EngineFailure(format!("HiGHS output_flag option failed: {e:?}"))
            })?;
        if let Some(threads) = request.options.thread_count {
            if let Some(nz) = NonZeroU32::new(threads) {
                model.set_threads(nz);
            }
        }

        let solved = model
            .try_solve()
            .map_err(|e| FrbSolverError::EngineFailure(format!("HiGHS solve failed: {e:?}")))?;

        let status = match solved.status() {
            HighsModelStatus::Optimal => FrbSolveStatus::Optimal,
            HighsModelStatus::Infeasible => FrbSolveStatus::Infeasible,
            HighsModelStatus::Unbounded | HighsModelStatus::UnboundedOrInfeasible => {
                FrbSolveStatus::Unbounded
            }
            HighsModelStatus::ReachedTimeLimit
            | HighsModelStatus::ReachedInterrupt
            | HighsModelStatus::ReachedIterationLimit
            | HighsModelStatus::ReachedSolutionLimit => FrbSolveStatus::TimeLimitExceeded,
            HighsModelStatus::SolveError
            | HighsModelStatus::ModelError
            | HighsModelStatus::PresolveError
            | HighsModelStatus::PostsolveError
            | HighsModelStatus::LoadError => FrbSolveStatus::NumericalError,
            _ => FrbSolveStatus::Unknown,
        };

        let solution = solved.get_solution();
        let variable_values = solution.columns().to_vec();
        let dual_values = if request.has_integer() {
            // MILP duals are meaningless or missing.
            None
        } else {
            Some(solution.dual_rows().to_vec())
        };

        let objective_value = match status {
            FrbSolveStatus::Optimal => {
                // HiGHS reports the raw linear objective WITHOUT the Dart-side
                // constant offset; re-add it here.
                Some(solved.objective_value() + request.objective.constant)
            }
            _ => None,
        };

        Ok(FrbSolveResponse {
            status,
            objective_value,
            variable_values,
            dual_values,
            statistics: FrbSolveStatistics::since(
                started,
                solved.simplex_iteration_count().max(0),
            ),
        })
    }
}
