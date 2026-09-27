use std::sync::Arc;

use crate::api::solvers::solver::OptimizationSolver;

pub enum SolverType {
    Highs,
    Clarabel,
    MicroLp,
}

pub struct SolverFactory;

impl SolverFactory {
    pub fn create(solver_type: SolverType) -> Result<Arc<dyn OptimizationSolver>, SolverError> {
        match solver_type {
            SolverType::Highs => Ok(Arc::new(crate::api::solvers::highs::HighsSolver)),
            _ => Err(SolverError::UnsupportedSolver),
        }

        todo!("Implement solver factory logic to create instances of different solvers based on the provided solver_type.");
    }
}
