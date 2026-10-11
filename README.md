# dart_mathopt

Dart modeling API for mathematical optimization, solved by native engines
(HiGHS, Clarabel, MicroLP) through a Rust bridge. You express variables,
an objective, and constraints in Dart; the engines compute the optimum.

This library provides the modeling layer and the engine dispatch. It does
not implement solvers itself, and it is not a general scientific or
numerical computing package: supported models are linear (LP), linear
with integer/binary variables (MILP) on HiGHS, on the engines listed
below.

## Status

Version `0.0.1`, under development, **not published on pub.dev**.

| Platform | State |
|---|---|
| Linux x64 | Tested (`flutter test`, release native build) |
| Windows / macOS | Native build is wired into the Flutter build (cargokit); no app run verified here |
| Android | Native build is wired in (incl. NDK `libc++` static linking); no device run verified here |
| iOS | Native build is wired in; no device run verified here |
| Web | Not supported (no WASM build wiring; the C++ HiGHS dependency has no web path) |

## Quick example

```dart
import 'package:dart_mathopt/dart_mathopt.dart';

Future<void> main() async {
  await DartMathOpt.init(); // once, before the first solve()

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
}
```

Expressions start from a variable or an expression (`x * 3`, not `3 * x`
— Dart resolves `num` operators first). The full form is covered by
`test/readme_examples_test.dart`.

## Capabilities and limitations

| Engine | LP (continuous linear) | MILP (integer/binary) | Duals |
|---|---|---|---|
| HiGHS (`auto` default for LP/MILP) | yes | yes | yes, pure LP only |
| Clarabel | yes | no | no |
| MicroLP (pure Rust, no C++) | yes | no | no |

- Models must be linear: products of variables are rejected with
  `ModelValidationException` (at expression build or at compile time).
- Non-finite math is rejected before FFI with the culprit named
  (constraint name or `objective`): NaN bounds at creation, NaN/infinite
  coefficients, constants, and right-hand sides at compile time.
  Infinite *bounds* stay legal (open bounds, e.g. `lower:
  double.negativeInfinity`).
- Quadratic (QP) and conic (SOCP) DTOs are not wired yet; all engines
  currently receive linear models only.
- Unsupported engine/model combinations are rejected before FFI with
  `ModelValidationException` (e.g. MILP on Clarabel or MicroLP).
- No incremental solving, warm starts, or cancellation API.
- Repeated `solve()` calls on an unchanged model reuse the compiled
  request; any structural edit (variable, constraint, objective)
  invalidates the cache. Changing `SolveOptions` never reuses stale
  configuration — options are rebuilt per call.

## Installation

Depend on the repository directly until the package is published:

```yaml
dependencies:
  dart_mathopt:
    path: ../dart_mathopt   # or a git: reference
```

You need the Rust toolchain installed (rustup) because the native
engines compile from source. What builds them depends on the consumer:

- **Flutter app** (`flutter run` / `flutter build`): the platform build
  scripts compile the Rust core automatically (cargokit). No manual
  `cargo` step.
- **Repository development** (`flutter test`, `dart run example/...`):
  build the library once so tests can load it:
  ```bash
  cargo build --release --manifest-path rust/Cargo.toml
  ```

## LP example: production planning

```dart
final model = MathOptModel(name: 'Production_Plan');
final a = model.continuous('A', lower: 0);
final b = model.continuous('B', lower: 0);
model.maximize(a * 30 + b * 50);
model.add((a * 2 + b * 1) <= 20);
model.add((a * 1 + b * 3) <= 15);

final r = await model.solve();
print(r.objectiveValue); // 370.0 at A=9, B=2
print(r.dualValues);     // non-null: pure LP solved by HiGHS
```

## Integer example: knapsack

```dart
final model = MathOptModel(name: 'Knapsack');
const weights = [2.0, 1.5, 0.8, 0.2];
const values = [1000.0, 800.0, 400.0, 500.0];
final packed = [for (var i = 0; i < 4; i++) model.binary('p$i')];
model.maximize(Expr.dotLists(packed, values));
model.add(Expr.dotLists(packed, weights) <= 3.0);

final r = await model.solve(); // HiGHS handles the integers
print(r.objectiveValue); // 1900.0
print(r.dualValues);     // null: MILP has no duals
```

`Expr.dotLists` / `Expr.sum` / `Iterable.sum` fold balanced expression
trees (depth O(log n)) so large sums avoid deep `Add` chains; they are
equivalent to hand-written loops (`test/sums_test.dart`).

## Indexed variables

```dart
final ship = model.continuousGrid('s', rows: 3, cols: 4, lower: 0);
ship[0][1];          // Variable s_0_1
ship.row(0).sum;     // supply row as one expression
ship.column(2);      // one column
model.addAll([
  for (var i = 0; i < 3; i++) ship.row(i).sum <= supply[i],
  for (var j = 0; j < 4; j++) Expr.sumVars(ship.column(j)).eq(demand[j]),
]);
```

Arbitrary dimensions via `model.indexed('ship', [f, w, t], VariableType.continuous, lower: 0)`
(`at([i, j, t])`, `select({0: i})`, `sumsAlong(dim)`); names are stable
row-major `'name_i_j_...'`, out-of-range indices throw named errors.
Integer/binary grids: `integerGrid` / `binaryGrid`.

