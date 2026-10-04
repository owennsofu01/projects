import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../data/timeline_puzzle_content_loader.dart';
import '../models/timeline_event.dart';

enum TimelinePuzzleStatus { loading, playing, finished }

class TimelinePuzzleState {
  const TimelinePuzzleState({
    this.status = TimelinePuzzleStatus.loading,
    this.level,
    this.order = const [],
    this.correctIds = const {},
    this.checks = 0,
  });

  final TimelinePuzzleStatus status;
  final TimelineLevel? level;
  final List<TimelineEvent> order;
  final Set<String> correctIds;
  final int checks;

  int get totalCount => order.length;

  /// Solved on the first check = 3 stars, second = 2, any later = 1. The
  /// puzzle only ends once solved, so finishing always earns a star.
  int get stars => checks <= 1 ? 3 : (checks == 2 ? 2 : 1);

  int get score => (totalCount * 10 - (checks - 1) * 10).clamp(totalCount * 2, totalCount * 10);

  TimelinePuzzleState copyWith({
    TimelinePuzzleStatus? status,
    TimelineLevel? level,
    List<TimelineEvent>? order,
    Set<String>? correctIds,
    int? checks,
  }) => TimelinePuzzleState(
    status: status ?? this.status,
    level: level ?? this.level,
    order: order ?? this.order,
    correctIds: correctIds ?? this.correctIds,
    checks: checks ?? this.checks,
  );
}

class TimelinePuzzleSessionNotifier extends StateNotifier<TimelinePuzzleState> {
  TimelinePuzzleSessionNotifier(this.levelNumber) : super(const TimelinePuzzleState()) {
    _init();
  }

  final int levelNumber;

  Future<void> _init() async {
    final levels = await TimelinePuzzleContentLoader.load();
    final level = levels.where((l) => l.level == levelNumber).firstOrNull;
    final events = level?.events ?? const <TimelineEvent>[];
    var shuffled = [...events]..shuffle();
    // Never hand the player an already-solved puzzle.
    while (events.length > 1 && _isSolved(shuffled)) {
      shuffled = [...events]..shuffle();
    }
    state = state.copyWith(status: TimelinePuzzleStatus.playing, level: level, order: shuffled);
  }

  static bool _isSolved(List<TimelineEvent> order) {
    for (var i = 0; i < order.length; i++) {
      if (order[i].order != i + 1) return false;
    }
    return true;
  }

  void reorder(int oldIndex, int newIndex) {
    if (state.status != TimelinePuzzleStatus.playing) return;
    final updated = [...state.order];
    if (oldIndex < newIndex) newIndex -= 1;
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    // Any drag invalidates the last check's feedback until re-checked.
    state = state.copyWith(order: updated, correctIds: const {});
  }

  void checkOrder() {
    if (state.status != TimelinePuzzleStatus.playing) return;
    final correct = <String>{
      for (var i = 0; i < state.order.length; i++)
        if (state.order[i].order == i + 1) state.order[i].id,
    };
    final allCorrect = correct.length == state.order.length;
    SoundService.play(allCorrect ? SfxSound.complete : SfxSound.wrong);
    state = state.copyWith(
      correctIds: correct,
      checks: state.checks + 1,
      status: allCorrect ? TimelinePuzzleStatus.finished : TimelinePuzzleStatus.playing,
    );
  }
}

final timelinePuzzleSessionProvider = StateNotifierProvider.autoDispose
    .family<TimelinePuzzleSessionNotifier, TimelinePuzzleState, int>(
      (ref, level) => TimelinePuzzleSessionNotifier(level),
    );
