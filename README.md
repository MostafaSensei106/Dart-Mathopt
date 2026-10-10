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

## Project structure (strict, see `agents.md`)

```text
lib/
├── dart_mathopt.dart          # Barrel: public API only (+ RustLib.init)
└── src/
    ├── core/                  # types, exceptions, logger (no dependencies)
    ├── modules/
    │   ├── modeling/          # AST, Variable, Constraint, compiler, model
    │   └── solving/           # options, results, registry, solver interface
    └── rust/                  # FRB generated — DO NOT EDIT
rust/src/
├── api/solver_api.rs          # Sole FFI entry: execute_solve()
├── engine/                    # SolverEngine trait, router, highs/, clarabel/
├── models/                    # FRB DTOs (request/response)
└── errors.rs                  # Typed errors (no panics on engine paths)
```

Key design rules:

- Expressions are an **immutable AST** (`ExpressionNode`), compiled to sparse
  `(variableId → coefficient)` terms by `LinearExpressionCompiler`.
  Non-linear multiplication throws `ModelValidationException`.
- Variable IDs are **dense and zero-based** so native code uses array
  indexing instead of hash maps.
- Constraint constants are folded to the RHS before crossing the bridge.
- Engine code uses `try_*` APIs only — `unwrap`/`expect`/`panic!` are banned
  on solve paths (see `agents.md` §11).

## Development

```bash
flutter pub get
flutter_rust_bridge_codegen generate   # after changing rust/src/api or DTOs
dart run build_runner build --delete-conflicting-outputs  # freezed (FRB errors)
dart analyze lib test
flutter test                           # includes HiGHS/Clarabel end-to-end
```

Native binaries for Android/iOS/macOS/Windows/Linux are built by
`.github/workflows/build_rust_binaries.yml`.
