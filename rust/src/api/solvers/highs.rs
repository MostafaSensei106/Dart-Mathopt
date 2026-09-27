use crate::api::{
    constants,
    solvers::solver::{OptimizationSolver, SolverSolution},
};

pub struct HighsSolver;

impl OptimizationSolver for HighsSolver {
    fn name(&self) -> &'static str {
        constants::solver_names::HIGHS
    }

    fn supports_milp(&self) -> bool {
        true
    }

    fn solve(&self, payload: &ProblemPayload) -> Result<super::solver::SolverSolution, String> {
        let mut model = payload
            .build_highs_model()
            .map_err(|e| SolverError::ModelBuildFailed(e.to_string()))?;

        let solved = model.solve();

        let solution = solved.get_solution();

        Ok(SolverSolution {
            status_code: 0,
            objective_value: solution.objective_value(),
            variable_values: solution.columns().to_vec(),
            dual_values: vec![],
        })
    }
}
