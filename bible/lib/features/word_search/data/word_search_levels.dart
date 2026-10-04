import '../../../core/models/difficulty.dart';
import '../models/word_search_grid.dart';
import '../models/word_search_puzzle.dart';

/// Word Search levels: one puzzle per level, easiest themes first. Every 5
/// levels the grid grows and words may run in more directions — forwards
/// only, then diagonals, then backwards, then every direction.
class WordSearchLevels {
  WordSearchLevels._();

  static const gameModeId = 'word_search';

  /// One level per puzzle in word_search.json (a content test keeps these in step).
  static const levelCount = 20;

  /// Puzzles in level order: by difficulty, keeping file order within one.
  static List<WordSearchPuzzle> ordered(List<WordSearchPuzzle> puzzles) =>
      sortedByDifficulty(puzzles, (p) => p.difficulty);

  static int _band(int level) => ((level - 1) ~/ 5).clamp(0, 3);

  static int gridSizeFor(int level) => 9 + _band(level);

  static List<Cell> directionsFor(int level) =>
      WordSearchGrid.allDirections.take(const [2, 4, 6, 8][_band(level)]).toList();

  static String directionsLabel(int level) =>
      const ['Across & down', '+ diagonals', '+ backwards', 'Every direction'][_band(level)];

  /// Faster finds earn more stars: up to 20 seconds per word for 3 stars,
  /// up to 40 for 2. Finishing always earns at least 1.
  static int starsFor({required Duration elapsed, required int wordCount}) {
    final perWord = elapsed.inSeconds / (wordCount == 0 ? 1 : wordCount);
    if (perWord <= 20) return 3;
    if (perWord <= 40) return 2;
    return 1;
  }

  static String? nextStarHint(int stars) => switch (stars) {
    1 => 'Average 40 seconds or less per word for 2 stars.',
    2 => 'Average 20 seconds or less per word for 3 stars.',
    _ => null,
  };
}
