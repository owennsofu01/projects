import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../data/parable_matching_content_loader.dart';
import '../models/parable.dart';

enum ParableMatchingStatus { loading, playing, finished }

class ParableMatchingState {
  const ParableMatchingState({
    this.status = ParableMatchingStatus.loading,
    this.level,
    this.parables = const [],
    this.leftOrder = const [],
    this.rightOrder = const [],
    this.matchedIds = const {},
    this.selectedLeftId,
    this.wrongLeftId,
    this.wrongRightId,
    this.moves = 0,
  });

  final ParableMatchingStatus status;
  final ParableLevel? level;
  final List<Parable> parables;
  final List<String> leftOrder;
  final List<String> rightOrder;
  final Set<String> matchedIds;
  final String? selectedLeftId;
  final String? wrongLeftId;
  final String? wrongRightId;
  final int moves;

  int get totalCount => parables.length;

  /// Wrong pairings so far; every move is either a match or a mistake.
  int get mistakes => moves - matchedIds.length;

  /// Pairs "earned": each mistake costs one, which is what the shared star
  /// rule grades (6 pairs: perfect = 3 stars, 1 mistake = 2, 2 = 1).
  int get cleanMatches => (totalCount - mistakes).clamp(0, totalCount);

  int get score => (matchedIds.length * 10 - mistakes * 3).clamp(0, totalCount * 10);

  ParableMatchingState copyWith({
    ParableMatchingStatus? status,
    ParableLevel? level,
    List<Parable>? parables,
    List<String>? leftOrder,
    List<String>? rightOrder,
    Set<String>? matchedIds,
    String? selectedLeftId,
    bool clearSelectedLeftId = false,
    String? wrongLeftId,
    String? wrongRightId,
    bool clearWrong = false,
    int? moves,
  }) => ParableMatchingState(
    status: status ?? this.status,
    level: level ?? this.level,
    parables: parables ?? this.parables,
    leftOrder: leftOrder ?? this.leftOrder,
    rightOrder: rightOrder ?? this.rightOrder,
    matchedIds: matchedIds ?? this.matchedIds,
    selectedLeftId: clearSelectedLeftId ? null : (selectedLeftId ?? this.selectedLeftId),
    wrongLeftId: clearWrong ? null : (wrongLeftId ?? this.wrongLeftId),
    wrongRightId: clearWrong ? null : (wrongRightId ?? this.wrongRightId),
    moves: moves ?? this.moves,
  );
}

class ParableMatchingSessionNotifier extends StateNotifier<ParableMatchingState> {
  ParableMatchingSessionNotifier(this.levelNumber) : super(const ParableMatchingState()) {
    _init();
  }

  final int levelNumber;

  bool _disposed = false;

  Future<void> _init() async {
    final content = await ParableMatchingContentLoader.load();
    final level = content.levels.where((l) => l.level == levelNumber).firstOrNull;
    if (level == null) {
      state = state.copyWith(status: ParableMatchingStatus.playing);
      return;
    }
    final byId = content.byId;
    final parables = [for (final id in level.parableIds) byId[id]!];
    final leftOrder = parables.map((p) => p.id).toList()..shuffle();
    final rightOrder = parables.map((p) => p.id).toList()..shuffle();
    state = state.copyWith(
      status: ParableMatchingStatus.playing,
      level: level,
      parables: parables,
      leftOrder: leftOrder,
      rightOrder: rightOrder,
    );
  }

  void selectLeft(String id) {
    if (state.status != ParableMatchingStatus.playing) return;
    if (state.matchedIds.contains(id)) return;
    state = state.copyWith(
      selectedLeftId: state.selectedLeftId == id ? null : id,
      clearSelectedLeftId: state.selectedLeftId == id,
      clearWrong: true,
    );
  }

  void selectRight(String id) {
    if (state.status != ParableMatchingStatus.playing) return;
    if (state.matchedIds.contains(id)) return;
    final selected = state.selectedLeftId;
    if (selected == null) return;

    state = state.copyWith(moves: state.moves + 1);

    if (selected == id) {
      final matched = {...state.matchedIds, id};
      SoundService.play(SfxSound.correct);
      state = state.copyWith(matchedIds: matched, clearSelectedLeftId: true, clearWrong: true);
      if (matched.length == state.totalCount) {
        SoundService.play(SfxSound.complete);
        state = state.copyWith(status: ParableMatchingStatus.finished);
      }
    } else {
      SoundService.play(SfxSound.wrong);
      state = state.copyWith(wrongLeftId: selected, wrongRightId: id);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_disposed) return;
        state = state.copyWith(clearSelectedLeftId: true, clearWrong: true);
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final parableMatchingSessionProvider = StateNotifierProvider.autoDispose
    .family<ParableMatchingSessionNotifier, ParableMatchingState, int>(
      (ref, level) => ParableMatchingSessionNotifier(level),
    );
