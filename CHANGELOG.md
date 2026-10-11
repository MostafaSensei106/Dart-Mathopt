## 0.0.1

- fist version
- Single entry point `DartMathOpt.init(config:)` with `MathOptConfig` presets.
- Engine registries (Dart + Rust); MicroLP pure-Rust LP engine; `anyhow` context at the FFI boundary.
- Compiled-request cache + per-constraint event-loop yields.
- Natural operators (`x + y`, `x * 3`); vectorized builders; N-D indexed variables and grids; logical choice helpers.
- Typed solutions (`hasSolution`/`requireSolution`); NaN math rejected pre-FFI (infinite bounds legal).