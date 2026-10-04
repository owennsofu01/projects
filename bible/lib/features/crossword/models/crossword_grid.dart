import 'dart:math';

import 'crossword_puzzle.dart';

typedef Cell = (int row, int col);

class CrosswordPlacement {
  const CrosswordPlacement({
    required this.entryIndex,
    required this.clue,
    required this.label,
    required this.answer,
    required this.isAcross,
    required this.startRow,
    required this.startCol,
    required this.number,
  });

  final int entryIndex;
  final String clue;

  /// Original display answer, may contain spaces (e.g. "RED SEA").
  final String label;

  /// Letters as placed in the grid, no spaces.
  final String answer;
  final bool isAcross;
  final int startRow;
  final int startCol;
  final int number;

  String get direction => isAcross ? 'across' : 'down';

  List<Cell> get cells =>
      List.generate(answer.length, (i) => isAcross ? (startRow, startCol + i) : (startRow + i, startCol));
}

class CrosswordGrid {
  const CrosswordGrid({
    required this.rows,
    required this.cols,
    required this.solution,
    required this.numbers,
    required this.placements,
  });

  final int rows;
  final int cols;

  /// null entries are block (unused) cells.
  final List<List<String?>> solution;
  final List<List<int?>> numbers;
  final List<CrosswordPlacement> placements;

  bool isOpen(int row, int col) => solution[row][col] != null;

  List<CrosswordPlacement> placementsAt(int row, int col) =>
      placements.where((p) => p.cells.contains((row, col))).toList();

