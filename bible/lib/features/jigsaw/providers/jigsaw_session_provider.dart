import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../data/jigsaw_content_loader.dart';
import '../models/jigsaw_scene.dart';

enum JigsawStatus { loading, playing, finished }

/// Picks the divisor pair of [pieceCount] closest to a square, biased
/// towards more rows than columns (portrait-friendly). E.g. 24 -> 6x4,
/// 48 -> 8x6.
(int rows, int cols) jigsawGridDimensions(int pieceCount) {
  var bestCols = 1;
  var bestRows = pieceCount;
  var bestDiff = pieceCount - 1;
  for (var cols = 1; cols * cols <= pieceCount; cols++) {
    if (pieceCount % cols != 0) continue;
    final rows = pieceCount ~/ cols;
    final diff = rows - cols;
    if (diff < bestDiff) {
      bestDiff = diff;
      bestCols = cols;
      bestRows = rows;
    }
  }
  return (bestRows, bestCols);
}

class JigsawState {
  const JigsawState({
    this.status = JigsawStatus.loading,
    this.scene,
    this.rows = 0,
    this.cols = 0,
    this.order = const [],
    this.selectedIndex,
    this.moves = 0,
    this.minimumMoves = 0,
  });

  final JigsawStatus status;
  final JigsawScene? scene;
  final int rows;
  final int cols;

  /// order[slot] = the piece's correct target index. Solved when
  /// order[i] == i for every slot.
  final List<int> order;
  final int? selectedIndex;
  final int moves;

  /// Fewest swaps that could have solved the starting shuffle.
  final int minimumMoves;

  JigsawState copyWith({
    JigsawStatus? status,
    JigsawScene? scene,
    int? rows,
    int? cols,
    List<int>? order,
    int? selectedIndex,
    bool clearSelectedIndex = false,
    int? moves,
    int? minimumMoves,
  }) => JigsawState(
    status: status ?? this.status,
    scene: scene ?? this.scene,
    rows: rows ?? this.rows,
    cols: cols ?? this.cols,
    order: order ?? this.order,
    selectedIndex: clearSelectedIndex ? null : (selectedIndex ?? this.selectedIndex),
    moves: moves ?? this.moves,
    minimumMoves: minimumMoves ?? this.minimumMoves,
  );
}

/// One play-through of a level. [attempt] keeps a replay from reusing the
/// previous round's (finished) provider instance.
typedef JigsawRound = ({int level, int attempt});

class JigsawSessionNotifier extends StateNotifier<JigsawState> {
  JigsawSessionNotifier(this.round) : super(const JigsawState()) {
    _init();
  }

  final JigsawRound round;

  Future<void> _init() async {
    final scenes = await JigsawContentLoader.load();
    final scene = scenes.firstWhere((s) => s.level == round.level, orElse: () => scenes.first);
    final (rows, cols) = jigsawGridDimensions(scene.pieceCount);
    final pieceCount = rows * cols;

    List<int> order;
    do {
      order = List.generate(pieceCount, (i) => i)..shuffle();
    } while (_isSolved(order));

    if (!mounted) return;
    state = state.copyWith(
      status: JigsawStatus.playing,
      scene: scene,
      rows: rows,
      cols: cols,
      order: order,
      minimumMoves: JigsawRules.minimumSwaps(order),
    );
  }

  bool _isSolved(List<int> order) {
    for (var i = 0; i < order.length; i++) {
      if (order[i] != i) return false;
    }
    return true;
  }

  void selectTile(int index) {
    if (state.status != JigsawStatus.playing) return;
    final selected = state.selectedIndex;

    if (selected == null) {
      state = state.copyWith(selectedIndex: index);
      return;
    }
    if (selected == index) {
      state = state.copyWith(clearSelectedIndex: true);
      return;
    }

    final order = [...state.order];
    final tmp = order[selected];
    order[selected] = order[index];
    order[index] = tmp;

    final solved = _isSolved(order);
    if (solved) SoundService.play(SfxSound.complete);
    state = state.copyWith(
      order: order,
      clearSelectedIndex: true,
      moves: state.moves + 1,
      status: solved ? JigsawStatus.finished : JigsawStatus.playing,
    );
  }
}

final jigsawSessionProvider = StateNotifierProvider.autoDispose.family<JigsawSessionNotifier, JigsawState, JigsawRound>(
  (ref, round) => JigsawSessionNotifier(round),
);
