/// Request-side Data Transfer Objects (Dart -> Rust).
///
/// These structs are mirrored to Dart by flutter_rust_bridge. Field layout
/// is part of the FFI contract: additive changes only, never renames.

#[derive(Clone, Debug)]
pub struct FrbSolveRequest {
    pub name: String,
    pub variables: Vec<FrbVariableDto>,
    pub constraints: Vec<FrbConstraintDto>,
    pub objective: FrbObjectiveDto,
    pub options: FrbSolveOptionsDto,
}

impl FrbSolveRequest {
    /// `true` when any variable is integer or binary.
    pub fn has_integer(&self) -> bool {
        self.variables.iter().any(|v| {
            matches!(
                v.var_type,
                FrbVariableType::Integer | FrbVariableType::Binary
            )
        })
    }
}

#[derive(Clone, Debug)]
pub struct FrbVariableDto {
    /// Matches the Dart-side sequential ID (0-based, dense).
    pub id: u32,
    pub name: String,
    pub var_type: FrbVariableType,
    pub lower_bound: Option<f64>,
    pub upper_bound: Option<f64>,
}

#[derive(Clone, Debug)]
pub enum FrbVariableType {
    Continuous,
    Integer,
    Binary,
}

#[derive(Clone, Debug)]
pub struct FrbConstraintDto {
    pub name: Option<String>,
    /// Sparse representation: (variable_id, coefficient) pairs.
    pub terms: Vec<FrbTermDto>,
    pub sense: FrbConstraintSense,
    pub rhs: f64,
}

#[derive(Clone, Debug)]
pub struct FrbTermDto {
    pub variable_id: u32,
    pub coefficient: f64,
}

#[derive(Clone, Debug)]
pub struct FrbObjectiveDto {
    pub sense: FrbOptimizationSense,
    pub terms: Vec<FrbTermDto>,
    pub constant: f64,
}

#[derive(Clone, Debug)]
pub enum FrbOptimizationSense {
    Minimize,
    Maximize,
}

#[derive(Clone, Debug)]
pub enum FrbConstraintSense {
    LessThanOrEqual,
    GreaterThanOrEqual,
    Equal,
}

#[derive(Clone, Debug)]
pub struct FrbSolveOptionsDto {
    /// Wall-clock limit in seconds (`None` = no limit).
    pub time_limit_sec: Option<f64>,
    /// Forward HiGHS stdout logging.
    pub enable_logging: bool,
    /// Requested thread count (`None` = engine default).
    pub thread_count: Option<u32>,
    /// Forced backend: "auto" | "highs" | "clarabel".
    pub solver: String,
}

impl Default for FrbSolveOptionsDto {
    fn default() -> Self {
        Self {
            time_limit_sec: None,
            enable_logging: false,
            thread_count: None,
            solver: "auto".to_string(),
        }
    }
}
