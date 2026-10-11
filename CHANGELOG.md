## 0.0.1

- Single entry point `DartMathOpt.init(config:)` with `MathOptConfig` presets.
- Engine registries (Dart + Rust); MicroLP pure-Rust LP engine; `anyhow` context at the FFI boundary.
- Compiled-request cache + per-constraint event-loop yields.
- Natural operators (`x + y`, `x * 3`); vectorized builders; N-D indexed variables and grids; logical choice helpers.
- Typed solutions (`hasSolution`/`requireSolution`); NaN math rejected pre-FFI (infinite bounds legal).
- Web path: `highs` is now an optional cargo feature (default on); `--no-default-features` builds pure-Rust Clarabel + MicroLP to WASM, with `auto` falling back to MicroLP.
- Showcase grows to 12 demos using all three engines: Farm Planning (MicroLP), Juice Blending (Clarabel), Project Funding (`atMostOne`) and Lecture Timetabling (`exactlyOne` grid) on HiGHS.
- Unified console `example.dart`: usage-pattern recipes plus the catalog tour (`tour`/`patterns` args).
- Microsecond engine timings (`solve_time_us`, additive FFI field) with exact adaptive display (`µs`/`ms`/`s`) in the showcase; shared catalog tour for both console entries.
- Test-suite overhaul per testing skills: `test/` mirrors `lib/src/` by module, `group()` everywhere, Arrange-Act-Assert structure, new unit suites (options, logger, loader, exceptions, constraints, DTO contracts, lifecycle, init guard), 89.9% hand-written non-bridge coverage, and a real-solve `integration_test/` flow for the example app (with `solve()` refusing uninitialized use via a clear error).