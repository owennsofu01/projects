import '../../../core/models/difficulty.dart';
import '../models/crossword_puzzle.dart';

/// Crossword levels: one puzzle per level, Kids themes first and Scholar
/// last. Revealing letters helps you finish but costs stars.
class CrosswordLevels {
  CrosswordLevels._();

  static const gameModeId = 'crossword';

  /// One level per puzzle in crossword.json (a content test keeps these in step).
  static const levelCount = 20;

  static List<CrosswordPuzzle> ordered(List<CrosswordPuzzle> puzzles) =>
      sortedByDifficulty(puzzles, (p) => p.difficulty);

  /// No hints earns 3 stars, up to 2 hints earns 2, more earns 1.
  static int starsFor({required int hintsUsed}) {
    if (hintsUsed == 0) return 3;
    if (hintsUsed <= 2) return 2;
    return 1;
  }

  static String? nextStarHint(int stars) => switch (stars) {
    1 => 'Use 2 or fewer letter reveals for 2 stars.',
    2 => 'Solve it without revealing any letters for 3 stars.',
    _ => null,
  };
}