## Choice constraints

```dart
model.add(exactlyOne(sections)); // Σ == 1, binary variables required
model.add(atMostOne(options));   // Σ <= 1
model.add(atLeastOne(backups));  // Σ >= 1
```

These return plain constraints through the standard compile path —
no alternate pipeline — and reject empty or non-binary input with
named `ModelValidationException`s.

## Engine selection

```dart
await model.solve(
  options: const SolveOptions(
    solver: SolverPreference.highs, // auto | highs | clarabel | microlp
    timeLimitSec: 30,
  ),
);
```

`auto` picks HiGHS (the only MILP-capable engine). `microlp` is the
pure-Rust LP fallback for environments without a C++ toolchain.
A global default can be set once and is overridden per call:

```dart
await DartMathOpt.init(config: MathOptConfig.fastLp());
// balanced (default) | accurateMilp | lowMemory | verbose
```

## Results and errors

| Status | Objective | Variable values | Duals |
|---|---|---|---|
| `optimal` | set | set | pure LP on HiGHS only, else null |
| `infeasible` | null | engine-dependent (may be NaN) | null |
| `unbounded` | null | engine-dependent | null |
| `timeLimitExceeded` | may be set (incumbent) | set when available | null |
| `numericalError` / `unknown` | null | unreliable | null |

- Check `result.isOptimal` (equivalently `status == SolveStatus.optimal`)
  before trusting values.
- `valueOf(variable)` returns `double.nan` for missing entries;
  `tryValueOf(variable)` returns `null` instead.
- Availability vs quality are separate: `hasSolution` tells whether the
  engine returned a usable primal (`optimal` always; `timeLimitExceeded`
  only with all-finite values, i.e. an incumbent; anything else means
  none). `requireSolution()` returns it or throws
  `SolverExecutionException`; the returned `Solution` carries `isOptimal`
  and `status` so an incumbent is never mistaken for proven optimal.
- Time limits surface as `status == SolveStatus.timeLimitExceeded`,
  not as an exception.
- Error types are distinct without string parsing: `ModelValidationException`
  for invalid models and unsupported engine combinations (thrown before
  FFI), `SolverExecutionException` for native failures.

## Performance

Methodology: seeded models, release native build, Linux x64 dev machine.
`wall` is the full Dart `await` round-trip; `engine` is solver-reported.
`test/performance/` reproduces every figure (scaling, latency
distributions, UI responsiveness).

| Case | wall | engine |
|---|---|---|
| transport 50v/15c (n=15: p50 2.0 ms, p95 9.8 ms) | ~2–10 ms | ~0 ms |
| factory 100v/20c (n=11: p50 15 ms, p95 20 ms) | ~15–20 ms | 1–2 ms |
| factory 400v/60c, first solve | ~314 ms | 9 ms |
| factory 400v/60c, repeated solve (cache hit) | ~12 ms | 9 ms |
| knapsack 30 / assignment 25v/64v (MILP) | 4–7 ms | 3–7 ms |

Reading: on large LPs the first solve is dominated by Dart-side
compilation plus bridge transfer, not the engine. The compiled-request
cache removes the compilation part on unchanged repeated solves
(314 ms → 12 ms on the same instance, same bridge — isolated in
`test/model_cache_test.dart`); it does not speed up first solves.
Compilation additionally yields to the event loop per constraint, so a
400x60 solve overlaps ~38 timer ticks and 20 animation frames instead
of blocking (`test/performance/ui_responsiveness_test.dart`).

## Architecture

```text
MathOptModel → LinearExpressionCompiler → SolverRegistry check
  → FrbSolveRequest → Rust bridge (async thread pool)
  → engine::registry routes → HiGHS / Clarabel / MicroLP
  → FrbSolveResponse → SolveResult
```

Developer notes: DTO layout is the FFI contract (additive changes
only); engine capabilities are declared per adapter in
`rust/src/engine/` and mirrored in `SolverRegistry`; adding an engine
means implementing `SolverEngine` in Rust (see `engine/microlp/`) —
Dart-side `SolverRegistry.register` only overrides routing metadata
for validation and cannot add an executable backend by itself.

## Testing and contributing

```bash
cargo build --release --manifest-path rust/Cargo.toml  # once
flutter test                 # 117 tests, all suites
flutter test test/performance  # scaling, latency, responsiveness
cargo test --manifest-path rust/Cargo.toml  # Rust units
cd example && flutter test test/showcase_smoke_test.dart
```

Suites: config, registry, compiler, operators, sums, indexed, logic,
solution, LP/MILP/MicroLP correctness, robustness, stress, model cache,
performance, README examples. New solvers should add a
`*_problems_test.dart`; open an issue first for major changes.

## License

No license has been selected (`LICENSE` is a placeholder), so the
default is all rights reserved. Do not treat dependency licenses as the
project's license. For engine compatibility reference only: HiGHS is
MIT, Clarabel is Apache-2.0 (verified from the vendored crate
metadata). Run `cargo license` / `cargo deny` before any release.
