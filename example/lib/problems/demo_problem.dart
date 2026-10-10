/// Shared contract for every demo problem in the Flutter showcase app.
///
/// Each problem explains itself ([story], [difficultyReason], [modelingNotes])
/// and knows how to build its [MathOptModel] and how to turn a
/// [SolveResult] into human-readable text.
library;

import 'package:dart_mathopt/dart_mathopt.dart';

/// 1 = easy, 2 = medium, 3 = hard.
enum ProblemDifficulty { easy, medium, hard }

extension ProblemDifficultyX on ProblemDifficulty {
  String get label => switch (this) {
    ProblemDifficulty.easy => 'Easy',
    ProblemDifficulty.medium => 'Medium',
    ProblemDifficulty.hard => 'Hard',
  };

  /// Star rating shown on the problem card.
  String get stars => switch (this) {
    ProblemDifficulty.easy => '★☆☆',
    ProblemDifficulty.medium => '★★☆',
    ProblemDifficulty.hard => '★★★',
  };
}

abstract class DemoProblem {
  /// Short title, e.g. "Factory Production".
  String get title;

  /// One-line hook shown on the home card.
  String get tagline;

  /// Solver technology tag, e.g. "LP • HiGHS" or "MILP • HiGHS".
  String get technique;

  ProblemDifficulty get difficulty;

  /// The real-life story: what is happening and what we want.
  String get story;

  /// Why this difficulty rating (what makes it tricky or simple).
  String get difficultyReason;

  /// How the story maps to variables / objective / constraints.
  List<String> get modelingNotes;

  /// Builds a fresh model. Implementations keep the created variables in
  /// private fields so [describeResult] can read them back.
  MathOptModel createModel();

  /// Engine/option override for the showcase (default: automatic routing).
  SolveOptions? get preferredOptions => null;

  /// Human-readable rendering of a successful solve.
  String describeResult(SolveResult result);
}
