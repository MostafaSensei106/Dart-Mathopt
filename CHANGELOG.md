## 0.0.1

- Single entry point `DartMathOpt.init(config:)` with `MathOptConfig` presets.
- Engine registries (Dart + Rust); MicroLP pure-Rust LP engine; `anyhow` context at the FFI boundary.
- Compiled-request cache + per-constraint event-loop yields.
- Natural operators (`x + y`, `x * 3`); vectorized builders; N-D indexed variables and grids; logical choice helpers.
- Typed solutions (`hasSolution`/`requireSolution`); NaN math rejected pre-FFI (infinite bounds legal).
- Web path: `highs` is now an optional cargo feature (default on); `--no-default-features` builds pure-Rust Clarabel + MicroLP to WASM, with `auto` falling back to MicroLP.
- Showcase grows to 12 demos using all three engines: Farm Planning (MicroLP), Juice Blending (Clarabel), Project Funding (`atMostOne`) and Lecture Timetabling (`exactlyOne` grid) on HiGHS.
- Unified console `example.dart`: usage-pattern recipes plus the catalog tour (`tour`/`patterns` args).