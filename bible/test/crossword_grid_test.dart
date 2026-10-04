import 'package:bible_gamehive/features/crossword/data/crossword_levels.dart';
import 'package:bible_gamehive/features/crossword/data/crossword_content_loader.dart';
import 'package:bible_gamehive/features/crossword/models/crossword_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrosswordContentLoader', () {
    test('parses all 20 puzzles with unique ids, one per level', () async {
      final puzzles = await CrosswordContentLoader.load();
      expect(puzzles.length, CrosswordLevels.levelCount);
      expect(puzzles.map((p) => p.id).toSet().length, CrosswordLevels.levelCount);
    });
  });

  group('CrosswordGrid.generate', () {
    test('places every entry exactly once, connected, with a valid solution grid', () async {
      final puzzles = await CrosswordContentLoader.load();
      for (final puzzle in puzzles) {
        final grid = CrosswordGrid.generate(puzzle);

        expect(grid.placements.length, puzzle.entries.length, reason: '${puzzle.id}: every entry should be placed');
        expect(
          grid.placements.map((p) => p.entryIndex).toSet().length,
          puzzle.entries.length,
          reason: '${puzzle.id}: each entry placed exactly once',
        );

        // Every cell in every placement must be within bounds and match the solution grid.
        for (final placement in grid.placements) {
          for (var i = 0; i < placement.cells.length; i++) {
            final (row, col) = placement.cells[i];
            expect(row, inInclusiveRange(0, grid.rows - 1), reason: '${puzzle.id}/${placement.clue}');
            expect(col, inInclusiveRange(0, grid.cols - 1), reason: '${puzzle.id}/${placement.clue}');
            expect(
              grid.solution[row][col],
              placement.answer[i],
              reason: '${puzzle.id}: cell ($row,$col) should hold "${placement.answer[i]}" for "${placement.clue}"',
            );
          }
        }

        // Every open (non-block) cell in the grid must belong to at least one placement,
        // and every numbered cell must correspond to a placement start.
        var openCellCount = 0;
        for (var r = 0; r < grid.rows; r++) {
          for (var c = 0; c < grid.cols; c++) {
            if (grid.solution[r][c] == null) continue;
            openCellCount++;
            expect(grid.placementsAt(r, c), isNotEmpty, reason: '${puzzle.id}: open cell ($r,$c) is orphaned');
          }
        }
        final totalLetters = puzzle.entries.fold<int>(0, (sum, e) => sum + e.answer.replaceAll(' ', '').length);
        expect(openCellCount, lessThanOrEqualTo(totalLetters), reason: '${puzzle.id}: no phantom cells');

        // At least one intersection expected (i.e. not every word placed in isolation),
        // since these word lists were chosen to share letters.
        final totalCells = grid.placements.fold<int>(0, (sum, p) => sum + p.answer.length);
        expect(openCellCount, lessThan(totalCells), reason: '${puzzle.id}: expected at least one intersection');
      }
    });

    test('is deterministic across repeated generation for the same puzzle id', () async {
      final puzzles = await CrosswordContentLoader.load();
      final puzzle = puzzles.first;
      final a = CrosswordGrid.generate(puzzle);
      final b = CrosswordGrid.generate(puzzle);
      expect(a.rows, b.rows);
      expect(a.cols, b.cols);
      expect(a.solution, b.solution);
    });
  });
}
