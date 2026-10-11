import '../../core/exceptions.dart';
import '../../core/types.dart';
import '../../math_opt.dart';
import '../../rust/api/solver_api.dart' as bridge;
import '../../rust/errors.dart' as bridge_err;
import '../../rust/models/dto_request.dart' as dto;
import '../../rust/models/dto_response.dart' as dto_resp;
import '../solving/options.dart';
import '../solving/registry.dart';
import '../solving/results.dart';
import 'ast/node.dart';
import 'compiler.dart';
import 'constraints.dart';
import 'indexed.dart';
import 'variable.dart';

/// The user-facing mathematical optimization model (fluent facade).
///
/// Responsibilities ONLY (see agents.md 9):
/// 1. Fluent API for building models.
/// 2. Sequential variable ID allocation (0, 1, 2, ...) for native speed.
/// 3. Compiling ASTs via [LinearExpressionCompiler] and crossing the FRB
///    bridge asynchronously (never blocks the UI isolate).
///
/// No complex math lives here — the compiler and the Rust engines own that.
class MathOptModel {
  MathOptModel({this.name = 'MathOpt_Model'});
  final String name;

  /// Variables stored strictly in ID order for array-based native lookups.
  final List<Variable> _variables = [];
  final List<Constraint> _constraints = [];

  ExpressionNode? _objectiveNode;
  OptimizationSense _objectiveSense = OptimizationSense.minimize;

  int _nextVariableId = 0;

  /// Structural version, bumped on every mutation. Backs the
  /// compiled-request cache: repeated `solve()` calls without model
  /// changes reuse the cached DTOs instead of recompiling the ASTs.
  int _version = 0;

  int _compiledVersion = -1;
  List<dto.FrbVariableDto>? _cachedVariables;
  List<dto.FrbConstraintDto>? _cachedConstraints;
  dto.FrbObjectiveDto? _cachedObjective;

  bool _lastSolveWasCached = false;

  /// Whether the most recent `solve()` reused the cached compiled request
  /// (`false` when it compiled fresh, or when no solve ran yet).
  bool get lastSolveWasCached => _lastSolveWasCached;

  /// All variables in ID order (unmodifiable view).
  List<Variable> get variables => List.unmodifiable(_variables);

  /// All constraints in insertion order (unmodifiable view).
  List<Constraint> get constraints => List.unmodifiable(_constraints);

  // -- Variable factories --

  /// Creates a continuous variable with optional bounds.
  Variable continuous(String name, {double? lower, double? upper}) =>
      _addVariable(name, VariableType.continuous, lower, upper);

  /// Creates an integer variable with optional bounds.
  Variable integer(String name, {double? lower, double? upper}) =>
      _addVariable(name, VariableType.integer, lower, upper);

  /// Creates a binary (0/1) variable.
  ///
  /// Bounds default to `[0, 1]`; explicit bounds are intersected with
  /// `[0, 1]` so the engine always sees a valid binary domain.
  Variable binary(String name, {double? lower, double? upper}) {
    final lb = lower == null ? 0.0 : lower.clamp(0.0, 1.0);
    final ub = upper == null ? 1.0 : upper.clamp(0.0, 1.0);
    return _addVariable(name, VariableType.binary, lb, ub);
  }

  /// Creates an N-dimensional indexed variable collection (row-major).
  ///
  /// Names are `'${name}_i_j_...'` in row-major order. Use [VarGrid]
  /// conveniences (`continuousGrid` & co.) for the common 2-D case.
  VarArray indexed(
    String name,
    List<int> dimensions,
    VariableType type, {
    double? lower,
    double? upper,
  }) => VarArray.internal(
    name,
    dimensions,
    _indexedVars(name, dimensions, type, lower, upper),
  );

  /// Creates a 2-D grid of continuous variables with `grid[i][j]`,
  /// `grid.row(i)`, and `grid.column(j)` views.
  VarGrid continuousGrid(
    String name, {
    required int rows,
    required int cols,
    double? lower,
    double? upper,
  }) => VarGrid.internal(name, [
    rows,
    cols,
  ], _indexedVars(name, [rows, cols], VariableType.continuous, lower, upper));

