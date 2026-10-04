import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../data/crossword_content_loader.dart';
import '../data/crossword_levels.dart';
import '../models/crossword_grid.dart';
import '../models/crossword_puzzle.dart';

enum CrosswordStatus { loading, playing, finished }

class CrosswordState {
  const CrosswordState({
    this.status = CrosswordStatus.loading,
    this.puzzle,
    this.grid,
    this.entries = const {},
    this.selectedCell,
    this.acrossSelected = true,
    this.revealed = const {},
  });

  final CrosswordStatus status;
  final CrosswordPuzzle? puzzle;
  final CrosswordGrid? grid;
  final Map<Cell, String> entries;
  final Cell? selectedCell;
  final bool acrossSelected;

  /// Cells filled in by the "reveal letter" hint; each one is a hint used.
  final Set<Cell> revealed;
  int get hintsUsed => revealed.length;

  /// The currently highlighted word, if any.
  CrosswordPlacement? get activePlacement {
    final grid = this.grid;
    final cell = selectedCell;
    if (grid == null || cell == null) return null;
    final candidates = grid.placementsAt(cell.$1, cell.$2);
    if (candidates.isEmpty) return null;
    return candidates.firstWhere((p) => p.isAcross == acrossSelected, orElse: () => candidates.first);
  }

  CrosswordState copyWith({
    CrosswordStatus? status,
    CrosswordPuzzle? puzzle,
    CrosswordGrid? grid,
    Map<Cell, String>? entries,
    Cell? selectedCell,
    bool clearSelectedCell = false,
    bool? acrossSelected,
    Set<Cell>? revealed,
  }) => CrosswordState(
    status: status ?? this.status,
    puzzle: puzzle ?? this.puzzle,
    grid: grid ?? this.grid,
    entries: entries ?? this.entries,
    selectedCell: clearSelectedCell ? null : (selectedCell ?? this.selectedCell),
    acrossSelected: acrossSelected ?? this.acrossSelected,
    revealed: revealed ?? this.revealed,
  );
}

/// One play-through of a level. [attempt] keeps a replay from reusing the
/// previous round's (finished) provider instance.
typedef CrosswordRound = ({int level, int attempt});

class CrosswordSessionNotifier extends StateNotifier<CrosswordState> {
  CrosswordSessionNotifier(this.round) : super(const CrosswordState()) {
    _init();
  }

  final CrosswordRound round;

  Future<void> _init() async {
    final puzzles = CrosswordLevels.ordered(await CrosswordContentLoader.load());
    final puzzle = puzzles[(round.level - 1).clamp(0, puzzles.length - 1)];
    final grid = CrosswordGrid.generate(puzzle);
    if (!mounted) return;
    final firstCell = grid.placements.isEmpty ? null : grid.placements.first.cells.first;
    state = state.copyWith(
      status: CrosswordStatus.playing,
      puzzle: puzzle,
      grid: grid,
      selectedCell: firstCell,
      acrossSelected: grid.placements.isEmpty ? true : grid.placements.first.isAcross,
    );
  }

  void selectCell(Cell cell) {
    final grid = state.grid;
    if (grid == null || !grid.isOpen(cell.$1, cell.$2)) return;

    if (cell == state.selectedCell) {
      final options = grid.placementsAt(cell.$1, cell.$2);
      if (options.length > 1) {
        state = state.copyWith(acrossSelected: !state.acrossSelected);
        return;
      }
    }

    final options = grid.placementsAt(cell.$1, cell.$2);
    final hasAcross = options.any((p) => p.isAcross);
    final hasDown = options.any((p) => !p.isAcross);
    var acrossSelected = state.acrossSelected;
    if (acrossSelected && !hasAcross) acrossSelected = false;
    if (!acrossSelected && !hasDown) acrossSelected = true;

    state = state.copyWith(selectedCell: cell, acrossSelected: acrossSelected);
  }

  void selectClue(CrosswordPlacement placement) {
    state = state.copyWith(selectedCell: placement.cells.first, acrossSelected: placement.isAcross);
  }

  void inputLetter(String letter) {
    final cell = state.selectedCell;
    final grid = state.grid;
    if (cell == null || grid == null || letter.isEmpty) return;

    final entries = {...state.entries, cell: letter.toUpperCase()};
    state = state.copyWith(entries: entries);
    _checkCompletion();

    final next = _nextCell(cell);
    if (next != null) {
      state = state.copyWith(selectedCell: next);
    }
  }

  void backspace() {
    final cell = state.selectedCell;
    if (cell == null) return;

    if ((state.entries[cell] ?? '').isNotEmpty) {
      final entries = {...state.entries}..remove(cell);
      state = state.copyWith(entries: entries);
      return;
    }

    final prev = _previousCell(cell);
    if (prev != null) {
      final entries = {...state.entries}..remove(prev);
      state = state.copyWith(selectedCell: prev, entries: entries);
    }
  }

  Cell? _nextCell(Cell cell) {
    final placement = state.activePlacement;
    if (placement == null) return null;
    final cells = placement.cells;
    final index = cells.indexOf(cell);
    if (index == -1 || index == cells.length - 1) return null;
    return cells[index + 1];
  }

  Cell? _previousCell(Cell cell) {
    final placement = state.activePlacement;
    if (placement == null) return null;
    final cells = placement.cells;
    final index = cells.indexOf(cell);
    if (index <= 0) return null;
    return cells[index - 1];
  }

  /// Fills in the correct letter at the selected cell, or — if that one is
  /// already right — the first wrong or empty cell of the selected word.
  void revealLetter() {
    final grid = state.grid;
    final cell = state.selectedCell;
    if (grid == null || cell == null || state.status != CrosswordStatus.playing) return;

    bool isRight(Cell c) => state.entries[c] == grid.solution[c.$1][c.$2];
    final target = !isRight(cell) ? cell : state.activePlacement?.cells.where((c) => !isRight(c)).firstOrNull;
    if (target == null) return;

    state = state.copyWith(
      entries: {...state.entries, target: grid.solution[target.$1][target.$2]!},
      revealed: {...state.revealed, target},
    );
    _checkCompletion();
  }

  void _checkCompletion() {
    final grid = state.grid;
    if (grid == null) return;
    for (var r = 0; r < grid.rows; r++) {
      for (var c = 0; c < grid.cols; c++) {
        final solutionLetter = grid.solution[r][c];
        if (solutionLetter == null) continue;
        if (state.entries[(r, c)] != solutionLetter) return;
      }
    }
    SoundService.play(SfxSound.complete);
    state = state.copyWith(status: CrosswordStatus.finished);
  }
}

final crosswordSessionProvider = StateNotifierProvider.autoDispose
    .family<CrosswordSessionNotifier, CrosswordState, CrosswordRound>((ref, round) => CrosswordSessionNotifier(round));
