import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter_test/flutter_test.dart';

/// Solver registry: routing, capability negotiation, and custom backends.
/// Pure Dart — no native library needed.
void main() {
  setUp(SolverRegistry.resetToDefaults);
  tearDown(SolverRegistry.resetToDefaults);

  group('built-in routing', () {
    test('auto LP routes to highs', () {
      expect(
        SolverRegistry.route(hasInteger: false, hasQuadratic: false),
        'highs',
      );
    });

    test('auto MILP still routes to highs (integer support)', () {
      expect(
        SolverRegistry.route(hasInteger: true, hasQuadratic: false),
        'highs',
      );
    });

    test('explicit preferences are honored', () {
      expect(
        SolverRegistry.route(
          hasInteger: false,
          hasQuadratic: false,
          preference: SolverPreference.clarabel,
        ),
        'clarabel',
      );
      expect(
        SolverRegistry.route(
          hasInteger: false,
          hasQuadratic: false,
          preference: SolverPreference.microlp,
        ),
        'microlp',
      );
      expect(
        SolverRegistry.route(
          hasInteger: true,
          hasQuadratic: false,
          preference: SolverPreference.highs,
        ),
        'highs',
      );
    });

    test('registry advertises all built-in engines', () {
      expect(
        SolverRegistry.names,
        containsAll(['highs', 'clarabel', 'microlp']),
      );
    });
  });

  group('capability negotiation (pre-FFI errors)', () {
    test('MILP on Clarabel throws ModelValidationException', () {
      expect(
        () => SolverRegistry.resolve(
          hasInteger: true,
          hasQuadratic: false,
          preference: SolverPreference.clarabel,
        ),
        throwsA(isA<ModelValidationException>()),
      );
    });

    test('MILP on MicroLP throws ModelValidationException', () {
      expect(
        () => SolverRegistry.resolve(
          hasInteger: true,
          hasQuadratic: false,
          preference: SolverPreference.microlp,
        ),
        throwsA(isA<ModelValidationException>()),
      );
    });

    test('MILP on auto/highs resolves fine', () {
      expect(
        SolverRegistry.resolve(hasInteger: true, hasQuadratic: false).name,
        'highs',
      );
    });
  });

  group('extensibility (future solvers)', () {
    test('custom backend registers and resolves', () {
      SolverRegistry.register(
        const SolverRegistration(
          name: 'osqp',
          capabilities: SolverCapabilities(supportsQp: true),
          description: 'Test-only QP backend.',
        ),
      );
      expect(SolverRegistry.names, contains('osqp'));
      expect(
        SolverRegistry.lookup('OSQP')?.description,
        'Test-only QP backend.',
      );
      expect(SolverRegistry.unregister('osqp'), isTrue);
      expect(SolverRegistry.lookup('osqp'), isNull);
    });

    test('registering replaces an existing entry', () {
      SolverRegistry.register(
        const SolverRegistration(
          name: 'highs',
          capabilities: SolverCapabilities(),
          description: 'LP-only stub.',
        ),
      );
      // The stub no longer supports MILP → negotiation must fail.
      expect(
        () => SolverRegistry.resolve(
          hasInteger: true,
          hasQuadratic: false,
          preference: SolverPreference.highs,
        ),
        throwsA(isA<ModelValidationException>()),
      );
    });
  });
}
