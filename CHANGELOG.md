## 0.0.1-dev.2

### HiGHS is selected by target, not by a cargo feature

- HiGHS is now a **target-specific dependency** (`[target.'cfg(not(target_arch = "wasm32"))'.dependencies]`) instead of an opt-in cargo feature. The `[features]` table was removed outright: `wasm32-unknown-unknown` builds automatically contain the pure-Rust engines (Clarabel + MicroLP), while Android/iOS/macOS/Windows/Linux automatically contain HiGHS. There is no `--features highs`, no `--no-default-features`, and no build-script or CI plumbing for Dart developers to remember.
- The Rust module gates use the same rule (`#[cfg(not(target_arch = "wasm32"))]`), so the built-in registry holds three engines on native targets and two on the web with no conditional compilation left to configure.
- `auto` routing was redefined around problem class instead of availability: integer models go to HiGHS on native, continuous LP/QP models go to Clarabel on every platform. The decision is now an explicit `route(preference, has_integer, has_quadratic)` function rather than "HiGHS if it happens to be compiled in".
- Web requests are rejected in Dart *before* FFI. `SolverPreference.highs`, and `auto` on a model with integer variables, raise `ModelValidationException` naming the platform limitation, so a web caller receives a usage error instead of an FFI round-trip and a native-shaped failure.
- Defense in depth on the Rust side: an explicit `"highs"` on a WASM build returns `InvalidInput`, and an integer model on an LP-only engine returns `CapabilityError` pointing at HiGHS on native platforms. Nothing on the routing path panics; every unsupported combination maps to a typed `FrbSolverError`.
- **Behaviour change:** `SolverPreference.auto` for LP now resolves to Clarabel instead of HiGHS, so projects relying on the default no longer receive HiGHS duals (shadow prices) for continuous models. Request `highs` explicitly on a native target if you need them.
- Web path: HiGHS is a native-only dependency, so `wasm32-unknown-unknown` builds contain pure-Rust Clarabel + MicroLP with no cargo feature flags; `auto` sends continuous models to Clarabel and MILP on web is rejected with a clear error.

### Architecture decision: what I build next, and what I refuse to build

Base rule: of the 20 capability categories missing from the audit report, only 4 deserve engineering time. The rest are either outside the scope of a client-side Flutter library, or not real gaps at all  capabilities Clarabel and HiGHS already have, hidden behind our linear AST/DTO layer.

Flutter runs on phones and laptops, not on a cluster. Users do not need a supercomputer to run an optimization model; they need speed, stability, and easy modelling for the problems that actually appear in the market.

**Tier 1  open immediately (S/M).** These are not engine limitations; they are ownership gaps in the modelling layer:

- **QP in the DTO.** Exposing the square matrix `P` to Clarabel is the single largest waste in the current design: Clarabel is a conic solver and we use it as a plain LP. QP unlocks portfolio optimization, soft-trajectory/MPC planning, and SVM/least-squares style fitting.
- **SOCP cones.** Same hoarding problem: Clarabel already advertises `supports_socp`, but no DTO can express a cone.
- **Remove the temporary `hasQuadratic` flag** once `P` is representable, so the routing signature stops carrying a placeholder.

**Tier 2  medium (M):**

- **Duals / shadow prices** as first-class response fields, including for the Clarabel path that currently reports none.
- **Modelling helpers:** `implies(a, b)` and Big-M, so conditional and scheduling models do not require hand-built linearizations.
- **SOS1 / SOS2**, which HiGHS supports natively; exposing them removes thousands of manually added binary variables from user models.

**Accepted gap  do not attack:**

- **Pure-Rust MILP / branch-and-bound for the web.** Writing a B&B engine in Rust so web builds can solve MILP is an XL trap: it would underperform HiGHS badly for a large amount of work. Web stays the continuous LP/QP target; Android, iOS, and desktop keep full MILP via HiGHS.

**Out of scope  ignore entirely:**

| Missing category | Reason for exclusion |
| --- | --- |
| **NLP / MINLP** | Requires gradients, Hessians, and non-convex handling; needs engines the size of Ipopt and does not fit a client-side library. |
| **Global optimization / CP-SAT** | Constraint programming relies on domain propagation and a completely different search tree from LP/conic. It is memory-hungry and does not suit phones. |
| **Stochastic / robust / decomposition** | Operations-research tooling built for airlines and global supply chains on large servers (Benders, column generation). There is no mobile use case. |

Net position: extending the DTO contracts and the Dart compiler to cover **QP, conic constraints, and indicator constraints** delivers roughly 90% of the practical power the market needs, without adding a single new engine or another line of C++.

## 0.0.1-dev.1

- Preview release for pub.dev: `LICENSE` carries the full GPL-3.0 text with the commercial-license alternative (`dart pub publish --dry-run` clean).

- Single entry point `DartMathOpt.init(config:)` with `MathOptConfig` presets.
- Engine registries (Dart + Rust); MicroLP pure-Rust LP engine; `anyhow` context at the FFI boundary.
- Compiled-request cache + per-constraint event-loop yields.
- Natural operators (`x + y`, `x * 3`); vectorized builders; N-D indexed variables and grids; logical choice helpers.
- Typed solutions (`hasSolution`/`requireSolution`); NaN math rejected pre-FFI (infinite bounds legal).
- Showcase grows to 12 demos using all three engines: Farm Planning (MicroLP), Juice Blending (Clarabel), Project Funding (`atMostOne`) and Lecture Timetabling (`exactlyOne` grid) on HiGHS.
- Unified console `example.dart`: usage-pattern recipes plus the catalog tour (`tour`/`patterns` args).
- Microsecond engine timings (`solve_time_us`, additive FFI field) with exact adaptive display (`µs`/`ms`/`s`) in the showcase; shared catalog tour for both console entries.
- Test-suite overhaul per testing skills: `test/` mirrors `lib/src/` by module, `group()` everywhere, Arrange-Act-Assert structure, new unit suites (options, logger, loader, exceptions, constraints, DTO contracts, lifecycle, init guard), 89.9% hand-written non-bridge coverage, and a real-solve `integration_test/` flow for the example app (with `solve()` refusing uninitialized use via a clear error).
