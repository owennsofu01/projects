import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../data/word_search_content_loader.dart';
import '../data/word_search_levels.dart';
import '../models/word_search_grid.dart';
import '../models/word_search_puzzle.dart';

enum WordSearchStatus { loading, playing, finished }

class WordSearchState {
  const WordSearchState({
    this.status = WordSearchStatus.loading,
    this.puzzle,
    this.grid,
    this.foundWords = const {},
    this.selection = const [],
    this.startedAt,
    this.elapsed = Duration.zero,
  });

  final WordSearchStatus status;
  final WordSearchPuzzle? puzzle;
  final WordSearchGrid? grid;
  final Set<String> foundWords;
  final List<Cell> selection;
  final DateTime? startedAt;

  /// Time taken, set when the puzzle is finished.
  final Duration elapsed;

  bool get isComplete => grid != null && foundWords.length == grid!.placements.length;

  WordSearchState copyWith({
    WordSearchStatus? status,
    WordSearchPuzzle? puzzle,
    WordSearchGrid? grid,
    Set<String>? foundWords,
    List<Cell>? selection,
    DateTime? startedAt,
    Duration? elapsed,
  }) => WordSearchState(
    status: status ?? this.status,
    puzzle: puzzle ?? this.puzzle,
    grid: grid ?? this.grid,
    foundWords: foundWords ?? this.foundWords,
    selection: selection ?? this.selection,
    startedAt: startedAt ?? this.startedAt,
    elapsed: elapsed ?? this.elapsed,
  );
}

/// One play-through of a level. [attempt] keeps a replay from reusing the
/// previous round's (finished) provider instance.
typedef WordSearchRound = ({int level, int attempt});

class WordSearchSessionNotifier extends StateNotifier<WordSearchState> {
  WordSearchSessionNotifier(this.round) : super(const WordSearchState()) {
    _init();
  }

  final WordSearchRound round;

  Future<void> _init() async {
    final puzzles = WordSearchLevels.ordered(await WordSearchContentLoader.load());
    final puzzle = puzzles[(round.level - 1).clamp(0, puzzles.length - 1)];
    final grid = WordSearchGrid.generateComplete(
      puzzle,
      size: WordSearchLevels.gridSizeFor(round.level),
      directions: WordSearchLevels.directionsFor(round.level),
    );
    if (!mounted) return;
    state = state.copyWith(status: WordSearchStatus.playing, puzzle: puzzle, grid: grid, startedAt: DateTime.now());
  }

  void updateSelection(Cell start, Cell end) {
    final grid = state.grid;
    if (grid == null) return;
    final line = _lineBetween(start, end, grid.size);
    state = state.copyWith(selection: line);
  }

  void endSelection() {
    final grid = state.grid;
    if (grid == null || state.selection.length < 2) {
      state = state.copyWith(selection: []);
      return;
    }
    for (final placement in grid.placements) {
      if (_sameCells(state.selection, placement.cells) ||
          _sameCells(state.selection, placement.cells.reversed.toList())) {
        final found = {...state.foundWords, placement.word};
        state = state.copyWith(foundWords: found, selection: []);
        if (found.length == grid.placements.length) {
          SoundService.play(SfxSound.complete);
          state = state.copyWith(
            status: WordSearchStatus.finished,
            elapsed: DateTime.now().difference(state.startedAt ?? DateTime.now()),
          );
        } else {
          SoundService.play(SfxSound.correct);
        }
        return;
      }
    }
    state = state.copyWith(selection: []);
  }

  bool _sameCells(List<Cell> a, List<Cell> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<Cell> _lineBetween(Cell start, Cell end, int size) {
    final rowDiff = end.$1 - start.$1;
    final colDiff = end.$2 - start.$2;
    final rowStep = rowDiff == 0 ? 0 : (rowDiff > 0 ? 1 : -1);
    final colStep = colDiff == 0 ? 0 : (colDiff > 0 ? 1 : -1);

    final isStraight = rowDiff == 0 || colDiff == 0 || rowDiff.abs() == colDiff.abs();
    if (!isStraight) return [start];

    final steps = [rowDiff.abs(), colDiff.abs()].reduce((a, b) => a > b ? a : b);
    final cells = <Cell>[];
    for (var i = 0; i <= steps; i++) {
      final r = start.$1 + rowStep * i;
      final c = start.$2 + colStep * i;
      if (r < 0 || r >= size || c < 0 || c >= size) return [start];
      cells.add((r, c));
    }
    return cells;
  }
}

final wordSearchSessionProvider = StateNotifierProvider.autoDispose
    .family<WordSearchSessionNotifier, WordSearchState, WordSearchRound>(
      (ref, round) => WordSearchSessionNotifier(round),
    );
