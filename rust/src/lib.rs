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
