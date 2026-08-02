import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/difficulty.dart';
import '../data/verse_completion_content_loader.dart';
import '../models/verse_completion_item.dart';

class VerseCompletionConfig {
  const VerseCompletionConfig({required this.difficulty, required this.kidMode});

  final Difficulty difficulty;
  final bool kidMode;

  @override
  bool operator ==(Object other) =>
      other is VerseCompletionConfig && other.difficulty == difficulty && other.kidMode == kidMode;

  @override
  int get hashCode => Object.hash(difficulty, kidMode);
}

enum VerseCompletionStatus { loading, playing, answered, finished }

class VerseCompletionState {
  const VerseCompletionState({
    this.status = VerseCompletionStatus.loading,
    this.items = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.correctCount = 0,
    this.wasCorrect = false,
    this.lastAnswer = '',
  });

  final VerseCompletionStatus status;
  final List<VerseCompletionItem> items;
  final int currentIndex;
  final int score;
  final int correctCount;
  final bool wasCorrect;
  final String lastAnswer;

  VerseCompletionItem? get currentItem => currentIndex < items.length ? items[currentIndex] : null;
  int get totalCount => items.length;
  bool get isLastItem => currentIndex >= items.length - 1;

  VerseCompletionState copyWith({
    VerseCompletionStatus? status,
    List<VerseCompletionItem>? items,
    int? currentIndex,
    int? score,
    int? correctCount,
    bool? wasCorrect,
    String? lastAnswer,
  }) =>
      VerseCompletionState(
        status: status ?? this.status,
        items: items ?? this.items,
        currentIndex: currentIndex ?? this.currentIndex,
        score: score ?? this.score,
        correctCount: correctCount ?? this.correctCount,
        wasCorrect: wasCorrect ?? this.wasCorrect,
        lastAnswer: lastAnswer ?? this.lastAnswer,
      );
}

bool _normalizedMatch(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

class VerseCompletionSessionNotifier extends StateNotifier<VerseCompletionState> {
  VerseCompletionSessionNotifier(this.config) : super(const VerseCompletionState()) {
    _init();
  }

  final VerseCompletionConfig config;

  Future<void> _init() async {
    final all = await VerseCompletionContentLoader.load();
    final filtered = all.where((v) => v.difficulty == config.difficulty).toList()..shuffle();
    state = state.copyWith(status: VerseCompletionStatus.playing, items: filtered);
  }

  void submitAnswer(String answer) {
    if (state.status != VerseCompletionStatus.playing) return;
    final item = state.currentItem;
    if (item == null) return;

    final correct = _normalizedMatch(answer, item.answer);
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
      state = state.copyWith(status: VerseCompletionStatus.finished);
      return;
    }
    state = state.copyWith(
      status: VerseCompletionStatus.playing,
      currentIndex: state.currentIndex + 1,
    );
  }
}

final verseCompletionSessionProvider = StateNotifierProvider.autoDispose
    .family<VerseCompletionSessionNotifier, VerseCompletionState, VerseCompletionConfig>(
  (ref, config) => VerseCompletionSessionNotifier(config),
);
