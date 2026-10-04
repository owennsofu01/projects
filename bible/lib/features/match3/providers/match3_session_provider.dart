import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../data/match3_content_loader.dart';
import '../models/match3_level.dart';

const match3Rows = 6;
const match3Cols = 6;

/// Most tile kinds any level uses; the play screen has an icon for each.
const match3MaxKinds = 6;
const _pointsPerTile = 10;

enum Match3Status { loading, playing, finished }

class Match3State {
  const Match3State({
    this.status = Match3Status.loading,
    this.level,
    this.grid = const [],
    this.score = 0,
    this.movesLeft = 0,
    this.won = false,
    this.selectedIndex,
  });

  final Match3Status status;
  final Match3Level? level;
  final List<int> grid;
  final int score;
  final int movesLeft;

  /// Only meaningful once finished: true if the target was reached in time.
  final bool won;
  final int? selectedIndex;

  Match3State copyWith({
    Match3Status? status,
    Match3Level? level,
    List<int>? grid,
    int? score,
    int? movesLeft,
    bool? won,
    int? selectedIndex,
    bool clearSelectedIndex = false,
  }) => Match3State(
    status: status ?? this.status,
    level: level ?? this.level,
    grid: grid ?? this.grid,
    score: score ?? this.score,
    movesLeft: movesLeft ?? this.movesLeft,
    won: won ?? this.won,
    selectedIndex: clearSelectedIndex ? null : (selectedIndex ?? this.selectedIndex),
  );
}

/// One play-through of a level. [attempt] keeps a retry from reusing the
/// previous round's (finished) provider instance.
typedef Match3Round = ({String levelId, int attempt});

class Match3SessionNotifier extends StateNotifier<Match3State> {
  Match3SessionNotifier(this.round) : super(const Match3State()) {
    _init();
  }

  final Match3Round round;
  final _random = Random();
  int _kinds = 5;

  Future<void> _init() async {
    final levels = await Match3ContentLoader.load();
    final level = levels.firstWhere((l) => l.id == round.levelId);
    _kinds = level.tileKinds.clamp(3, match3MaxKinds);
    if (!mounted) return;
    state = state.copyWith(status: Match3Status.playing, level: level, grid: _playableGrid(), movesLeft: level.moves);
  }

  /// A fresh board with no ready-made matches and at least one valid swap.
  List<int> _playableGrid() {
    while (true) {
      final grid = _generateStableGrid();
      if (_hasValidMove(grid)) return grid;
    }
  }

  bool _hasValidMove(List<int> grid) {
    final g = List<int>.from(grid);
    for (var i = 0; i < g.length; i++) {
      for (final j in [if (i % match3Cols < match3Cols - 1) i + 1, if (i + match3Cols < g.length) i + match3Cols]) {
        final tmp = g[i];
        g[i] = g[j];
        g[j] = tmp;
        final found = _findMatches(g).isNotEmpty;
        g[j] = g[i];
        g[i] = tmp;
        if (found) return true;
      }
    }
    return false;
  }

  int _index(int row, int col) => row * match3Cols + col;

  List<int> _generateStableGrid() {
    final grid = List<int>.filled(match3Rows * match3Cols, 0);
    for (var row = 0; row < match3Rows; row++) {
      for (var col = 0; col < match3Cols; col++) {
        final avoid = <int>{};
        if (col >= 2 && grid[_index(row, col - 1)] == grid[_index(row, col - 2)]) {
          avoid.add(grid[_index(row, col - 1)]);
        }
        if (row >= 2 && grid[_index(row - 1, col)] == grid[_index(row - 2, col)]) {
          avoid.add(grid[_index(row - 1, col)]);
        }
        var kind = _random.nextInt(_kinds);
        while (avoid.contains(kind)) {
          kind = _random.nextInt(_kinds);
        }
        grid[_index(row, col)] = kind;
      }
    }
    return grid;
  }

