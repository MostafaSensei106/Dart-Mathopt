/// Names of the solvers supported by the API.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SolversNames {
    Highs,
}

/// Solver name constants used by configuration code.
pub mod solver_names {
    pub const HIGHS: &str = "highs";
}

/// Default solver configuration values.
pub mod defaults {
    pub const SOLVER: &str = super::solver_names::HIGHS;
}
