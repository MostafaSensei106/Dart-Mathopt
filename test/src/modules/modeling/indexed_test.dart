import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:dart_mathopt/src/modules/modeling/compiler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/benchmark_models.dart';
import 'helpers/test_helpers.dart';

/// Indexed variables: factories, names, views, aggregation, errors.
/// The e2e transport case stays native; the rest is pure Dart.
void main() {
  setUpAll(ensureNativeInit);

  group('factories and names', () {
    test('grid allocates row-major with stable names', () {
      final model = MathOptModel(name: 'Grid');
      final g = model.continuousGrid('s', rows: 2, cols: 3, lower: 0);
      expect(g.rows, 2);
      expect(g.cols, 3);
      expect(g.length, 6);
      expect(g.at([0, 0]).name, 's_0_0');
      expect(g.at([1, 2]).name, 's_1_2');
      expect(g.at([0, 0]).id, 0);
      expect(g.at([1, 2]).id, 5);
    });

    test('generic indexed supports 3-D', () {
      final model = MathOptModel(name: 'Cube');
      final a = model.indexed(
        'ship',
        [2, 3, 4],
        VariableType.continuous,
        lower: 0,
      );
      expect(a.rank, 3);
      expect(a.length, 24);
      expect(a.at([1, 2, 3]).name, 'ship_1_2_3');
      expect(a.at([0, 0, 0]).id, 0);
    });

    test('binaryGrid defaults to [0, 1]', () {
      final model = MathOptModel(name: 'Bin');
      final g = model.binaryGrid('b', rows: 2, cols: 2);
      for (final v in g) {
        expect(v.type, VariableType.binary);
        expect(v.lowerBound, 0.0);
        expect(v.upperBound, 1.0);
      }
    });

    test('non-positive or empty dimensions throw', () {
      final model = MathOptModel(name: 'Dims');
      expect(
        () => model.indexed('x', [], VariableType.continuous),
        throwsArgumentError,
      );
      expect(
        () => model.indexed('x', [2, 0], VariableType.continuous),
        throwsArgumentError,
      );
      expect(
        () => model.continuousGrid('x', rows: -1, cols: 2),
        throwsArgumentError,
      );
    });

    test('at() validates arity and ranges', () {
      final model = MathOptModel(name: 'At');
      final g = model.continuousGrid('s', rows: 2, cols: 3);
      expect(() => g.at([0]), throwsArgumentError);
      expect(() => g.at([0, 3]), throwsA(isA<RangeError>()));
      expect(() => g.row(2), throwsA(isA<RangeError>()));
      expect(() => g.column(-1), throwsA(isA<RangeError>()));
    });
  });

  group('views and aggregation', () {
    test('row/column/select agree', () {
      final model = MathOptModel(name: 'Views');
      final g = model.continuousGrid('s', rows: 2, cols: 3);
      expect(g[1].map((v) => v.name), ['s_1_0', 's_1_1', 's_1_2']);
      expect(g.row(0).map((v) => v.name), ['s_0_0', 's_0_1', 's_0_2']);
      expect(g.column(2).map((v) => v.name), ['s_0_2', 's_1_2']);
      expect(g.select({0: 1}).map((v) => v.name), g.row(1).map((v) => v.name));
    });

    test('sum covers all elements; sumsAlong aggregates per axis', () {
      final model = MathOptModel(name: 'Agg');
      final g = model.continuousGrid('s', rows: 2, cols: 3);
      model.add(g.sum <= 100);
      expect(model.constraints, hasLength(1));

      final perRow = [for (var i = 0; i < 2; i++) Expr.sumVars(g.row(i))];
      final along0 = g.sumsAlong(0);
      expect(along0, hasLength(2));
      Map<int, double> termsOf(ExpressionNode e) =>
          (LinearExpressionCompiler()..compile(e)).terms;
      expect(termsOf(along0[0]).keys, termsOf(perRow[0]).keys);
      expect(g.sumsAlong(1), hasLength(3));
      expect(() => g.sumsAlong(2), throwsArgumentError);
    });

    test('iteration is row-major', () {
      final model = MathOptModel(name: 'Order');
      final g = model.continuousGrid('s', rows: 2, cols: 2);
      expect(g.map((v) => v.name).toList(), [
        's_0_0',
        's_0_1',
        's_1_0',
        's_1_1',
      ]);
    });
  });

  group('e2e transport with grid + addAll', () {
    test('grid model matches known optimum', () async {
      const supply = [20.0, 30.0, 25.0];
      const demand = [15.0, 20.0, 18.0, 22.0];
      const cost = [
        [4.0, 6.0, 8.0, 7.0],
        [5.0, 3.0, 6.0, 9.0],
        [7.0, 8.0, 4.0, 5.0],
      ];
      final model = MathOptModel(name: 'Grid_Transport');
      final ship = model.continuousGrid('s', rows: 3, cols: 4, lower: 0);
      model.addAll([
        for (var i = 0; i < 3; i++) ship.row(i).sum <= supply[i],
        for (var j = 0; j < 4; j++) Expr.sumVars(ship.column(j)).eq(demand[j]),
      ]);
      model.minimize(
        Expr.dotLists(ship.toList(), [for (final row in cost) ...row]),
      );

      final r = await model.solve();
      expectOptimal(r);
      expectCloseTo(r.objectiveValue!, 332.0);
    });

    test('sumsAlong builds per-factory supply rows', () async {
      final model = buildTransport(5, 10, 1);
      expect(model.variables, hasLength(50));
      final r = await model.solve();
      expectOptimal(r);
    });
  });
}
