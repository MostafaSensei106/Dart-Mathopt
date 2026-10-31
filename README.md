<h1 align="center">Dart-Mathopt</h1>
<p align="center">
  <img src="https://socialify.git.ci/MostafaSensei106/dart_mathopt/image?custom_language=Rust&font=KoHo&language=1&logo=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F138288138%3Fv%3D4&name=1&owner=1&pattern=Floating+Cogs&theme=Light" alt="Banner">
</p>

<p align="center">
  <strong>Mathematical optimization for Dart &amp; Flutter, solved by native engines through Rust.</strong><br>
  Write models as <i>equations in Dart</i>, solve <i>LP and MILP</i> outside the UI isolate, and switch between <i>HiGHS, Clarabel, and MicroLP</i> with one setting.
</p>

<p align="center">
  <a href="https://pub.dev/packages/dart_mathopt"><img src="https://img.shields.io/pub/v/dart_mathopt.svg" alt="pub version"></a>
  <a href="https://pub.dev/packages/dart_mathopt/score"><img src="https://img.shields.io/pub/points/dart_mathopt.svg" alt="pub points"></a>
  <img src="https://img.shields.io/badge/status-dev%20preview-orange" alt="Status: development preview">
  <img src="https://img.shields.io/badge/platforms-android%20%7C%20ios%20%7C%20linux%20%7C%20macos%20%7C%20windows-blue" alt="Platforms">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-blue" alt="License: GPL-3.0"></a>
</p>

> **Development preview (`0.0.1-dev.1`):** this is a trial release for early feedback. The public API may still change before the first stable version pin the exact version in your `pubspec.yaml` and report anything that breaks.

<p align="center">
  <a href="#-key-features">Key Features</a> •
  <a href="#-why-choose-dart_mathopt">Why?</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-basic-usage">Basic Usage</a> •
  <a href="#-advanced-usage">Advanced Usage</a> •
  <a href="#-solver-engines">Solver Engines</a> •
  <a href="#-showcase-demo">Showcase Demo</a> •
  <a href="#-performance-benchmarks">Benchmarks</a> •
  <a href="#-contributing">Contributing</a>
</p>

---

## ✨ Key Features

| Area | What you get |
| :--- | :--- |
| **Modeling** | Variables, objectives, and constraints written as equations (`x + y <= 4`); indexed variables (`continuousGrid`, N-D `indexed`); balanced `Expr.sum` / `Expr.dot` builders that avoid deep expression chains |
| **Choice constraints** | `exactlyOne` / `atMostOne` / `atLeastOne` over binary variables, compiled through the standard constraint path |
| **Engines** | HiGHS (LP/MILP, C++), Clarabel (LP, Rust interior-point), MicroLP (LP, pure Rust via `good_lp`), selected with `SolverPreference`; unsupported combinations are rejected before FFI |
| **Web builds** | HiGHS is a native-only dependency (excluded from this package’s WASM build), so web builds automatically get Clarabel + MicroLP only |
| **Configuration** | `DartMathOpt.init(config:)` with presets (`fastLp` / `accurateMilp` / `lowMemory` / `verbose`); per-call `SolveOptions` override the global config field by field |
| **Repeated solves** | The compiled request is reused while the model is unchanged (`lastSolveWasCached`); any structural edit invalidates it |
| **Results** | `hasSolution` reports whether a usable primal exists, `isOptimal` whether optimality was proved; `requireSolution()` returns either an optimal solution or an incumbent, and throws only when there is none |
| **Responsiveness** | Solvers run on the bridge thread pool, and compilation yields to the event loop per constraint, so timers and animations continue during long solves |
| **Validation** | NaN bounds and NaN/infinite coefficients are rejected before FFI with the offending constraint or objective named; infinite bounds remain allowed |

---

## 🤔 Why Choose dart_mathopt?

> Optimization code usually ends up as index arithmetic: hand-built matrices, manual bounds, and often a separate backend service just to run a solver.

When a Dart or Flutter application needs to make a computed decision, such as how much to produce, who works which shift, or which warehouses to open, the usual options are to reimplement solver logic by hand or to send the problem to a server. `dart_mathopt` keeps that work inside the Dart codebase: the model is written next to the application code, the computation runs locally in native engines, and engine limitations are reported before the call crosses into native code rather than after.

### 📊 The three engines compared

