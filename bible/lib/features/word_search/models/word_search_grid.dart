import 'dart:math';

import 'word_search_puzzle.dart';

typedef Cell = (int row, int col);

class WordPlacement {
  const WordPlacement({required this.word, required this.label, required this.cells});

  /// Letters as placed in the grid (no spaces) — used to match selections.
  final String word;

  /// Original display text (may contain spaces, e.g. "LOST SHEEP").
  final String label;
  final List<Cell> cells;
}

class WordSearchGrid {
  const WordSearchGrid({required this.size, required this.letters, required this.placements});

  final int size;
  final List<List<String>> letters;
  final List<WordPlacement> placements;

  /// Directions in order of difficulty: the first 2 read forwards, the next
  /// 2 add forward diagonals, then backwards, then backwards diagonals.
  static const allDirections = <Cell>[
    (0, 1), // right
    (1, 0), // down
    (1, 1), // diagonal down-right
    (-1, 1), // diagonal up-right
    (0, -1), // left
    (-1, 0), // up
    (-1, -1), // diagonal up-left
    (1, -1), // diagonal down-left
  ];

  /// Like [generate], but retries (and finally grows the grid) until every
  /// word is placed, so no word silently goes missing.
  static WordSearchGrid generateComplete(
    WordSearchPuzzle puzzle, {
    required int size,
    List<Cell> directions = allDirections,
    int? seed,
  }) {
    final random = Random(seed);
    final longest = puzzle.words.map((w) => w.replaceAll(' ', '').length).fold(0, max);
    var gridSize = max(size, longest);
    while (true) {
      for (var attempt = 0; attempt < 40; attempt++) {
        final grid = generate(puzzle, size: gridSize, directions: directions, seed: random.nextInt(1 << 31));
        if (grid.placements.length == puzzle.words.length) return grid;
      }
      gridSize++;
    }
  }

  static WordSearchGrid generate(
    WordSearchPuzzle puzzle, {
    int size = 12,
    List<Cell> directions = allDirections,
    int? seed,
  }) {
    final random = Random(seed);
    final grid = List.generate(size, (_) => List.filled(size, ''));
    final placements = <WordPlacement>[];

    for (final rawWord in puzzle.words) {
      final word = rawWord.replaceAll(' ', '');
      if (word.length > size) continue;

      var placed = false;
      for (var attempt = 0; attempt < 60 && !placed; attempt++) {
        final direction = directions[random.nextInt(directions.length)];
        final startRow = random.nextInt(size);
        final startCol = random.nextInt(size);

        final cells = <Cell>[];
        var row = startRow;
        var col = startCol;
        var fits = true;
        for (var i = 0; i < word.length; i++) {
          if (row < 0 || row >= size || col < 0 || col >= size) {
            fits = false;
            break;
          }
          final existing = grid[row][col];
          if (existing.isNotEmpty && existing != word[i]) {
            fits = false;
            break;
          }
          cells.add((row, col));
          row += direction.$1;
          col += direction.$2;
        }
        if (!fits || cells.length != word.length) continue;

        for (var i = 0; i < cells.length; i++) {
          grid[cells[i].$1][cells[i].$2] = word[i];
        }
        placements.add(WordPlacement(word: word, label: rawWord, cells: cells));
        placed = true;
      }
    }

    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c].isEmpty) {
          grid[r][c] = alphabet[random.nextInt(alphabet.length)];
        }
      }
    }

    return WordSearchGrid(size: size, letters: grid, placements: placements);
  }
}
