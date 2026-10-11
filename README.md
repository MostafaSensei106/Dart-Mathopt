<h1 align="center">dart_mathopt</h1>
<p align="center">
  <img src="https://socialify.git.ci/MostafaSensei106/dart_mathopt/image?custom_language=Rust&font=KoHo&language=1&logo=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F138288138%3Fv%3D4&name=1&owner=1&pattern=Floating+Cogs&theme=Light" alt="Banner">
</p>

<p align="center">
  <strong>Mathematical optimization for Dart &amp; Flutter, powered by Rust and native solver engines.</strong><br>
  Go beyond hand-built matrices. Model with <i>readable equations</i>, solve <i>LP/MILP</i> off the UI isolate, and swap <i>HiGHS, Clarabel, or pure-Rust MicroLP</i> with one enum.
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
| **Modeling** | Equations in code (`x + y <= 4`), mixed operands (`x + y`, `x * 3`), indexed variables (`continuousGrid`, N-D `indexed`), balanced `Expr.sum` / `Expr.dot` builders |
| **Choice constraints** | `exactlyOne` / `atMostOne` / `atLeastOne` over binary variables — plain constraints, same compile path |
| **Engines** | HiGHS (LP/MILP, C++), Clarabel (LP, Rust interior-point), MicroLP (LP, pure Rust via `good_lp`) — one `SolverPreference` switch with pre-FFI capability checks |
| **Web story** | The C++ HiGHS engine is feature-gated out of web builds; pure-Rust Clarabel + MicroLP compile to WASM via `flutter_rust_bridge_codegen build-web` |
| **Configuration** | `DartMathOpt.init(config:)` with presets (`fastLp` / `accurateMilp` / `lowMemory` / `verbose`); per-call `SolveOptions` always win |
| **Repeated solves** | Compiled-request cache (`lastSolveWasCached`); any structural edit invalidates — measured 314 ms → 12 ms on a 400-variable LP |
| **Safe results** | `hasSolution` (availability) vs `isOptimal` (proven quality); `requireSolution()` returns optimal or incumbent, throws only when none exists |
| **Responsiveness** | Solvers on FRB's thread pool + per-constraint event-loop yields — 38 timer ticks and 20 animation frames overlap a heavy solve |
| **Validation** | NaN bounds/coefficients rejected pre-FFI with named errors; infinite bounds stay legal; MILP on LP-only engines rejected before the bridge |

---

## 🤔 Why Choose dart_mathopt?

> Optimization code usually drowns in index arithmetic: hand-built matrices, manual bounds, and a separate backend service just to run a solver.

Most Dart developers who need real decisions — production plans, shift coverage, warehouse selection, portfolios — either reimplement simplex themselves or ship the math to a Python backend. `dart_mathopt` keeps the model next to your Flutter code: equations you can read, engines that run locally on a thread pool, and capability negotiation that rejects unsupported shapes *before* FFI instead of failing natively.

### 📊 The three engines compared

| | **HiGHS** | **Clarabel** | **MicroLP** |
| :--- | :--- | :--- | :--- |
| **Algorithm** | Simplex-based LP + branch-and-bound MILP (C++ core) | Primal-dual interior-point with homogeneous embedding (Rust) | Bounded-variable simplex, pure Rust (via `good_lp`) |
| **Problem classes here** | LP + MILP | LP (linear models today) | LP |
| **Integer/binary** | ✅ | ❌ rejected pre-FFI | ❌ rejected pre-FFI |
| **Duals (shadow prices)** | ✅ pure LP only | ❌ | ❌ |
| **Native deps** | C++ (`highs-sys`) | None (pure Rust) | None (pure Rust) |
| **Web (WASM)** | ❌ excluded from web builds | ✅ compiles to WASM | ✅ compiles to WASM, `auto` fallback |
| **Pick it when** | You need MILP or maximum LP throughput on desktop/mobile | You want a Rust IPM engine alongside simplex | No C++ toolchain available, or web target |

