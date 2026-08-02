import 'package:bible_gamehive/features/word_search/models/word_search_grid.dart';
import 'package:bible_gamehive/features/word_search/models/word_search_puzzle.dart';
import 'package:bible_gamehive/core/models/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WordSearchGrid.generate', () {
    test('places every word and fills the rest of the grid', () {
      const puzzle = WordSearchPuzzle(
        id: 'test',
        theme: 'Test',
        difficulty: Difficulty.adult,
        words: ['LIGHT', 'EARTH', 'ADAM', 'EVE'],
      );

      final grid = WordSearchGrid.generate(puzzle, size: 10, seed: 42);

      expect(grid.placements.length, puzzle.words.length);
      for (final row in grid.letters) {
        expect(row.every((cell) => cell.isNotEmpty), isTrue);
      }
      for (final placement in grid.placements) {
        expect(placement.cells.length, placement.word.length);
      }
    });
  });

  group('Difficulty.fromJson', () {
    test('parses known values and falls back to adult for unknown ones', () {
      expect(Difficulty.fromJson('kids'), Difficulty.kids);
      expect(Difficulty.fromJson('scholar'), Difficulty.scholar);
      expect(Difficulty.fromJson('nonsense'), Difficulty.adult);
    });
  });
}
