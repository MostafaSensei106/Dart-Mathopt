<h1 align="center">dart_mathopt</h1>
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
  <img src="https://img.shields.io/badge/platforms-android%20%7C%20ios%20%7C%20linux%20%7C%20macos%20%7C%20windows-blue" alt="Platforms">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-blue" alt="License: GPL-3.0"></a>
</p>

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
| **Engines** | HiGHS (LP/MILP, C++), Clarabel (LP, Rust interior-point), MicroLP (LP, pure Rust via `good_lp`) — selected with `SolverPreference`, with unsupported combinations rejected before FFI |
| **Web builds** | HiGHS is excluded from web builds by cargo feature; Clarabel and MicroLP compile to WASM with `flutter_rust_bridge_codegen build-web` |
| **Configuration** | `DartMathOpt.init(config:)` with presets (`fastLp` / `accurateMilp` / `lowMemory` / `verbose`); per-call `SolveOptions` override the global config field by field |
| **Repeated solves** | The compiled request is reused while the model is unchanged (`lastSolveWasCached`); any structural edit invalidates it |
| **Results** | `hasSolution` reports whether a usable primal exists, `isOptimal` whether optimality was proved; `requireSolution()` returns either an optimal solution or an incumbent, and throws only when there is none |
| **Responsiveness** | Solvers run on the bridge thread pool, and compilation yields to the event loop per constraint, so timers and animations continue during long solves |
| **Validation** | NaN bounds and NaN/infinite coefficients are rejected before FFI with the offending constraint or objective named; infinite bounds remain allowed |

---

## 🤔 Why Choose dart_mathopt?

> Optimization code usually ends up as index arithmetic: hand-built matrices, manual bounds, and often a separate backend service just to run a solver.

When a Dart or Flutter application needs to make a computed decision — how much to produce, who works which shift, which warehouses to open — the usual options are to reimplement solver logic by hand or to send the problem to a server. `dart_mathopt` keeps that work inside the Dart codebase: the model is written next to the application code, the computation runs locally in native engines, and engine limitations are reported before the call crosses into native code rather than after.

### 📊 The three engines compared

| | **HiGHS** | **Clarabel** | **MicroLP** |
| :--- | :--- | :--- | :--- |
| **Algorithm** | Simplex-based LP with branch-and-bound for integers (C++ core) | Primal-dual interior-point method with homogeneous embedding (Rust) | Bounded-variable simplex in pure Rust (driven through `good_lp`) |
| **Problem classes in this package** | LP and MILP | LP (linear models; quadratic DTOs are not wired yet) | LP |
| **Integer/binary variables** | Supported | Rejected before FFI | Rejected before FFI |
| **Dual values** | Returned for pure LP only | Not exposed | Not exposed |
| **Native requirements** | C++ toolchain (`highs-sys`) | None | None |
| **Web (WASM)** | Excluded from web builds | Included | Included; the `auto` fallback |
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

> **Note:** For Flutter applications, the platform build scripts compile the Rust core during the normal app build — no manual `cargo` step is needed. When working on this repository itself (`flutter test`, `dart run example/...`), build the native library once so tests can load it:
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
  dart_mathopt: ^0.0.1
```

Then fetch packages:

```bash
flutter pub get
```

> **Note:** `0.0.1` is working toward its first pub.dev release. Until then, depend on the repository directly:
> ```yaml
> dependencies:
>   dart_mathopt:
>     path: ../dart_mathopt   # or a git: reference
> ```

---

## 🚀 Basic Usage

### 1. Initialize once

Initialize the entry point once — it finds and loads the native library, so application code never deals with FFI setup.

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

Expressions start from a variable (`x * 3`, not `3 * x`, because Dart resolves `num` operators first). Every snippet in this document is executed by `test/readme_examples_test.dart`.

### 3. Integer decisions and engine choice

```dart
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

---

## 🔬 Advanced Usage