  /// Creates a 2-D grid of integer variables (see [continuousGrid]).
  VarGrid integerGrid(
    String name, {
    required int rows,
    required int cols,
    double? lower,
    double? upper,
  }) => VarGrid.internal(name, [
    rows,
    cols,
  ], _indexedVars(name, [rows, cols], VariableType.integer, lower, upper));

  /// Creates a 2-D grid of binary variables (see [continuousGrid]).
  VarGrid binaryGrid(
    String name, {
    required int rows,
    required int cols,
    double? lower,
    double? upper,
  }) => VarGrid.internal(name, [
    rows,
    cols,
  ], _indexedVars(name, [rows, cols], VariableType.binary, lower, upper));

  List<Variable> _indexedVars(
    String name,
    List<int> dimensions,
    VariableType type,
    double? lower,
    double? upper,
  ) {
    if (dimensions.isEmpty) {
      throw ArgumentError('"$name": dimensions must not be empty.');
    }
    if (dimensions.any((d) => d <= 0)) {
      throw ArgumentError(
        '"$name": every dimension must be positive, got $dimensions.',
      );
    }
    Variable maker(String n) => switch (type) {
      VariableType.continuous => continuous(n, lower: lower, upper: upper),
      VariableType.integer => integer(n, lower: lower, upper: upper),
      VariableType.binary => binary(n, lower: lower, upper: upper),
    };
    final vars = <Variable>[];
    final indices = List.filled(dimensions.length, 0);
    void walk(int dim) {
      if (dim == dimensions.length) {
        vars.add(maker('${name}_${indices.join('_')}'));
        return;
      }
      for (var i = 0; i < dimensions[dim]; i++) {
        indices[dim] = i;
        walk(dim + 1);
      }
    }

    walk(0);
    return vars;
  }

  Variable _addVariable(
    String name,
    VariableType type,
    double? lower,
    double? upper,
  ) {
    if ((lower != null && lower.isNaN) || (upper != null && upper.isNaN)) {
      throw ModelValidationException('Variable "$name" has a NaN bound.');
    }
    if (lower != null && upper != null && lower > upper) {
      throw ModelValidationException(
        'Variable "$name" has lower bound $lower > upper bound $upper.',
      );
    }
    final v = Variable(
      id: _nextVariableId++,
      name: name,
      type: type,
      lowerBound: lower,
      upperBound: upper,
    );
    _variables.add(v);
    _version++;
    return v;
  }

  // -- Constraint & objective builders --

  /// Adds a constraint (e.g. `model.add(x + y <= 5)`).
  void add(Constraint constraint) {
    _constraints.add(constraint);
    _version++;
  }

  /// Adds every constraint in [constraints] (batch form of [add]).
  void addAll(Iterable<Constraint> constraints) {
    for (final c in constraints) {
      add(c);
    }
  }

  /// Alias for [add] (familiar to OptModel-style APIs).
  void addConstraint(Constraint constraint) => add(constraint);

  /// Sets a minimization objective.
  void minimize(ExpressionNode expression) {
    _objectiveNode = expression;
    _objectiveSense = OptimizationSense.minimize;
    _version++;
  }

  /// Sets a maximization objective.
  void maximize(ExpressionNode expression) {
    _objectiveNode = expression;
    _objectiveSense = OptimizationSense.maximize;
    _version++;
  }

  // -- Solve --

