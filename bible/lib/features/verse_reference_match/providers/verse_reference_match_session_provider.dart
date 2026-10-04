import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../../../core/progress/tiered_levels.dart';
import '../../../core/storage/local_cache_service.dart';
import '../data/verse_reference_match_content_loader.dart';
import '../data/verse_reference_match_levels.dart';
import '../models/verse_reference_match_item.dart';

enum VerseReferenceMatchStatus { loading, playing, answered, finished }

class VerseReferenceMatchState {
  const VerseReferenceMatchState({
    this.status = VerseReferenceMatchStatus.loading,
    this.items = const [],
    this.choices = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.correctCount = 0,
    this.wasCorrect = false,
    this.selectedReference = '',
  });

  final VerseReferenceMatchStatus status;
  final List<VerseReferenceMatchItem> items;

  /// Index-aligned with [items]: the shuffled references shown for each verse.
  final List<List<String>> choices;
  final int currentIndex;
  final int score;
  final int correctCount;
  final bool wasCorrect;
  final String selectedReference;

  VerseReferenceMatchItem? get currentItem => currentIndex < items.length ? items[currentIndex] : null;
  List<String> get currentChoices => currentIndex < choices.length ? choices[currentIndex] : const [];
  int get totalCount => items.length;
  bool get isLastItem => currentIndex >= items.length - 1;

  VerseReferenceMatchState copyWith({
    VerseReferenceMatchStatus? status,
    List<VerseReferenceMatchItem>? items,
    List<List<String>>? choices,
    int? currentIndex,
    int? score,
    int? correctCount,
    bool? wasCorrect,
    String? selectedReference,
  }) => VerseReferenceMatchState(
    status: status ?? this.status,
    items: items ?? this.items,
    choices: choices ?? this.choices,
    currentIndex: currentIndex ?? this.currentIndex,
    score: score ?? this.score,
    correctCount: correctCount ?? this.correctCount,
    wasCorrect: wasCorrect ?? this.wasCorrect,
    selectedReference: selectedReference ?? this.selectedReference,
  );
}

/// One play-through of a level. [attempt] keeps a retry from reusing the
/// previous round's (finished) provider instance.
typedef VerseReferenceMatchRound = ({int level, int attempt});

class VerseReferenceMatchSessionNotifier extends StateNotifier<VerseReferenceMatchState> {
  VerseReferenceMatchSessionNotifier(this.round) : super(const VerseReferenceMatchState()) {
    _init();
  }

  final VerseReferenceMatchRound round;
  final _random = Random();

  static String _seenKey(int tier) => 'verse_reference_match:seen:tier$tier';

  Future<void> _init() async {
    final tier = TieredLevels.tierFor(round.level);
    final all = await VerseReferenceMatchContentLoader.load();
    final pool = all.where((v) => v.tier == tier).toList();

    final box = LocalCacheService.contentCacheBox;
    final seen = List<String>.from(box.get(_seenKey(tier)) as List? ?? const []);
    final items = TieredLevels.pickRound(pool, (v) => v.id, seen, _random);
    await box.put(_seenKey(tier), TieredLevels.markSeen(seen, items.map((v) => v.id)));

    if (!mounted) return;
    state = state.copyWith(
      status: VerseReferenceMatchStatus.playing,
      items: items,
      choices: [for (final item in items) VerseReferenceMatchLevels.choicesFor(item, round.level, all, _random)],
    );
  }

  void submitAnswer(String reference) {
    if (state.status != VerseReferenceMatchStatus.playing) return;
    final item = state.currentItem;
    if (item == null) return;

    final correct = reference == item.reference;
    SoundService.play(correct ? SfxSound.correct : SfxSound.wrong);
    state = state.copyWith(
      status: VerseReferenceMatchStatus.answered,
      wasCorrect: correct,
      selectedReference: reference,
      score: state.score + (correct ? 10 : 0),
      correctCount: state.correctCount + (correct ? 1 : 0),
    );
  }

  void nextItem() {
    if (state.isLastItem) {
      SoundService.play(SfxSound.complete);
      state = state.copyWith(status: VerseReferenceMatchStatus.finished);
      return;
    }
    state = state.copyWith(
      status: VerseReferenceMatchStatus.playing,
      currentIndex: state.currentIndex + 1,
      selectedReference: '',
    );
  }
}

final verseReferenceMatchSessionProvider = StateNotifierProvider.autoDispose
    .family<VerseReferenceMatchSessionNotifier, VerseReferenceMatchState, VerseReferenceMatchRound>(
      (ref, round) => VerseReferenceMatchSessionNotifier(round),
    );
