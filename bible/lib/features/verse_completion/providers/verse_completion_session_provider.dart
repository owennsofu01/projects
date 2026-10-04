import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../../../core/progress/tiered_levels.dart';
import '../../../core/storage/local_cache_service.dart';
import '../data/verse_completion_content_loader.dart';
import '../data/verse_completion_levels.dart';
import '../models/verse_completion_item.dart';

enum VerseCompletionStatus { loading, playing, answered, finished }

class VerseCompletionState {
  const VerseCompletionState({
    this.status = VerseCompletionStatus.loading,
    this.items = const [],
    this.choices = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.correctCount = 0,
    this.wasCorrect = false,
    this.lastAnswer = '',
  });

  final VerseCompletionStatus status;
  final List<VerseCompletionItem> items;

  /// Index-aligned with [items]: the shuffled options shown for each verse.
  final List<List<String>> choices;
  final int currentIndex;
  final int score;
  final int correctCount;
  final bool wasCorrect;
  final String lastAnswer;

  VerseCompletionItem? get currentItem => currentIndex < items.length ? items[currentIndex] : null;
  List<String> get currentChoices => currentIndex < choices.length ? choices[currentIndex] : const [];
  int get totalCount => items.length;
  bool get isLastItem => currentIndex >= items.length - 1;

  VerseCompletionState copyWith({
    VerseCompletionStatus? status,
    List<VerseCompletionItem>? items,
    List<List<String>>? choices,
    int? currentIndex,
    int? score,
    int? correctCount,
    bool? wasCorrect,
    String? lastAnswer,
  }) => VerseCompletionState(
    status: status ?? this.status,
    items: items ?? this.items,
    choices: choices ?? this.choices,
    currentIndex: currentIndex ?? this.currentIndex,
    score: score ?? this.score,
    correctCount: correctCount ?? this.correctCount,
    wasCorrect: wasCorrect ?? this.wasCorrect,
    lastAnswer: lastAnswer ?? this.lastAnswer,
  );
}

/// One play-through of a level. [attempt] keeps a retry from reusing the
/// previous round's (finished) provider instance.
typedef VerseCompletionRound = ({int level, int attempt});

class VerseCompletionSessionNotifier extends StateNotifier<VerseCompletionState> {
  VerseCompletionSessionNotifier(this.round) : super(const VerseCompletionState()) {
    _init();
  }

  final VerseCompletionRound round;
  final _random = Random();

  static String _seenKey(int tier) => 'verse_completion:seen:tier$tier';

  Future<void> _init() async {
    final tier = TieredLevels.tierFor(round.level);
    final pool = (await VerseCompletionContentLoader.load()).where((v) => v.tier == tier).toList();

    final box = LocalCacheService.contentCacheBox;
    final seen = List<String>.from(box.get(_seenKey(tier)) as List? ?? const []);
    final items = TieredLevels.pickRound(pool, (v) => v.id, seen, _random);
    await box.put(_seenKey(tier), TieredLevels.markSeen(seen, items.map((v) => v.id)));

    if (!mounted) return;
    state = state.copyWith(
      status: VerseCompletionStatus.playing,
      items: items,
      choices: [for (final item in items) VerseCompletionLevels.choicesFor(item, round.level, _random)],
    );
  }

  void submitAnswer(String answer) {
    if (state.status != VerseCompletionStatus.playing) return;
    final item = state.currentItem;
    if (item == null) return;

    final correct = answer == item.answer;
    SoundService.play(correct ? SfxSound.correct : SfxSound.wrong);
    state = state.copyWith(
      status: VerseCompletionStatus.answered,
      wasCorrect: correct,
      lastAnswer: answer,
      score: state.score + (correct ? 10 : 0),
      correctCount: state.correctCount + (correct ? 1 : 0),
    );
  }

  void nextItem() {
    if (state.isLastItem) {
      SoundService.play(SfxSound.complete);
      state = state.copyWith(status: VerseCompletionStatus.finished);
      return;
    }
    state = state.copyWith(status: VerseCompletionStatus.playing, currentIndex: state.currentIndex + 1);
  }
}

final verseCompletionSessionProvider = StateNotifierProvider.autoDispose
    .family<VerseCompletionSessionNotifier, VerseCompletionState, VerseCompletionRound>(
      (ref, round) => VerseCompletionSessionNotifier(round),
    );
