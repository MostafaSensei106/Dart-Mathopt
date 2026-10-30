pub mod clarabel;
// HiGHS is C++ and cannot target WebAssembly; it is compiled in
// automatically on every native platform (Android/iOS/desktop).
#[cfg(not(target_arch = "wasm32"))]
pub mod highs;
pub mod microlp;
pub mod registry;
pub mod router;
pub mod traits;

pub use registry::{all_engines, find, route_request};
pub use traits::{EngineCapabilities, SolverEngine};