  /// Compiles the model and solves it via the Rust engines (async).
  ///
  /// Throws [ModelValidationException] for empty models or missing
  /// objectives, [SolverTimeoutException] on time-limit errors, and
  /// [SolverExecutionException] for any other native failure.
  Future<SolveResult> solve({SolveOptions? options}) async {
    if (_variables.isEmpty) {
      throw const ModelValidationException('Cannot solve an empty model.');
    }
    final objectiveNode = _objectiveNode;
    if (objectiveNode == null) {
      throw const ModelValidationException('Objective function is missing.');
    }
    // Merge per-call options over the global DartMathOpt config, then
    // validate engine capabilities Dart-side for a clear pre-FFI error.
    final opts = DartMathOpt.config.resolve(options);
    final hasInteger = SolverRegistry.hasIntegerVariables(
      _variables.map((v) => v.type),
    );
    SolverRegistry.resolve(
      hasInteger: hasInteger,
      // Quadratic objectives are not representable in the linear AST yet;
      // the flag is plumbed for future QP DTOs.
      hasQuadratic: false,
      preference: opts.solver,
    );

    _lastSolveWasCached = false;
    try {
      // Structural DTOs are cached across unchanged solves; only the
      // per-call options are rebuilt every time.
      final compiled = await _compileOrReuse(objectiveNode);

      final request = dto.FrbSolveRequest(
        name: name,
        variables: compiled.variables,
        constraints: compiled.constraints,
        objective: compiled.objective,
        options: dto.FrbSolveOptionsDto(
          timeLimitSec: opts.timeLimitSec,
          enableLogging: opts.enableLogging,
          threadCount: opts.threadCount,
          solver: opts.solver.name,
        ),
      );

      // 5. CROSS THE BRIDGE (async — never blocks the UI isolate).
      final response = await bridge.executeSolve(request: request);

      return _mapResponse(response);
    } on bridge_err.FrbSolverError catch (e) {
      throw switch (e) {
        bridge_err.FrbSolverError_TimeLimitExceeded(field0: final secs) =>
          SolverTimeoutException(
            Duration(microseconds: (secs * 1000000).round()),
          ),
        _ => SolverExecutionException(e.toString(), -1),
      };
    } catch (e, stackTrace) {
      if (e is MathOptException) rethrow;
      Error.throwWithStackTrace(
        SolverExecutionException('Unknown FFI execution failure: $e', 0),
        stackTrace,
      );
    }
  }

  // -- Compilation (with structural cache) --

  /// Compiled structural DTOs (everything except per-call options).
  ///
  /// DTOs are immutable, so cache hits safely share list instances across
  /// solves — the bridge only reads them.
  /// The fresh-compile path is chunked with event-loop yields (one per
  /// constraint): compiling a 400x60 LP is ~300 ms of synchronous AST
  /// traversal, and without yields that would freeze the UI isolate for
  /// ~20 frames. Each `await` costs microseconds against that budget.
  Future<
    ({
      List<dto.FrbVariableDto> variables,
      List<dto.FrbConstraintDto> constraints,
      dto.FrbObjectiveDto objective,
    })
  >
  _compileOrReuse(ExpressionNode objectiveNode) async {
    final vars = _cachedVariables;
    final cons = _cachedConstraints;
    final obj = _cachedObjective;
    if (_compiledVersion == _version &&
        vars != null &&
        cons != null &&
        obj != null) {
      _lastSolveWasCached = true;
      return (variables: vars, constraints: cons, objective: obj);
    }
    final fresh = await _compileFresh(objectiveNode);
    _cachedVariables = fresh.variables;
    _cachedConstraints = fresh.constraints;
    _cachedObjective = fresh.objective;
    _compiledVersion = _version;
    return fresh;
  }

  Future<
    ({
      List<dto.FrbVariableDto> variables,
      List<dto.FrbConstraintDto> constraints,
      dto.FrbObjectiveDto objective,
    })
  >
  _compileFresh(ExpressionNode objectiveNode) async {
    final objCompiler = LinearExpressionCompiler()..compile(objectiveNode);
    _checkFiniteTerms(
      objCompiler.sortedTerms,
      objCompiler.constant,
      'objective',
    );

    final frbVariables = _variables
        .map(
          (v) => dto.FrbVariableDto(
            id: v.id,
            name: v.name,
            varType: _mapVariableType(v.type),
            lowerBound: v.lowerBound,
            upperBound: v.upperBound,
          ),
        )
        .toList(growable: false);

    // Let timers/frames breathe before the (usually largest) phase.
    await Future<void>.delayed(Duration.zero);

    // Compile constraints to DTOs, yielding per constraint so a big
    // model never blocks the event loop for more than one row's work.
    final frbConstraints = <dto.FrbConstraintDto>[];
    var row = 0;
    for (final c in _constraints) {
      final cCompiler = LinearExpressionCompiler()..compile(c.expression);
      // Move the constant to the RHS:  (terms + k) (sense) rhs
      // -> terms (sense) (rhs - k).
      final adjustedRhs = c.rhs - cCompiler.constant;
      _checkFiniteTerms(
        cCompiler.sortedTerms,
        adjustedRhs,
        'constraint ${c.name ?? '#$row'}',
      );
      frbConstraints.add(
        dto.FrbConstraintDto(
          name: c.name,
          terms: [
            for (final e in cCompiler.sortedTerms)
              dto.FrbTermDto(variableId: e.key, coefficient: e.value),
          ],
          sense: _mapConstraintSense(c.sense),
          rhs: adjustedRhs,
        ),
      );
      row++;
      await Future<void>.delayed(Duration.zero);
    }

    return (
      variables: frbVariables,
      constraints: frbConstraints,
      objective: dto.FrbObjectiveDto(
        sense: _mapObjectiveSense(_objectiveSense),
        terms: [
          for (final e in objCompiler.sortedTerms)
            dto.FrbTermDto(variableId: e.key, coefficient: e.value),
        ],
        constant: objCompiler.constant,
      ),
    );
  }

