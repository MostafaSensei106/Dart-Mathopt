abstract interface class MathOptSolver {
  String get name;
  bool get supportsMilp;

  Future<SolverResult> solve({required ProblemPayload payload});
}
