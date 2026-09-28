import 'variable.dart';
import 'constraint.dart';
import 'expression.dart';
import '../solvers/solver_interface.dart';
import '../solving/solve_result.dart';

class OptModel {
  final List<Variable> _variables = [];
  final List<Constraint> _constraints = [];
  Expression? _objective;
  bool _isMaximize = false;

  Variable addVar({
    required String name,
    VariableType type = VariableType.continuous,
    double lb = 0.0,
    double? ub,
  }) {
    final v = Variable(_variables.length, name, type, lb, ub);
    _variables.add(v);
    return v;
  }

  void addConstraint(Constraint constraint) {
    _constraints.add(constraint);
  }

  void maximize(Expression expr) {
    _objective = expr;
    _isMaximize = true;
  }

  void minimize(Expression expr) {
    _objective = expr;
    _isMaximize = false;
  }

  Future<SolveResult> solve(MathOptSolver solver) async {
    final payload = ProblemPayload.compile(
      variables: _variables,
      constraints: _constraints,
      objective: _objective,
      isMaximize: _isMaximize,
    );
    return await solver.solve(payload);
  }
}