> Fragments below build on 2: `model` is a `MathOptModel`, `ship` an indexed grid.

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
await model.solve(); // cache hit — model.lastSolveWasCached == true
```

---

## 🧠 Solver Engines

One model, three backends. `SolverPreference.auto` selects HiGHS when it is part of the build (desktop and mobile) and falls back to pure-Rust MicroLP otherwise (web). Requesting an engine that is not in the build returns an `InvalidInput` error listing the available ones.

### HiGHS — LP and integer models (C++)

HiGHS solves linear programs with simplex methods and integer models with branch-and-bound. In this package it is driven through a row-oriented model, and it is the only engine that accepts integer/binary variables and the only one that returns dual values (for pure LP). It is written in C++ (`highs-sys`), so builds need a C++ toolchain — which is why web builds leave it out through the `highs` cargo feature (`default = ["highs"]`, web builds pass `--no-default-features`).

**Use it for:** production planning, assignment of people to shifts, knapsack/packing choices, staff scheduling, facility location — any model with yes/no or counting decisions — and LP models where per-constraint dual values are needed.

### Clarabel — interior-point LP (Rust)

Clarabel implements a primal-dual interior-point method with homogeneous embedding. This package feeds it linear models in its standard conic form with a zero quadratic term; quadratic and conic shapes remain possible later once quadratic DTOs are added. Integer variables are rejected before FFI, and conic duals are not exposed as per-row LP duals.

**Use it for:** solving LP models with a Rust interior-point engine as an alternative to simplex, and later for quadratic and conic models once they are wired through.

### MicroLP — portable simplex (Rust via `good_lp`)

MicroLP implements a bounded-variable simplex method in pure Rust, used here through the `good_lp` modeling facade (with `anyhow` context converted to the typed `FrbSolverError` at the boundary). Its declared capability is LP only. Its practical value is portability: with no C++ dependency it compiles anywhere Rust compiles, including `wasm32-unknown-unknown` for web, where it serves as the `auto` fallback.

**Use it for:** environments without a C++ toolchain, and web targets where HiGHS cannot be built.

---

## 🖥️ Showcase Demo

`example/` contains a Flutter application and a console tour that exercise the public API only:

| # | Screen | Everyday story | Technique |
|---|---|---|---|
| 1 | Factory Production | How many units of A/B maximize profit? | LP • HiGHS |
| 2 | Budget Diet | Cheapest meals hitting calorie + protein goals | LP • HiGHS |
| 3 | Task Assignment | Match 5 workers to 5 shifts cheapest | Binary MILP • HiGHS |
| 4 | Backpack Packing | Pick gadgets for max value within 3 kg | Binary MILP • HiGHS |
| 5 | Investment Mix | Best \$10k portfolio under a risk cap | LP • Clarabel |
| 6 | Delivery Network | Ship 3 factories → 4 warehouses cheapest (+ shadow prices) | LP • HiGHS |
| 7 | Warehouse Opening | Which depots pay off, and who serves whom? | Fixed-charge MILP • HiGHS |
| 8 | Staff Scheduling | Cover every shift with the fewest workers | Integer MILP • HiGHS |

```bash
dart run example/example.dart   # console tour (from root)
cd example && flutter run -d linux lib/main.dart  # app
```

> A widget smoke test (`example/test/showcase_smoke_test.dart`) builds all eight problem screens without requiring the native bridge.

---

## ⚡ Performance Benchmarks

Seeded models, release native build, Linux x64 development machine. `wall` is the full Dart `await` round-trip; `engine` is the time reported by the solver. Everything below is reproduced by `test/performance/`.

### 📊 Per-engine comparison (identical models, 5 seeded runs each)

| Case | HiGHS (wall / engine) | Clarabel (wall / engine) | MicroLP (wall / engine) |
| :--- | :---: | :---: | :---: |
| transport 50v/15c | p50 4 ms / ~0 ms | p50 2 ms / ~0 ms | p50 2 ms / ~0 ms |
| factory 100v/20c | p50 21 ms / 1 ms | p50 21 ms / 2 ms | p50 25 ms / 0 ms |

On small and medium linear models the three engines finish within measurement noise of each other — the wall time is spent on Dart-side compilation and bridge transfer rather than inside the solver. MicroLP matches the other two on LP while requiring no C++.

### 🔬 Scaling snapshot (HiGHS, `auto` default)

| Case | wall | engine |
| :--- | :---: | :---: |
| transport 200v/30c | ~5 ms | ~0 ms |
| factory 400v/60c, first solve | ~314 ms | 9 ms |
| factory 400v/60c, repeated solve (cache hit) | ~12 ms | 9 ms |
| knapsack 30 / assignment 25v/64v (MILP) | 4–7 ms | 3–7 ms |
| knapsack 80 items (MILP) | ~64 ms | — |
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

Key entry points: `DartMathOpt` with `MathOptConfig`, the modeling layer (`VarArray`/`VarGrid`, `Expr`, the logical helpers), and the solving layer (`SolveOptions`, `Solution`). Cargo features: `highs` (default, C++) for desktop and mobile, pure-Rust builds for web. Generated bridge files are not public API.

---

## 🌐 Web builds

Only the C++ HiGHS engine has no web path — and it is not compiled for web at all. Clarabel and MicroLP are pure Rust and build to WASM with the prepared command:

```bash
flutter_rust_bridge_codegen build-web --rust-root rust --cargo-build-args="--no-default-features"
```

`--no-default-features` drops the `highs` cargo feature, leaving Clarabel and MicroLP in the registry: `auto` falls back to MicroLP for LP, and an explicit `highs` request returns an `InvalidInput` error listing the available engines. Integer models are rejected before FFI on web because no integer-capable engine is in that build — use a desktop or mobile build for those.

> Build status: the command above produces `web/pkg/` (`dart_mathopt_bg.wasm`, with no HiGHS in the build graph), and `cargo test --no-default-features` passes 4/4. Running in a browser is still pending (no browser in this environment).

---

## 🧪 Testing

```bash
cargo build --release --manifest-path rust/Cargo.toml  # once (desktop)
flutter test                 # 117 tests, all suites
flutter test test/performance  # scaling, latency, responsiveness
cargo test --manifest-path rust/Cargo.toml  # Rust units (also --no-default-features)
cd example && flutter test test/showcase_smoke_test.dart
```

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

> 💡 New solvers: implement `SolverEngine` in Rust and register it in `engine/registry.rs`, mirror the capabilities in Dart's `SolverRegistry`, and add a `*_problems_test.dart`. Open an issue first for major ideas.

---
## ⚖️ License

This project is dual-licensed:

1. **Open Source License**: GPL-3.0
   - Free to use, modify, and distribute under GPL terms.
   - Any distributed modified version must also be GPL-3.0.

2. **Commercial License**:
   - Required for using the library in proprietary / closed-source products.
   - Only available from the copyright holder (Mostafa Mahmoud).
   - Contact: [mostafasensei106@gmail.com](mailto:mostafasensei106@gmail.com)

See the [LICENSE](LICENSE) file for full details.

<p align="center">
  Made with ❤️ by <a href="https://github.com/MostafaSensei106">MostafaSensei106</a>
</p>
