/// Request-side Data Transfer Objects (Dart -> Rust).
///
/// These structs are mirrored to Dart by flutter_rust_bridge: every doc
/// comment here is transferred to the generated Dart models, so write
/// for Dart developers, not just Rust readers.
///
/// Field layout is part of the FFI contract: additive changes only
/// (new fields must be `Option`al or have wire-compatible defaults),
/// never renames or reordering.
///
/// Three invariants hold for every request the Dart compiler produces:
/// - Variable ids are dense and zero-based (`id == position`), so engines
///   index arrays instead of hashing maps.
/// - Constraint constants are already folded into `rhs`
///   (`terms + k (sense) rhs` arrives as `terms (sense) (rhs - k)`).
/// - `options` carries *effective* values: per-call options merged over
///   the global config Dart-side, so engines never see "auto" leftovers
///   beyond the `solver` routing key.

#[derive(Clone, Debug)]
pub struct FrbSolveRequest {
    /// Model name, diagnostics only. Never affects the solution.
    pub name: String,
    /// Decision variables in id order. Must be non-empty and dense.
    pub variables: Vec<FrbVariableDto>,
    /// Constraints in insertion order. May be empty (bound-only models).
    pub constraints: Vec<FrbConstraintDto>,
    /// Objective sense, linear terms, and the constant offset.
    pub objective: FrbObjectiveDto,
    /// Effective per-solve options (time limit, logging, threads, engine).
    pub options: FrbSolveOptionsDto,
}

impl FrbSolveRequest {
    /// `true` when any variable is integer or binary.
    ///
    /// Drives two decisions: the Dart-side router prefers MILP-capable
    /// engines, and adapters suppress dual values for such models
    /// (integer duals are meaningless).
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
    /// Dense zero-based id matching the variable's position in
    /// [`FrbSolveRequest::variables`]. Engines reject gaps.
    pub id: u32,
    /// Stable human-readable name, diagnostics only.
    pub name: String,
    /// Continuous, integer, or binary domain.
    pub var_type: FrbVariableType,
    /// Lower bound, or `None` when unbounded below. Must not be NaN
    /// (rejected Dart-side); infinite values mean "no bound".
    pub lower_bound: Option<f64>,
    /// Upper bound, or `None` when unbounded above. Same NaN rule.
    pub upper_bound: Option<f64>,
}

#[derive(Clone, Debug)]
pub enum FrbVariableType {
    /// Any real value within bounds.
    Continuous,
    /// Whole numbers within bounds. Only MILP-capable engines accept it.
    Integer,
    /// Either 0 or 1. The Dart layer normally also sets bounds `[0, 1]`.
    Binary,
}

#[derive(Clone, Debug)]
pub struct FrbConstraintDto {
    /// Optional human-readable label, diagnostics only.
    /// `None` for anonymous constraints built by helpers.
    pub name: Option<String>,
    /// Sparse left-hand side: (variable_id, coefficient) pairs in
    /// ascending id order. Every id must exist in the request.
    pub terms: Vec<FrbTermDto>,
    /// The relation between the term sum and `rhs`.
    pub sense: FrbConstraintSense,
    /// Right-hand side with the expression constant already folded in.
    /// Must be finite (rejected Dart-side otherwise).
    pub rhs: f64,
}

#[derive(Clone, Debug)]
pub struct FrbTermDto {
    /// Referenced variable id (must be `< variables.len()`).
    pub variable_id: u32,
    /// Linear coefficient. Duplicate ids for one variable are summed
    /// by the Dart compiler before crossing, so engines may add blindly.
    /// Must be finite.
    pub coefficient: f64,
}

#[derive(Clone, Debug)]
pub struct FrbObjectiveDto {
    /// Minimize or maximize the term sum plus [`Self::constant`].
    pub sense: FrbOptimizationSense,
    /// Sparse linear terms, same layout as constraint terms.
    pub terms: Vec<FrbTermDto>,
    /// Constant offset. Engines optimize the pure linear part and add
    /// this back when reporting the objective value, so
    /// `minimize(x + 5)` reports 5 more than the raw engine objective.
    pub constant: f64,
}

#[derive(Clone, Debug)]
pub enum FrbOptimizationSense {
    /// Find the smallest objective value.
    Minimize,
    /// Find the largest objective value. Adapters that only minimize
    /// (e.g. Clarabel) negate the coefficients internally and flip
    /// the reported value back.
    Maximize,
}

#[derive(Clone, Debug)]
pub enum FrbConstraintSense {
    /// Left-hand side must be less than or equal to `rhs`.
    LessThanOrEqual,
    /// Left-hand side must be greater than or equal to `rhs`.
    /// Backends without native support (e.g. good_lp's microlp
    /// mapping) normalize this by negating terms and `rhs`.
    GreaterThanOrEqual,
    /// Both sides must be equal.
    Equal,
}

#[derive(Clone, Debug)]
pub struct FrbSolveOptionsDto {
    /// Wall-clock limit in seconds (`None` = no limit). Timeouts surface
    /// as a time-limit status, never as an error.
    pub time_limit_sec: Option<f64>,
    /// Forward native solver logging (HiGHS `output_flag`, Clarabel
    /// verbose). Off by default: solver stdout pollutes app logs.
    pub enable_logging: bool,
    /// Requested thread count (`None` = engine default). Values of 0
    /// are ignored by adapters that need non-zero counts.
    pub thread_count: Option<u32>,
    /// Routing key: `"auto" | "highs" | "clarabel" | "microlp"`.
    /// `"auto"` sends integer models to HiGHS on native platforms and
    /// continuous LP/QP models to Clarabel on every platform. HiGHS is a
    /// native-only dependency, so `"highs"` on a web build fails fast
    /// with an invalid-input error explaining the platform limitation;
    /// MILP on the web fails with a capability error. Unknown keys fail
    /// fast with an invalid-input error naming the available engines.
    pub solver: String,
}

impl Default for FrbSolveOptionsDto {
    /// Quiet, unlimited, engine-chosen threads, automatic routing.
    fn default() -> Self {
        Self {
            time_limit_sec: None,
            enable_logging: false,
            thread_count: None,
            solver: "auto".to_string(),
        }
    }
}
