//! Native optimization engines behind the `dart_mathopt` FFI boundary.
//!
//! Dart builds a model, compiles it to [`models`] DTOs, and calls
//! [`api::solver_api::execute_solve`], which routes through
//! [`engine::registry`] to one of three [`engine::SolverEngine`]
//! backends: HiGHS (LP/MILP, C++), Clarabel (LP, Rust interior-point),
//! or MicroLP (LP, pure Rust via `good_lp`).
//!
//! HiGHS is a native-only dependency (it is C++ and cannot target
//! WebAssembly). Platform selection is automatic: the engine is compiled
//! only when `target_arch != "wasm32"`, so web builds expose Clarabel
//! and MicroLP without any cargo feature flags.
pub mod api;
pub mod engine;
pub mod errors;
mod frb_generated;
pub mod models;

/// cbindgen:ignore
#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
