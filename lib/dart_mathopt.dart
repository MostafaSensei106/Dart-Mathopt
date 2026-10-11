/// `dart_mathopt`: mathematical optimization for Dart & Flutter.
///
/// LP/MILP via HiGHS, LP/QP/SOCP via Clarabel, bridged through Rust
/// (flutter_rust_bridge). The native engines run off the main isolate,
/// so solving never blocks the UI.
///
/// ## Quick start
///
/// ```dart
/// import 'package:dart_mathopt/dart_mathopt.dart';
///
/// Future<void> main() async {
///   await DartMathOpt.init();
///   final model = MathOptModel(name: 'demo');
///   final x = model.continuous('x', lower: 0);
///   final y = model.continuous('y', lower: 0);
///   model.add((x + y) <= 4);
///   model.maximize(x + y * 2);
///   final result = await model.solve();
///   print(result.objectiveValue); // 8.0
/// }
/// ```
library;

export 'src/config.dart';
export 'src/core/exceptions.dart';
export 'src/core/logger.dart';
export 'src/core/types.dart';
export 'src/math_opt.dart';
export 'src/modules/modeling/ast/arithmetic_nodes.dart';
export 'src/modules/modeling/ast/leaf_nodes.dart';
export 'src/modules/modeling/ast/node.dart';
export 'src/modules/modeling/constraints.dart';
export 'src/modules/modeling/indexed.dart';
export 'src/modules/modeling/logic.dart';
export 'src/modules/modeling/model.dart';
export 'src/modules/modeling/sums.dart';
export 'src/modules/modeling/variable.dart';
// Solving layer.
export 'src/modules/solving/options.dart';
export 'src/modules/solving/registry.dart';
export 'src/modules/solving/results.dart';
export 'src/modules/solving/solver_interface.dart';
