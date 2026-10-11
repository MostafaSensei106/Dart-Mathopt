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
flutter run -d linux lib/main.dart   # or -d macos / windows
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

## C. Scaling benchmarks (`test/performance/` in the package root)

How fast are answers as models grow? The suite lives with the rest of the
tests and reports **user-perceived latency** (full Dart `await`
round-trip) plus engine-only time and iterations:

```sh
cargo build --release --manifest-path rust/Cargo.toml
flutter test test/performance   # from root
```

The engines are fast on the seeded shapes there (transport/factory LP,
knapsack/assignment MILP); each case logs the wall/engine split and
enforces a generous wall-clock ceiling as a regression tripwire.

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
| Measure latency at scale | `flutter test test/performance` (from root) |

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
