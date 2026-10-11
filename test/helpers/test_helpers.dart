/// Shared helpers for the `dart_mathopt` test-suite.
///
/// Every test file calls [ensureNativeInit] once in `setUpAll`; the guard
/// makes repeated calls (across groups) safe within one test process.
library;

import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

bool _initialized = false;

/// Loads the Rust engines. Must run before any `solve()`.
Future<void> ensureNativeInit() async {
  if (_initialized) return;
  await DartMathOpt.init();
  _initialized = true;
}

/// Asserts the solver proved optimality (with a readable message).
void expectOptimal(SolveResult result, {String? reason}) {
  expect(
    result.status,
    SolveStatus.optimal,
    reason: reason ?? 'expected optimal, got ${result.status}',
  );
}

/// Absolute-tolerance double comparison (default 1e-6, looser for MIP).
void expectCloseTo(double actual, double expected, [double eps = 1e-6]) {
  expect(
    actual,
    closeTo(expected, eps),
    reason: 'expected $expected ± $eps, got $actual',
  );
}

/// Weighted sum Σ [coefs[v] * result.valueOf(v)].
double dot(SolveResult result, Map<Variable, double> coefs) {
  var sum = 0.0;
  coefs.forEach((v, c) => sum += c * result.valueOf(v));
  return sum;
}
