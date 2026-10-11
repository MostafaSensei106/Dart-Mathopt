import 'package:meta/meta.dart';

import 'ast/node.dart';
import 'sums.dart';
import 'variable.dart';

/// N-dimensional indexed variable collection (row-major order).
///
/// Created via [MathOptModel.indexed]; 2-D shapes should prefer [VarGrid]
/// (see `continuousGrid`/`integerGrid`/`binaryGrid`).
///
/// The grid owns no copies: it is a view over the model's variables with
/// index arithmetic. Iteration and [sum] cover all elements in row-major
/// order; [select] and [sumsAlong] aggregate along dimensions.
@immutable
class VarArray extends Iterable<Variable> {
  final String name;
  final List<int> dimensions;
  final List<Variable> _vars;

  /// Assembles an indexed view over already-allocated [vars].
  ///
  /// Validates dimensions against the variable count. Internal: prefer
  /// [MathOptModel.indexed] and the grid factories.
  @internal
  VarArray.internal(this.name, List<int> dimensions, List<Variable> vars)
    : dimensions = List.unmodifiable(dimensions),
      _vars = List.unmodifiable(vars) {
    if (dimensions.isEmpty) {
      throw ArgumentError('"$name": dimensions must not be empty.');
    }
    if (dimensions.any((d) => d <= 0)) {
      throw ArgumentError(
        '"$name": every dimension must be positive, got $dimensions.',
      );
    }
    var total = 1;
    for (final d in dimensions) {
      total *= d;
    }
    if (vars.length != total) {
      throw ArgumentError(
        '"$name": $total variables required for $dimensions, got ${vars.length}.',
      );
    }
  }

  /// Total element count.
  @override
  int get length => _vars.length;

  /// Number of dimensions.
  int get rank => dimensions.length;

  /// Element at N-D [indices] (row-major). Validates arity and ranges
  /// with named errors.
  Variable at(List<int> indices) {
    if (indices.length != rank) {
      throw ArgumentError(
        'Expected $rank indices for "$name" with dimensions $dimensions, got ${indices.length}.',
      );
    }
    var flat = 0;
    for (var d = 0; d < rank; d++) {
      final idx = indices[d];
      final size = dimensions[d];
      if (idx < 0 || idx >= size) {
        throw RangeError(
          'Index $idx out of range for dimension $d (size $size) of "$name".',
        );
      }
      flat = flat * size + idx;
    }
    return _vars[flat];
  }

  /// Elements with the given dimension values fixed, in row-major order.
  ///
  /// `select({0: 2})` on a grid is row 2; `select({1: 3})` is column 3.
  List<Variable> select(Map<int, int> fixed) {
    for (final entry in fixed.entries) {
      if (entry.key < 0 || entry.key >= rank) {
        throw ArgumentError(
          'Dimension ${entry.key} out of range for "$name" with dimensions $dimensions.',
        );
      }
      final size = dimensions[entry.key];
      if (entry.value < 0 || entry.value >= size) {
        throw RangeError(
          'Index ${entry.value} out of range for dimension ${entry.key} (size $size) of "$name".',
        );
      }
    }
    final out = <Variable>[];
    final indices = List.filled(rank, 0);
    void walk(int dim) {
      if (dim == rank) {
        out.add(at(indices));
        return;
      }
      if (fixed.containsKey(dim)) {
        indices[dim] = fixed[dim]!;
        walk(dim + 1);
      } else {
        for (var i = 0; i < dimensions[dim]; i++) {
          indices[dim] = i;
          walk(dim + 1);
        }
      }
    }

    walk(0);
    return out;
  }

  /// One summed expression per index of [dim], aggregating over every
  /// other dimension (e.g. per-period totals).
  List<ExpressionNode> sumsAlong(int dim) {
    if (dim < 0 || dim >= rank) {
      throw ArgumentError(
        'Dimension $dim out of range for "$name" with dimensions $dimensions.',
      );
    }
    return [
      for (var i = 0; i < dimensions[dim]; i++) Expr.sumVars(select({dim: i})),
    ];
  }

  @override
  Iterator<Variable> get iterator => _vars.iterator;
}

/// 2-D indexed variables with row/column views.
///
/// Created via `continuousGrid`/`integerGrid`/`binaryGrid`. Rows are
/// unmodifiable views (no copies); `grid[i]` is row `i`.
@immutable
class VarGrid extends VarArray {
  /// Assembles a 2-D view. Internal: prefer the grid factories.
  @internal
  VarGrid.internal(String name, List<int> dimensions, List<Variable> vars)
    : super.internal(name, dimensions, vars) {
    if (dimensions.length != 2) {
      throw ArgumentError(
        '"$name": a grid needs exactly 2 dimensions, got $dimensions.',
      );
    }
  }

  int get rows => dimensions[0];
  int get cols => dimensions[1];

  /// Row `i` as an unmodifiable view.
  List<Variable> operator [](int i) => row(i);

  /// Row `i` as an unmodifiable view.
  List<Variable> row(int i) {
    if (i < 0 || i >= rows) {
      throw RangeError('Row $i out of range for "$name" with $rows rows.');
    }
    return List.unmodifiable(select({0: i}));
  }

  /// Column `j` as a fresh list (columns are strided, not contiguous).
  List<Variable> column(int j) {
    if (j < 0 || j >= cols) {
      throw RangeError(
        'Column $j out of range for "$name" with $cols columns.',
      );
    }
    return select({1: j});
  }
}
