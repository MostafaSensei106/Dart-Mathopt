use crate::errors::solver::SolverError;
use crate::models::problem::ProblemPayload;

#[derive(Debug, Clone)]
pub struct SolverSolution {
    pub status_code: i32,
    pub objective_value: f64,
    pub variable_values: Vec<f64>,
    pub dual_values: Vec<f64>,
}

pub trait OptimizationSolver: Send + Sync {
    fn name(&self) -> &'static str;
    fn supports_milp(&self) -> bool;
    fn solve(&self, payload: &ProblemPayload) -> Result<SolverSolution, String>;
}