  static int _stableSeed(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  static bool _canPlace(List<List<String?>> working, String letters, int row, int col, bool isAcross, int size) {
    final len = letters.length;
    if (isAcross) {
      if (col - 1 < 0 || col + len >= size || row < 0 || row >= size) return false;
    } else {
      if (row - 1 < 0 || row + len >= size || col < 0 || col >= size) return false;
    }

    for (var i = 0; i < len; i++) {
      final r = isAcross ? row : row + i;
      final c = isAcross ? col + i : col;
      final existing = working[r][c];
      if (existing != null) {
        if (existing != letters[i]) return false;
      } else if (isAcross) {
        if (working[r - 1][c] != null || working[r + 1][c] != null) return false;
      } else {
        if (working[r][c - 1] != null || working[r][c + 1] != null) return false;
      }
    }

    if (isAcross) {
      if (working[row][col - 1] != null || working[row][col + len] != null) return false;
    } else {
      if (working[row - 1][col] != null || working[row + len][col] != null) return false;
    }
    return true;
  }

  static void _place(List<List<String?>> working, String letters, int row, int col, bool isAcross) {
    for (var i = 0; i < letters.length; i++) {
      final r = isAcross ? row : row + i;
      final c = isAcross ? col + i : col;
      working[r][c] = letters[i];
    }
  }

  static CrosswordGrid generate(CrosswordPuzzle puzzle, {int? seed}) {
    final random = Random(seed ?? _stableSeed(puzzle.id));
    const workingSize = 45;
    const offset = 22;
    final working = List.generate(workingSize, (_) => List<String?>.filled(workingSize, null));

    final letters = puzzle.entries.map((e) => e.answer.replaceAll(' ', '')).toList();
    final order = List<int>.generate(letters.length, (i) => i)
      ..sort((a, b) => letters[b].length.compareTo(letters[a].length));

    final placed = <_PlacedWord>[];

    final firstIndex = order.first;
    final firstLetters = letters[firstIndex];
    final startRow = offset;
    final startCol = offset - (firstLetters.length ~/ 2);
    _place(working, firstLetters, startRow, startCol, true);
    placed.add(
      _PlacedWord(entryIndex: firstIndex, letters: firstLetters, isAcross: true, row: startRow, col: startCol),
    );

    var pending = order.sublist(1).toList();
    for (var pass = 0; pass < 4 && pending.isNotEmpty; pass++) {
      final stillPending = <int>[];
      for (final idx in pending) {
        final word = letters[idx];
        final candidates = <_Candidate>[];
        for (final p in placed) {
          for (var pi = 0; pi < p.letters.length; pi++) {
            final letter = p.letters[pi];
            for (var wi = 0; wi < word.length; wi++) {
              if (word[wi] != letter) continue;
              final isAcross = !p.isAcross;
              final row = p.isAcross ? p.row - wi : p.row + pi;
              final col = p.isAcross ? p.col + pi : p.col - wi;
              if (_canPlace(working, word, row, col, isAcross, workingSize)) {
                candidates.add(_Candidate(row: row, col: col, isAcross: isAcross));
              }
            }
          }
        }
        if (candidates.isNotEmpty) {
          final chosen = candidates[random.nextInt(candidates.length)];
          _place(working, word, chosen.row, chosen.col, chosen.isAcross);
          placed.add(
            _PlacedWord(entryIndex: idx, letters: word, isAcross: chosen.isAcross, row: chosen.row, col: chosen.col),
          );
        } else {
          stillPending.add(idx);
        }
      }
      pending = stillPending;
    }

    if (pending.isNotEmpty) {
      var row = placed.map((p) => p.isAcross ? p.row : p.row + p.letters.length - 1).reduce(max) + 2;
      for (final idx in pending) {
        final word = letters[idx];
        final col = offset - (word.length ~/ 2);
        _place(working, word, row, col, true);
        placed.add(_PlacedWord(entryIndex: idx, letters: word, isAcross: true, row: row, col: col));
        row += 2;
      }
    }

    var minRow = workingSize, maxRow = 0, minCol = workingSize, maxCol = 0;
    for (final p in placed) {
      final endRow = p.isAcross ? p.row : p.row + p.letters.length - 1;
      final endCol = p.isAcross ? p.col + p.letters.length - 1 : p.col;
      minRow = min(minRow, p.row);
      maxRow = max(maxRow, endRow);
      minCol = min(minCol, p.col);
      maxCol = max(maxCol, endCol);
    }
    final rows = maxRow - minRow + 1;
    final cols = maxCol - minCol + 1;

    final solution = List.generate(rows, (_) => List<String?>.filled(cols, null));
    for (final p in placed) {
      for (var i = 0; i < p.letters.length; i++) {
        final r = p.isAcross ? p.row - minRow : p.row - minRow + i;
        final c = p.isAcross ? p.col - minCol + i : p.col - minCol;
        solution[r][c] = p.letters[i];
      }
    }

    final numbers = List.generate(rows, (_) => List<int?>.filled(cols, null));
    var nextNumber = 1;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (solution[r][c] == null) continue;
        final startsAcross = (c == 0 || solution[r][c - 1] == null) && (c + 1 < cols && solution[r][c + 1] != null);
        final startsDown = (r == 0 || solution[r - 1][c] == null) && (r + 1 < rows && solution[r + 1][c] != null);
        if (startsAcross || startsDown) {
          numbers[r][c] = nextNumber++;
        }
      }
    }

    final placements = <CrosswordPlacement>[];
    for (final p in placed) {
      final r = p.row - minRow;
      final c = p.col - minCol;
      final entry = puzzle.entries[p.entryIndex];
      placements.add(
        CrosswordPlacement(
          entryIndex: p.entryIndex,
          clue: entry.clue,
          label: entry.answer,
          answer: p.letters,
          isAcross: p.isAcross,
          startRow: r,
          startCol: c,
          number: numbers[r][c]!,
        ),
      );
    }
    placements.sort((a, b) {
      final byNumber = a.number.compareTo(b.number);
      if (byNumber != 0) return byNumber;
      return a.isAcross ? -1 : 1;
    });

    return CrosswordGrid(rows: rows, cols: cols, solution: solution, numbers: numbers, placements: placements);
  }
}

class _PlacedWord {
  _PlacedWord({
    required this.entryIndex,
    required this.letters,
    required this.isAcross,
    required this.row,
    required this.col,
  });

  final int entryIndex;
  final String letters;
  final bool isAcross;
  final int row;
  final int col;
}

class _Candidate {
  _Candidate({required this.row, required this.col, required this.isAcross});

  final int row;
  final int col;
  final bool isAcross;
}
