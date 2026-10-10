import '../../core/exceptions.dart';
import '../../core/types.dart';
import '../../rust/api/solver_api.dart' as bridge;
import '../../rust/errors.dart' as bridge_err;
import '../../rust/models/dto_request.dart' as dto;
import '../../rust/models/dto_response.dart' as dto_resp;
import '../solving/options.dart';
import '../solving/results.dart';
import 'ast/node.dart';
import 'compiler.dart';
import 'constraints.dart';
import 'variable.dart';

/// The user-facing mathematical optimization model (fluent facade).
///
/// Responsibilities ONLY (see agents.md §9):
/// 1. Fluent API for building models.
/// 2. Sequential variable ID allocation (0, 1, 2, ...) for native speed.
/// 3. Compiling ASTs via [LinearExpressionCompiler] and crossing the FRB
///    bridge asynchronously (never blocks the UI isolate).
///
/// No complex math lives here — the compiler and the Rust engines own that.
class MathOptModel {
  final String name;

  /// Variables stored strictly in ID order for array-based native lookups.
  final List<Variable> _variables = [];
  final List<Constraint> _constraints = [];

  ExpressionNode? _objectiveNode;
  OptimizationSense _objectiveSense = OptimizationSense.minimize;

  int _nextVariableId = 0;

  MathOptModel({this.name = 'MathOpt_Model'});

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

  Variable _addVariable(
    String name,
    VariableType type,
    double? lower,
    double? upper,
  ) {
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
    return v;
  }

  // -- Constraint & objective builders --

  /// Adds a constraint (e.g. `model.add(x + y <= 5)`).
  void add(Constraint constraint) {
    _constraints.add(constraint);
  }

  /// Alias for [add] (familiar to OptModel-style APIs).
  void addConstraint(Constraint constraint) => add(constraint);

  /// Sets a minimization objective.
  void minimize(ExpressionNode expression) {
    _objectiveNode = expression;
    _objectiveSense = OptimizationSense.minimize;
  }

  /// Sets a maximization objective.
  void maximize(ExpressionNode expression) {
    _objectiveNode = expression;
    _objectiveSense = OptimizationSense.maximize;
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
    final opts = options ?? const SolveOptions();

    try {
      // 1. Compile objective.
      final objCompiler = LinearExpressionCompiler()..compile(objectiveNode);

      // 2. Map variables to DTOs (fixed-length for native speed).
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

      // 3. Compile constraints to DTOs.
      final frbConstraints = _constraints
          .map((c) {
            final cCompiler = LinearExpressionCompiler()..compile(c.expression);
            // Move the constant to the RHS:  (terms + k) (sense) rhs
            // -> terms (sense) (rhs - k).
            final adjustedRhs = c.rhs - cCompiler.constant;
            return dto.FrbConstraintDto(
              name: c.name,
              terms: [
                for (final e in cCompiler.sortedTerms)
                  dto.FrbTermDto(variableId: e.key, coefficient: e.value),
              ],
              sense: _mapConstraintSense(c.sense),
              rhs: adjustedRhs,
            );
          })
          .toList(growable: false);

      // 4. Build the full request.
      final request = dto.FrbSolveRequest(
        name: name,
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
        options: dto.FrbSolveOptionsDto(
          timeLimitSec: opts.timeLimitSec,
          enableLogging: opts.enableLogging,
          threadCount: opts.threadCount,
          solver: opts.solver.name,
        ),
      );

      // 5. CROSS THE BRIDGE (async — never blocks the UI isolate).
      final response = await bridge.executeSolve(request: request);

      // 6. Map the response back to domain objects.
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

  // -- Private mappers --

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
