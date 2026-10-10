# dart_mathopt examples

Three ways to learn, same solvers underneath.

## A. Console tour — one main example (`example.dart`)

Runs all eight showcase problems back to back: story, live native solve,
result, timing. Start here for copy-paste code.

```sh
# one-time native build (from the package root)
cargo build --release --manifest-path rust/Cargo.toml

dart run example/example.dart   # from root
dart run example.dart           # from example/
```

## B. Showcase app — 8 everyday problems (`lib/`)

The same eight problems in one Flutter app. Each screen shows the **story**,
**difficulty** (★☆☆ → ★★★), **modeling notes**, and a **live solve** button.
The progress indicator keeps animating during every solve — proof the UI
never blocks.

```sh
cd example
flutter run -d linux lib/main.dart   # or -d macos / windows / chrome
```

| # | Screen | Everyday story | Technique |
|---|---|---|---|
| 1 | Factory Production | How many units of A/B maximize profit? | LP • HiGHS ★☆☆ |
| 2 | Budget Diet | Cheapest meals hitting calorie + protein goals | LP • HiGHS ★☆☆ |
| 3 | Task Assignment | Match 5 workers to 5 shifts cheapest | Binary MILP • HiGHS ★★☆ |
| 4 | Backpack Packing | Pick gadgets for max value within 3 kg | Binary MILP • HiGHS ★★☆ |
| 5 | Investment Mix | Best \$10k portfolio under a risk cap | LP • Clarabel ★★☆ |
| 6 | Delivery Network | Ship 3 factories → 4 warehouses cheapest (+ shadow prices) | LP • HiGHS ★★☆ |
| 7 | Warehouse Opening | Which depots pay off, and who serves whom? | Fixed-charge MILP • HiGHS ★★★ |
| 8 | Staff Scheduling | Cover every shift with the fewest workers | Integer MILP • HiGHS ★★★ |

Both entry points share one interface (`DemoProblem` in `lib/problems/`:
story + difficulty + notes + `createModel()` + `describeResult()`), so the
app and the console tour can never drift apart.

## C. Scaling benchmarks (`benchmark/`)

How fast are answers as models grow? The harness reports **user-perceived
latency** (full Dart `await` round-trip) plus engine-only time and iterations:

```sh
cargo build --release --manifest-path rust/Cargo.toml
dart run example/benchmark/scaling_benchmark.dart   # from root
dart run benchmark/scaling_benchmark.dart           # from example/
```

What the numbers tell you (measured on Ryzen AI 9 HX 370, Linux x64):
- The engines are **fast**: 800-variable transport in 2 ms, 400-variable
  factory LP in 9 ms, 100-item knapsack in 20 ms.
- On big LPs, wall time ≫ engine time (factory 400v: 289 ms wall vs 9 ms
  engine). The gap is Dart-side per-solve work: AST re-compilation + DTO
  allocation + bridge crossing (~24k terms per solve here).
- Optimization opportunity (not yet implemented): **cache the compiled
  request** when the model hasn't changed between solves (parametric /
  repeated solves), and let the compiler emit column-major arrays to cut
  bridge serialization. MILP latency is structure-driven (assignment 64v ≈
  25v), so no single scaling law applies there.

<!--BENCH:START-->
| case | vars/constraints | wall/op | engine | iters |
|---|---|---|---|---|
| transport 50v/15c | 50 / 15 | 1.0 ms | 0 ms | 22 |
| transport 200v/30c | 200 / 30 | 3.0 ms | 0 ms | 41 |
| transport 800v/60c | 800 / 60 | 20.2 ms | 2 ms | 89 |
| factory 100v/20c | 100 / 20 | 13.3 ms | 2 ms | 24 |
| factory 400v/60c | 400 / 60 | 288.7 ms | 9 ms | 75 |
| knapsack 30v/1c | 30 / 1 | 4.1 ms | 3 ms | 0 |
| knapsack 100v/1c | 100 / 1 | 21.7 ms | 20 ms | 101 |
| assignment 25v/10c | 25 / 10 | 6.2 ms | 7 ms | 7 |
| assignment 64v/16c | 64 / 16 | 5.8 ms | 4 ms | 10 |
<!--BENCH:END-->

## Which example do I need?

| I want to… | Read |
|---|---|
| Run one file and see everything | `example.dart` |
| Solve my first LP | Factory Production |
| Eat cheap and healthy | Budget Diet |
| Assign people to shifts | Task Assignment |
| Model yes/no decisions | Backpack Packing |
| Invest under a risk cap | Investment Mix |
| Schedule shifts / tasks | Staff Scheduling |
| Open warehouses / design networks | Warehouse Opening, Delivery Network |
| Prove the UI won't freeze | Any app screen (tap Solve) |
| Measure latency at scale | `benchmark/` |

## Expected outputs (sanity checks)

| Problem | Expected result |
|---|---|
| Factory Production | Optimal profit \$370 (A=9, B=2) |
| Budget Diet | Cheapest day \$2.63 (bread 1.25, milk 2.5) |
| Task Assignment | Minimum cost $16 (Ali→Serve, Sara→Cook, Omar→Clean, Lina→Stock, Hadi→Host) |
| Backpack Packing | Optimal value \$1900 (Laptop + Tablet + Watch) |
| Investment Mix | \$762.50/yr (B=\$3750, C=\$6250 via Clarabel) |
| Delivery Network | Minimum cost \$332, supplies/demands exactly satisfied |
| Warehouse Opening | Minimum cost $795 (North closed; East serves S1/S2/S5, West serves S3/S4) |
| Staff Scheduling | Minimum staff 23, all 7 demands covered |