  // -- Private mappers --

  /// Rejects NaN/infinite coefficients, constants, and right-hand sides
  /// before FFI. Infinite variable *bounds* stay legal (open bounds);
  /// non-finite math does not.
  static void _checkFiniteTerms(
    List<MapEntry<int, double>> terms,
    double rhsOrConstant,
    String where,
  ) {
    if (!rhsOrConstant.isFinite) {
      throw ModelValidationException(
        'Non-finite value ($rhsOrConstant) in $where.',
      );
    }
    for (final e in terms) {
      if (!e.value.isFinite) {
        throw ModelValidationException(
          'Non-finite coefficient (${e.value}) for variable id ${e.key} in $where.',
        );
      }
    }
  }

  SolveResult _mapResponse(dto_resp.FrbSolveResponse response) {
    final status = switch (response.status) {
      dto_resp.FrbSolveStatus.optimal => SolveStatus.optimal,
      dto_resp.FrbSolveStatus.infeasible => SolveStatus.infeasible,
      dto_resp.FrbSolveStatus.unbounded => SolveStatus.unbounded,
      dto_resp.FrbSolveStatus.timeLimitExceeded =>
        SolveStatus.timeLimitExceeded,
      dto_resp.FrbSolveStatus.numericalError => SolveStatus.numericalError,
      dto_resp.FrbSolveStatus.unknown => SolveStatus.unknown,
    };

    final values = response.variableValues;
    if (values.length != _variables.length) {
      throw SolverExecutionException(
        'Native engine returned ${values.length} values for ${_variables.length} variables.',
        -2,
      );
    }
    final variableValues = {for (final v in _variables) v: values[v.id]};

    final dualRaw = response.dualValues;
    return SolveResult(
      status: status,
      objectiveValue: response.objectiveValue,
      variableValues: variableValues,
      dualValues: dualRaw == null ? null : List.unmodifiable(dualRaw),
      statistics: SolveStatistics(
        solveTimeMs: response.statistics.solveTimeMs,
        solveTimeUs: response.statistics.solveTimeUs,
        iterations: response.statistics.iterations,
      ),
    );
  }

  static dto.FrbVariableType _mapVariableType(VariableType t) => switch (t) {
    VariableType.continuous => dto.FrbVariableType.continuous,
    VariableType.integer => dto.FrbVariableType.integer,
    VariableType.binary => dto.FrbVariableType.binary,
  };

  static dto.FrbConstraintSense _mapConstraintSense(ConstraintSense s) =>
      switch (s) {
        ConstraintSense.lessThanOrEqual =>
          dto.FrbConstraintSense.lessThanOrEqual,
        ConstraintSense.greaterThanOrEqual =>
          dto.FrbConstraintSense.greaterThanOrEqual,
        ConstraintSense.equal => dto.FrbConstraintSense.equal,
      };

  static dto.FrbOptimizationSense _mapObjectiveSense(OptimizationSense s) =>
      switch (s) {
        OptimizationSense.minimize => dto.FrbOptimizationSense.minimize,
        OptimizationSense.maximize => dto.FrbOptimizationSense.maximize,
      };
}
