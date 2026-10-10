pub mod clarabel;
pub mod highs;
pub mod router;
pub mod traits;

pub use router::route_request;
pub use traits::{EngineCapabilities, SolverEngine};