| | **HiGHS** | **Clarabel** | **MicroLP** |
| :--- | :--- | :--- | :--- |
| **Algorithm** | Simplex-based LP with branch-and-bound for integers (C++ core) | Primal-dual interior-point method with homogeneous embedding (Rust) | Bounded-variable simplex in pure Rust (driven through `good_lp`) |
| **Problem classes in this package** | LP and MILP | LP (linear models; quadratic DTOs are not wired yet) | LP |
| **Integer/binary variables** | Supported | Rejected before FFI | Rejected before FFI |
| **Dual values** | Returned for pure LP only | Not exposed | Not exposed |
| **Native requirements** | C++ toolchain (`highs-sys`) | None | None |
| **Web (WASM)** | Excluded automatically (native-only dependency) | Included | Included |
| **Typical use** | Integer decisions (assignment, packing, scheduling, facility choice), LP models where dual values are needed | LP solving with a Rust interior-point engine; later quadratic/conic models | Targets without a C++ toolchain, and web builds |

The selection policy, per-engine behavior, and measured numbers are documented under [Solver Engines](#-solver-engines) and [Benchmarks](#-performance-benchmarks).

---

## 📦 Installation

### 1. Prerequisites (The Rust Toolchain)

This library connects Flutter and Rust through a bridge, so the Rust compiler is required on the development machine.

- **Windows**: Download and run [rustup-init.exe](https://rustup.rs).
- **macOS / Linux**: Run the following command in your terminal:
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```

> **Note:** For Flutter applications, the platform build scripts compile the Rust core during the normal app build, so no manual `cargo` step is needed. When working on this repository itself (`flutter test`, `dart run example/...`), build the native library once so tests can load it:
> ```bash
> cargo build --release --manifest-path rust/Cargo.toml
> ```

### 2. Add the Dependency

```bash
flutter pub add dart_mathopt
```

Or add it manually to your `pubspec.yaml`:

```yaml
dependencies:
  dart_mathopt: ^0.0.1-dev.1
```

Then fetch packages:

```bash
flutter pub get
```

---

## 🚀 Basic Usage

### 1. Initialize once

Initialize the entry point once: it finds and loads the native library, so application code never deals with FFI setup.

```dart
import 'package:dart_mathopt/dart_mathopt.dart';

Future<void> main() async {
  await DartMathOpt.init();
  runApp(const MyApp());
}
```

### 2. Write a model and solve it

Declare variables, add constraints, set an objective, solve, and read the result with a status check.

```dart
final model = MathOptModel(name: 'demo');
final x = model.continuous('x', lower: 0);
final y = model.continuous('y', lower: 0);
model.add(x + y <= 4);
model.maximize(x * 3 + y * 5);

final result = await model.solve();
if (result.isOptimal) {
  print(result.objectiveValue); // 20.0
  print(result.valueOf(y));     // 4.0
}
```

Expressions start from a variable (`x * 3`, not `3 * x`, because Dart resolves `num` operators first). Core solving examples are covered by [`test/integration/readme_examples_test.dart`](test/integration/readme_examples_test.dart); advanced fragments require the surrounding variables shown or described.

### 3. Integer decisions and engine choice

```dart
final model = MathOptModel(name: 'Knapsack');
final packed = [for (var i = 0; i < 4; i++) model.binary('p$i')];
model.maximize(Expr.dotLists(packed, [1000.0, 800.0, 400.0, 500.0]));
model.add(Expr.dotLists(packed, [2.0, 1.5, 0.8, 0.2]) <= 3.0);

final r = await model.solve(
  options: const SolveOptions(
    solver: SolverPreference.highs, // auto | highs | clarabel | microlp
    timeLimitSec: 30,
  ),
);
print(r.objectiveValue); // 1900.0 (HiGHS solves the integers)
print(r.dualValues);     // null: integer models have no duals
```

### 4. One model, three engines

```dart
Future<double?> solveOn(SolverPreference engine) async {
  final model = MathOptModel(name: 'Engines');
  final a = model.continuous('A', lower: 0);
  final b = model.continuous('B', lower: 0);
  model.maximize(a * 30 + b * 50);
  model.add((a * 2 + b * 1) <= 20);
  model.add((a * 1 + b * 3) <= 15);
  final r = await model.solve(options: SolveOptions(solver: engine));
  return r.isOptimal ? r.objectiveValue : null;
}

print(await solveOn(SolverPreference.highs));    // 370.0
print(await solveOn(SolverPreference.clarabel)); // ~370.0 (interior-point tolerance)
print(await solveOn(SolverPreference.microlp));  // 370.0
```

### 5. Non-optimal results are statuses, not exceptions

```dart
final model = MathOptModel(name: 'Capped');
final x = model.continuous('x', lower: 0);
model.add(x <= 1);
model.add(x >= 2); // contradictory: no feasible point
model.minimize(x.asExpr);

final r = await model.solve();
print(r.status);       // SolveStatus.infeasible
print(r.hasSolution);  // false: nothing usable came back
print(r.objectiveValue); // null
```

---

## 🔬 Advanced Usage

> The fragments below assume initialization and an existing `MathOptModel`; supply, demand, and choice-variable lists are application inputs.

### Indexed variables instead of manual indexing

```dart
final ship = model.continuousGrid('s', rows: 3, cols: 4, lower: 0);
ship[0][1];       // the variable named s_0_1
ship.row(0).sum;  // one expression summing the whole row

model.addAll([
  for (var i = 0; i < 3; i++) ship.row(i).sum <= supply[i],
  for (var j = 0; j < 4; j++) Expr.sumVars(ship.column(j)).eq(demand[j]),
]);
```

Models with more than two dimensions use `model.indexed('ship', [f, w, t], VariableType.continuous, lower: 0)`
with `at([i, j, t])`, `select({0: i})`, and `sumsAlong(dim)`. Names follow the row-major pattern `'name_i_j_...'`, and out-of-range indices raise errors that name the dimension. Integer and binary grids use `integerGrid` / `binaryGrid`.

### Choice constraints and reading solutions

```dart
model.add(exactlyOne(sections)); // sum == 1, binary variables required
model.add(atMostOne(options));   // sum <= 1
model.add(atLeastOne(backups));  // sum >= 1

final solution = result.requireSolution(); // optimal solution or incumbent
if (solution.isOptimal) {
  // Optimality was proved; otherwise this is a usable incumbent.
}
print(result.hasSolution); // whether any usable primal exists
```

### Configuration presets and repeated solves

```dart
await DartMathOpt.init(config: MathOptConfig.fastLp());
// accurateMilp() | lowMemory() | verbose() | balanced (default)

await model.solve(); // compiles the model
await model.solve(); // cache hit: model.lastSolveWasCached == true
```

---

## 🧠 Solver Engines

One model, three backends. `SolverPreference.auto` sends integer models (MILP) to HiGHS on native platforms (desktop and mobile) and continuous LP models to Clarabel everywhere. QP routing is reserved for future use; the current public modeling API is linear only. HiGHS is a native-only dependency, so web builds contain Clarabel and MicroLP only; MILP on the web is rejected with a clear `ModelValidationException` before FFI. On the web, explicitly selecting HiGHS raises `ModelValidationException` in Dart before FFI; direct bridge requests receive Rust `InvalidInput`.

### Usage changes in the latest source

See [`CHANGELOG.md`](CHANGELOG.md#001-dev2) for the `0.0.1-dev.2` changes; `pubspec.yaml` still declares `0.0.1-dev.1`.

- `SolverPreference.auto` now selects Clarabel for continuous LP, instead of HiGHS. Select HiGHS explicitly on native platforms when you need LP dual values.
- Integer and binary models use HiGHS automatically on native platforms. Web builds reject MILP; choosing Clarabel or MicroLP does not relax integer variables automatically.
- The build target selects the engines: native builds include all three, WASM builds include Clarabel and MicroLP. No `--features highs` or `--no-default-features` flags are needed.

```dart
// Native only: preserve LP shadow prices after the auto-routing change.
final model = MathOptModel(name: 'Shadow_prices');
final x = model.continuous('x', lower: 0);
model.add(x <= 10);
model.maximize(x * 3);
final result = await model.solve(
  options: const SolveOptions(solver: SolverPreference.highs),
);
if (result.isOptimal) {
  print(result.valueOf(x));       // 10.0
  print(result.dualValues);       // One value per constraint, in insertion order.
}
```

```dart
// Continuous LP: works with the engines included in native and WASM builds.
final model = MathOptModel(name: 'Portable_LP');
final x = model.continuous('x', lower: 0, upper: 10);
model.maximize(x * 3);
final result = await model.solve(
  options: const SolveOptions(solver: SolverPreference.auto), // Clarabel
);
if (result.hasSolution) {
  final solution = result.requireSolution();
  print(solution.valueOf(x)); // Approximately 10.0
  print(solution.isOptimal); // Check before claiming optimality.
}
```

### Supported problem classes and why others are unavailable

Support below means accessible through this package’s current public Dart API, rather than every capability of the underlying engines. LP means linear programming; MILP adds integer/binary variables; QP adds a quadratic objective; SOCP adds second-order cone constraints.

| Model or output | HiGHS (native) | Clarabel (native / WASM) | MicroLP (native / WASM) | Reason / current limitation |
| :--- | :--- | :--- | :--- | :--- |
| Continuous LP, minimize or maximize | Supported | Supported; default for `auto` | Supported | Linear objectives and `<=`, `>=`, `.eq()` constraints are compiled to sparse linear DTOs. |
| Integer / binary / mixed-integer linear models (MILP) | Supported; default for integer `auto` | Unsupported | Unsupported | Only HiGHS is declared MILP-capable in this package; the other adapters reject discrete variables. |
| MILP on web | Unavailable | Unsupported | Unsupported | HiGHS is excluded from WASM builds and no web MILP backend is exposed. |
| Convex quadratic objective (QP) | Unsupported through this API | Planned; unavailable through this API | Unsupported | The compiler is linear-only and objective DTOs have no quadratic matrix, even though Clarabel has QP capability flags. |
| SOCP / other conic constraints | Unsupported through this API | Planned for SOCP; unavailable through this API | Unsupported | No public cone builders or cone DTOs; Clarabel currently receives linear constraints and a zero quadratic term. |
| Quadratic constraints / MIQP / MIQCP | Unsupported | Unsupported | Unsupported | No quadratic expression/constraint transport or mixed-integer quadratic integration. |
| General nonlinear / nonconvex models (NLP / MINLP) | Unsupported | Unsupported | Unsupported | No nonlinear compiler, derivative interface, or suitable integrated backend. Products of variable expressions are rejected. |
| Choice constraints (`exactlyOne`, `atMostOne`, `atLeastOne`) | Supported | Unsupported | Unsupported | Helpers require binary variables and emit ordinary linear constraints, so they need the MILP backend. |
| Indicator / implication / SOS1 / SOS2 builders | Unavailable | Unavailable | Unavailable | No public builders or DTO support. Conditional rules can be modeled manually as linear MILP constraints when a valid Big-M formulation is available. |
| CP-SAT / global optimization | Unsupported | Unsupported | Unsupported | No constraint-programming or global-search backend is integrated. |
| Stochastic / robust / decomposition workflows | No dedicated API | No dedicated API | No dedicated API | No scenario, uncertainty, Benders, or column-generation orchestration; a manually formulated LP/MILP can still use the supported engines. |
| Primal variable values and objective | Supported | Supported | Supported | Read only when `hasSolution` is true; optimality is a separate check. |
| LP dual values / shadow prices | Returned for pure LP | Not exposed | Not exposed | Clarabel conic duals are not mapped to public row duals; the MicroLP `good_lp` adapter does not expose them. MILP duals are not returned. |

### Result states

| `SolveStatus` | Usable solution? | How to handle it |
| :--- | :--- | :--- |
| `optimal` | Yes | `isOptimal` is true; use `requireSolution()` or `valueOf()`. |
| `timeLimitExceeded` | An incumbent may be available | Check `hasSolution`; an incumbent is not proof of optimality. Some engine iteration/gap limits also map to this status. |
| `infeasible` | No | The constraints have no feasible point; revise the model. |
| `unbounded` | No | The objective can improve without bound; review bounds and constraints. |
| `numericalError` / `unknown` | No usable solution under the public result contract | Inspect the status and solver diagnostics before changing the formulation or engine. |

A completed solve can report a non-optimal status without throwing. Invalid models and unsupported engine/platform combinations raise validation errors; initialization and execution failures can still throw. `requireSolution()` throws when `hasSolution` is false.

### HiGHS: LP and integer models (C++)

**Algorithm:** simplex methods for linear programs, branch-and-bound for integer models.

**Wired as:** a row-oriented model in this package. The only engine that accepts integer/binary variables, and the only one that returns dual values (pure LP only).

**Build note:** written in C++ (`highs-sys`), so builds need a C++ toolchain. It is declared as a target-specific dependency (`cfg(not(target_arch = "wasm32"))`), which means it is compiled in automatically on Android, iOS, Windows, macOS, and Linux, and left out of web builds with no flags to pass.

**Use it for:** production planning, assignment of people to shifts, knapsack/packing choices, staff scheduling, facility location (any model with yes/no or counting decisions), and LP models where per-constraint dual values are needed.

### Clarabel: interior-point LP (Rust)

**Algorithm:** primal-dual interior-point method with homogeneous embedding.

**Wired as:** linear models in its standard conic form with a zero quadratic term. Quadratic and conic shapes remain possible later, once quadratic DTOs are added. Integer variables are rejected before FFI, and conic duals are not exposed as per-row LP duals.

**Use it for:** solving LP models with a Rust interior-point engine as an alternative to simplex, and later for quadratic and conic models once they are wired through.

### MicroLP: portable simplex (Rust via `good_lp`)

**Algorithm:** bounded-variable simplex method in pure Rust.

**Wired as:** driven through the `good_lp` modeling facade, with `anyhow` context converted to the typed `FrbSolverError` at the boundary. Declared capability is LP only.

**Build note:** with no C++ dependency it compiles anywhere Rust compiles, including `wasm32-unknown-unknown` for web.

**Use it for:** environments without a C++ toolchain, and web targets where HiGHS cannot be built.

---

## 🖥️ Showcase Demo

`example/` contains a Flutter application and a console tour that exercise the public API only.
Open **Engine & API demos** on the app home page to compare the available LP engines,
try automatic integer routing, observe cache reuse/invalidation, and run result/validation
guards. The same recipes run with `dart run example/example.dart patterns`.
QP/SOCP and other roadmap features are labeled as unavailable in that screen.
See [`example/README.md`](example/README.md#live-changelog-demos) for the feature map.

The academic problem catalog contains:

| # | Screen | Everyday story | Technique |
|---|---|---|---|
| 1 | Factory Production | How many units of A/B maximize profit? | LP • HiGHS |
| 2 | Budget Diet | Cheapest meals hitting calorie + protein goals | LP • HiGHS |
| 3 | Farm Planning | Best crop mix for 100 acres, pure Rust | LP • MicroLP |
| 4 | Task Assignment | Match 5 workers to 5 shifts cheapest | Binary MILP • HiGHS |
| 5 | Backpack Packing | Pick gadgets for max value within 3 kg | Binary MILP • HiGHS |
| 6 | Investment Mix | Best \$10k portfolio under a risk cap | LP • Clarabel |
| 7 | Juice Blending | Cheapest 100 L blend hitting flavor targets | LP • Clarabel |
| 8 | Delivery Network | Ship 3 factories → 4 warehouses cheapest (+ shadow prices) | LP • HiGHS |
| 9 | Project Funding | Fund at most one project per team, best return | Binary MILP • HiGHS |
| 10 | Warehouse Opening | Which depots pay off, and who serves whom? | Fixed-charge MILP • HiGHS |
| 11 | Lecture Timetabling | One slot per course, rooms fit two | Binary MILP • HiGHS |
| 12 | Staff Scheduling | Cover every shift with the fewest workers | Integer MILP • HiGHS |

```bash
dart run example/example.dart   # console tour (from root)
cd example && flutter run -d linux lib/main.dart  # app
```

> A widget smoke test (`example/test/showcase_smoke_test.dart`) builds all twelve problem screens without requiring the native bridge.

---

## ⚡ Performance Benchmarks

Seeded models, release native build, Linux x64 development machine. `wall` is the full Dart `await` round-trip; `engine` is the time reported by the solver. Everything below is reproduced by `test/performance/`.

### 📊 Per-engine comparison (identical models, 5 seeded runs each)

| Case | HiGHS (wall / engine) | Clarabel (wall / engine) | MicroLP (wall / engine) |
| :--- | :---: | :---: | :---: |
| transport 50v/15c | p50 4 ms / ~0 ms | p50 2 ms / ~0 ms | p50 2 ms / ~0 ms |
| factory 100v/20c | p50 21 ms / 1 ms | p50 21 ms / 2 ms | p50 25 ms / 0 ms |

On small and medium linear models the three engines finish within measurement noise of each other. The wall time is spent on Dart-side compilation and bridge transfer rather than inside the solver. MicroLP matches the other two on LP while requiring no C++.

### 🔬 Scaling snapshot (HiGHS)

| Case | wall | engine |
| :--- | :---: | :---: |
| transport 200v/30c | ~5 ms | ~0 ms |
| factory 400v/60c, first solve | ~314 ms | 9 ms |
| factory 400v/60c, repeated solve (cache hit) | ~12 ms | 9 ms |
| knapsack 30 / assignment 25v/64v (MILP) | 4–7 ms | 3–7 ms |
| knapsack 80 items (MILP) | ~64 ms | not recorded |
| delivery 15x40 LP | ~23 ms | 2 ms |

### 🎛️ Latency distribution and responsiveness

- transport 50v (n=15): wall p50 2.0 ms, p95 9.8 ms. factory 100v (n=11): wall p50 15 ms, p95 20 ms.
- The compiled-request cache removes the compilation part of unchanged repeated solves (314 ms → 12 ms on the same instance over the same bridge, isolated by measurement); first solves are unaffected.
- A 400x60 solve overlaps ~38 event-loop timer ticks and 20 animation frames instead of blocking, and `solve()` startup stays under a 100 ms synchronous budget. Each statement is enforced by a test in `test/performance/ui_responsiveness_test.dart`.

---

## 🏛️ Architecture

The package is layered so that a new engine implements one trait instead of changing application code:

```text
Flutter/Dart (MathOptModel, Expr, VarGrid, SolveResult)
  → LinearExpressionCompiler → SolverRegistry check → DTOs
Rust bridge (flutter_rust_bridge, async thread pool)
  → engine::registry routes → HiGHS / Clarabel / MicroLP adapters
Native engines (C++ HiGHS • Rust Clarabel • Rust MicroLP via good_lp)
```

Key entry points: `DartMathOpt` with `MathOptConfig`, the modeling layer (`VarArray`/`VarGrid`, `Expr`, the logical helpers), and the solving layer (`SolveOptions`, `Solution`). HiGHS is a native-only dependency selected by target (not by a cargo feature); web builds get the pure-Rust engines. Generated bridge files are not public API.

---

## 🌐 Web builds

Only the C++ HiGHS engine has no web path, and it is not compiled for web at all: `rust/Cargo.toml` declares it under `[target.'cfg(not(target_arch = "wasm32"))'.dependencies]`, so a `wasm32-unknown-unknown` build simply never sees it. Clarabel and MicroLP are pure Rust and build to WASM with the prepared command:

```bash
flutter_rust_bridge_codegen build-web --rust-root rust
```

No cargo features or `--no-default-features` are involved  the target triple alone decides. On the web the registry contains Clarabel and MicroLP: `auto` sends continuous models to Clarabel, an explicit `SolverPreference.highs` request raises `ModelValidationException` before FFI (direct bridge calls receive `InvalidInput`), and integer models are rejected in Dart with a `ModelValidationException` before FFI (use a desktop or mobile build for MILP).

> Build status: the command above produces `web/pkg/` (`dart_mathopt_bg.wasm`, with no HiGHS in the build graph), and `cargo test` passes on both native and `wasm32-unknown-unknown`. Running in a browser is still pending (no browser in this environment).

---

## 🤝 Contributing

Contributions are welcome! Here's how to get started:

1.  Fork the repository.
2.  Create a new branch:
    `git checkout -b feature/YourFeature`
3.  Commit your changes:
    `git commit -m "Add amazing feature"`
4.  Push to your branch:
    `git push origin feature/YourFeature`
5.  Open a pull request.

> 💡 Please read our **[Contributing Guidelines](CONTRIBUTING.md)** and open an issue first for major feature ideas or changes.

---

## ⚖️ License

This project is dual-licensed:

1. **Open Source License**: GPL-3.0
   - Free to use, modify, and distribute under GPL terms.
   - Any distributed modified version must also be GPL-3.0.

2. **Commercial License**:
   - Required for using the library in proprietary / closed-source products.
   - Only available from the copyright holder (Mostafa Mahmoud).
   - Contact: [mostafasensei106@gmail.com]

See the [LICENSE](LICENSE) file for full details.

<p align="center">
  Made with ❤️ by <a href="https://github.com/MostafaSensei106">MostafaSensei106</a>
</p>