  bool _adjacent(int a, int b) {
    final rowA = a ~/ match3Cols, colA = a % match3Cols;
    final rowB = b ~/ match3Cols, colB = b % match3Cols;
    return (rowA == rowB && (colA - colB).abs() == 1) || (colA == colB && (rowA - rowB).abs() == 1);
  }

  Set<int> _findMatches(List<int> grid) {
    final matched = <int>{};

    for (var row = 0; row < match3Rows; row++) {
      var runStart = 0;
      for (var col = 1; col <= match3Cols; col++) {
        final atEnd = col == match3Cols;
        final broke = atEnd || grid[_index(row, col)] != grid[_index(row, runStart)];
        if (broke) {
          if (col - runStart >= 3) {
            for (var c = runStart; c < col; c++) {
              matched.add(_index(row, c));
            }
          }
          runStart = col;
        }
      }
    }

    for (var col = 0; col < match3Cols; col++) {
      var runStart = 0;
      for (var row = 1; row <= match3Rows; row++) {
        final atEnd = row == match3Rows;
        final broke = atEnd || grid[_index(row, col)] != grid[_index(runStart, col)];
        if (broke) {
          if (row - runStart >= 3) {
            for (var r = runStart; r < row; r++) {
              matched.add(_index(r, col));
            }
          }
          runStart = row;
        }
      }
    }

    return matched;
  }

  List<int> _collapseAndRefill(List<int> grid) {
    final result = List<int>.from(grid);
    for (var col = 0; col < match3Cols; col++) {
      final remaining = <int>[];
      for (var row = 0; row < match3Rows; row++) {
        final v = result[_index(row, col)];
        if (v != -1) remaining.add(v);
      }
      final missing = match3Rows - remaining.length;
      final refilled = [for (var i = 0; i < missing; i++) _random.nextInt(_kinds), ...remaining];
      for (var row = 0; row < match3Rows; row++) {
        result[_index(row, col)] = refilled[row];
      }
    }
    return result;
  }

  void selectTile(int index) {
    if (state.status != Match3Status.playing) return;
    final selected = state.selectedIndex;

    if (selected == null) {
      state = state.copyWith(selectedIndex: index);
      return;
    }
    if (selected == index) {
      state = state.copyWith(clearSelectedIndex: true);
      return;
    }
    if (!_adjacent(selected, index)) {
      state = state.copyWith(selectedIndex: index);
      return;
    }

    var grid = List<int>.from(state.grid);
    final tmp = grid[selected];
    grid[selected] = grid[index];
    grid[index] = tmp;

    var matches = _findMatches(grid);
    if (matches.isEmpty) {
      // Invalid move — nothing to clear, leave the board untouched.
      SoundService.play(SfxSound.wrong);
      state = state.copyWith(clearSelectedIndex: true);
      return;
    }
    SoundService.play(SfxSound.correct);

    var scoreGain = 0;
    while (matches.isNotEmpty) {
      scoreGain += matches.length * _pointsPerTile;
      for (final i in matches) {
        grid[i] = -1;
      }
      grid = _collapseAndRefill(grid);
      matches = _findMatches(grid);
    }

    final newScore = state.score + scoreGain;
    final movesLeft = state.movesLeft - 1;
    final won = newScore >= (state.level?.targetScore ?? 0);
    final finished = won || movesLeft <= 0;
    if (won) SoundService.play(SfxSound.complete);
    // Reshuffle a board with no possible swap so the player is never stuck.
    if (!finished && !_hasValidMove(grid)) grid = _playableGrid();
    state = state.copyWith(
      grid: grid,
      score: newScore,
      movesLeft: movesLeft,
      won: won,
      clearSelectedIndex: true,
      status: finished ? Match3Status.finished : Match3Status.playing,
    );
  }
}

final match3SessionProvider = StateNotifierProvider.autoDispose.family<Match3SessionNotifier, Match3State, Match3Round>(
  (ref, round) => Match3SessionNotifier(round),
);
