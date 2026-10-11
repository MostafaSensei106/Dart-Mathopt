pub mod clarabel;
#[cfg(feature = "highs")]
pub mod highs;
pub mod microlp;
pub mod registry;
pub mod router;
pub mod traits;

pub use registry::{all_engines, find, route_request};
pub use traits::{EngineCapabilities, SolverEngine};