Details, selection policy, and per-engine numbers live in [Solver Engines](#-solver-engines) and [Benchmarks](#-performance-benchmarks).

---

## 📦 Installation

> **Tip — Don't worry about the "Rust Core"!**
> Adding **dart_mathopt** is designed to be as simple as adding any other Flutter package. While it uses native solver engines, you don't need to be a Rust expert. You install the toolchain once, and the build system compiles the engines for whatever desktop/mobile platform you target.

### 1. Prerequisites (The Rust Toolchain)

Since this library uses a high-speed bridge to connect Flutter and Rust, you need the Rust compiler installed on your development machine.

- **Windows**: Download and run [rustup-init.exe](https://rustup.rs).
- **macOS / Linux**: Run the following command in your terminal:
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```

> **Note:** For Flutter apps, the platform build scripts compile the Rust core automatically (cargokit) — no manual `cargo` step. For running the package tests from source, build once: `cargo build --release --manifest-path rust/Cargo.toml`.

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

> **Note:** `0.0.1` is under development toward its first pub.dev release; until then, depend on the repository by path or git (see below).

```yaml
dependencies:
  dart_mathopt:
    path: ../dart_mathopt   # or a git: reference
```

---

## 🚀 Basic Usage

### 1. Initialize once

Create the entry point once — it resolves and loads the native library, so you never touch FFI setup yourself.

```dart
import 'package:dart_mathopt/dart_mathopt.dart';

Future<void> main() async {
  await DartMathOpt.init(); // once, before the first solve()
  runApp(const MyApp());
}
```

### 2. Model with equations and solve

Declare variables, add constraints, set an objective, solve, and read the result safely.

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

Expressions start from a variable (`x * 3`, not `3 * x` — Dart resolves `num` operators first). Every snippet in this README is executed by `test/readme_examples_test.dart`.

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
print(r.objectiveValue); // 1900.0 (HiGHS handles the integers)
print(r.dualValues);     // null: MILP has no duals
```

---

## 🔬 Advanced Usage

> Fragments below build on §2: `model` is a `MathOptModel`, `ship` an indexed grid.

### Indexed variables, no index bookkeeping

```dart
final ship = model.continuousGrid('s', rows: 3, cols: 4, lower: 0);
ship[0][1];       // Variable s_0_1
ship.row(0).sum;  // one expression for the whole row

model.addAll([
  for (var i = 0; i < 3; i++) ship.row(i).sum <= supply[i],
  for (var j = 0; j < 4; j++) Expr.sumVars(ship.column(j)).eq(demand[j]),
]);
```

Arbitrary dimensions via `model.indexed('ship', [f, w, t], VariableType.continuous, lower: 0)`
(`at([i, j, t])`, `select({0: i})`, `sumsAlong(dim)`); integer/binary grids via `integerGrid` / `binaryGrid`.

### Choice constraints and safe results

```dart
model.add(exactlyOne(sections)); // Σ == 1 over binary variables
model.add(atMostOne(options));   // Σ <= 1
model.add(atLeastOne(backups));  // Σ >= 1

final solution = result.requireSolution(); // optimal or incumbent
if (solution.isOptimal) {
  // Proven optimal — otherwise a usable incumbent with values.
}
print(result.hasSolution); // availability, independent of quality
```

### Config presets and repeated solves

```dart
await DartMathOpt.init(config: MathOptConfig.fastLp());
// accurateMilp() | lowMemory() | verbose() | balanced (default)

await model.solve(); // compiles
await model.solve(); // cache hit — model.lastSolveWasCached == true
```

---

## 🧠 Solver Engines

One model, three backends. `SolverPreference.auto` picks HiGHS when compiled in (desktop/mobile) and falls back to pure-Rust MicroLP otherwise (web); an explicit engine that isn't in the build fails with a clear `InvalidInput` naming the available ones.

### HiGHS — the workhorse (C++)

Simplex-based LP plus branch-and-bound MILP, exposed through a row-oriented model (`RowProblem`). It is the only engine here that solves integer/binary models, and the only one returning dual values (shadow prices) on pure LPs. Cost: a C++ toolchain (`highs-sys`), which is why web builds exclude it via the `highs` cargo feature (`default = ["highs"]`; web uses `--no-default-features`).

**Use it for:** production planning, assignment, knapsack, scheduling, facility location — anything with yes/no or counting decisions, plus LP shadow-price analysis.

### Clarabel — the interior-point engine (Rust)

Primal-dual interior-point method with homogeneous embedding, natively Rust, wired here through its standard conic form `(A, b, cones)` with a zero quadratic term — i.e. linear models today; QP/SOCP shapes stay on the roadmap until quadratic DTOs land. No integer support (rejected pre-FFI), no duals exposed (conic duals don't map to per-row LP duals).

**Use it for:** pure-Rust LP solving, and as the future home of quadratic/conic models.

### MicroLP — the portable simplex (Rust via `good_lp`)

Bounded-variable simplex in pure Rust, driven through the `good_lp` modeling facade (`anyhow` context maps to the typed `FrbSolverError` boundary). LP-only by declared capability. Its value is portability: zero C++, so it compiles anywhere Rust does — including `wasm32-unknown-unknown` for web, where it is the `auto` fallback.

**Use it for:** environments without a C++ toolchain, and web targets.

---

## 🖥️ Showcase Demo

`example/` is a Flutter app plus a console tour exercising the public API only:

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

> A widget smoke test (`example/test/showcase_smoke_test.dart`) builds all eight problems with no native bridge required.

---

## ⚡ Performance Benchmarks

Seeded models, release native build, Linux x64 dev machine. `wall` = full Dart `await` round-trip; `engine` = solver-reported time. `test/performance/` reproduces every figure.

### 📊 Per-engine comparison (identical models, 5 seeded runs each)

| Case | HiGHS (wall / engine) | Clarabel (wall / engine) | MicroLP (wall / engine) |
| :--- | :---: | :---: | :---: |
| transport 50v/15c | p50 4 ms / ~0 ms | p50 2 ms / ~0 ms | p50 2 ms / ~0 ms |
| factory 100v/20c | p50 21 ms / 1 ms | p50 21 ms / 2 ms | p50 25 ms / 0 ms |

On small/medium LPs the three engines solve within noise of each other — wall time is dominated by Dart-side compilation plus bridge transfer, not the engine. MicroLP holds its own on LP while shipping zero C++.

### 🔬 Scaling snapshot (HiGHS, `auto` default)

| Case | wall | engine |
| :--- | :---: | :---: |
| transport 200v/30c | ~5 ms | ~0 ms |
| factory 400v/60c, first solve | ~314 ms | 9 ms |
| factory 400v/60c, repeated solve (cache hit) | ~12 ms | 9 ms |
| knapsack 30 / assignment 25v/64v (MILP) | 4–7 ms | 3–7 ms |
| knapsack 80 items (MILP) | ~64 ms | — |
| delivery 15x40 LP | ~23 ms | 2 ms |

### 🎛️ Latency distribution & responsiveness

- transport 50v (n=15): wall p50 2.0 ms, p95 9.8 ms. factory 100v (n=11): wall p50 15 ms, p95 20 ms.
- The compiled-request cache removes the compilation part on unchanged repeated solves (314 ms → 12 ms on the same instance — isolated, same bridge); it does not speed up first solves.
- A 400x60 solve overlaps ~38 event-loop timer ticks and 20 animation frames instead of blocking; `solve()` startup stays under a 100 ms synchronous budget (all enforced by tests).

---

## 🏛️ Architecture

The library is layered so new engines extend one trait instead of branching the app:

```text
Flutter/Dart (MathOptModel, Expr, VarGrid, SolveResult)
  → LinearExpressionCompiler → SolverRegistry check → DTOs
Rust bridge (flutter_rust_bridge, async thread pool)
  → engine::registry routes → HiGHS / Clarabel / MicroLP adapters
Native engines (C++ HiGHS • Rust Clarabel • Rust MicroLP via good_lp)
```

Key entry points: `DartMathOpt` + `MathOptConfig`, modeling (`VarArray`/`VarGrid`, `Expr`, logical helpers), solving (`SolveOptions`, `Solution`). Cargo features: `highs` (default; C++) vs pure-Rust web builds. Generated FRB files are not public API.

---

## 🌐 Web builds

Only the C++ HiGHS engine has no web path — and it is not compiled for web at all. Clarabel and MicroLP are pure Rust and build to WASM:

```bash
flutter_rust_bridge_codegen build-web --rust-root rust --cargo-build-args="--no-default-features"
```

`--no-default-features` drops the `highs` cargo feature, so the registry contains Clarabel + MicroLP only: `auto` falls back to MicroLP for LP, and an explicit `highs` request fails with `InvalidInput` naming the available engines. MILP models are rejected pre-FFI on web (no integer-capable engine in the build) — plan desktop/mobile builds for those.

> Verified here: the command above produced `web/pkg/` (`dart_mathopt_bg.wasm`, no HiGHS symbols in the build graph) and `cargo test --no-default-features` passes 4/4. A browser run is still pending (no Chrome in this environment).

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

> 💡 New solvers: implement `SolverEngine` in Rust + register in `engine/registry.rs`, mirror the capabilities in Dart's `SolverRegistry`, and add a `*_problems_test.dart`. Open an issue first for major ideas.

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
