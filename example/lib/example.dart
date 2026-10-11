/// Legacy console entry point: catalog tour only.
///
/// Prefer `dart run example/example.dart`, which also offers usage-pattern
/// recipes (`tour`/`patterns` args). This file stays as a thin shim so
/// existing `dart run example.dart` (from `example/`) keeps working.
library;

import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:dart_mathopt_example/tour.dart';

Future<void> main() async {
  await DartMathOpt.init();
  await runCatalogTour();
  DartMathOpt.dispose();
}
