# dart_mathopt

Mathematical optimization for Dart & Flutter: **LP/MILP via HiGHS**,
**LP/QP/SOCP via Clarabel**, bridged through Rust
([flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge)).
Solvers run on FRB's thread pool — never on the UI isolate.

## Quick start

```dart
import 'package:dart_mathopt/dart_mathopt.dart';

Future<void> main() async {
  await RustLib.init(); // once, before the first solve()

  final model = MathOptModel(name: 'demo');
  final x = model.continuous('x', lower: 0);
  final y = model.continuous('y', lower: 0);
  model.add((x + y) <= 4);          // constraint via operator overloads
  model.maximize(x + y * 2);        // objective

  final result = await model.solve();
  print(result.status);             // SolveStatus.optimal
  print(result.objectiveValue);     // 8.0
  print(result.valueOf(y));         // 4.0
}
```

Binary/integer variables, engine selection, and time limits:

```dart
final b = model.binary('b');
final result = await model.solve(
  options: const SolveOptions(
    solver: SolverPreference.clarabel, // auto (default) | highs | clarabel
    timeLimitSec: 30,
  ),
);
```