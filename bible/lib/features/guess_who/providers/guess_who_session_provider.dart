import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../data/guess_who_content_loader.dart';
import '../models/guess_who_character.dart';

enum GuessWhoStatus { loading, playing, answered, finished }

class GuessWhoState {
  const GuessWhoState({
    this.status = GuessWhoStatus.loading,
    this.level = 1,
    this.characters = const [],
    this.currentIndex = 0,
    this.revealedClueCount = 1,
    this.wasCorrect = false,
    this.lastGuessWrong = false,
    this.score = 0,
    this.correctCount = 0,
  });

  final GuessWhoStatus status;
  final int level;
  final List<GuessWhoCharacter> characters;
  final int currentIndex;
  final int revealedClueCount;
  final bool wasCorrect;
  final bool lastGuessWrong;
  final int score;
  final int correctCount;

  GuessWhoCharacter? get currentCharacter => currentIndex < characters.length ? characters[currentIndex] : null;
  int get totalCount => characters.length;
  bool get isLastCharacter => currentIndex >= characters.length - 1;
  bool get allCluesRevealed => currentCharacter == null ? false : revealedClueCount >= currentCharacter!.clues.length;

  GuessWhoState copyWith({
    GuessWhoStatus? status,
    int? level,
    List<GuessWhoCharacter>? characters,
    int? currentIndex,
    int? revealedClueCount,
    bool? wasCorrect,
    bool? lastGuessWrong,
    int? score,
    int? correctCount,
  }) => GuessWhoState(
    status: status ?? this.status,
    level: level ?? this.level,
    characters: characters ?? this.characters,
    currentIndex: currentIndex ?? this.currentIndex,
    revealedClueCount: revealedClueCount ?? this.revealedClueCount,
    wasCorrect: wasCorrect ?? this.wasCorrect,
    lastGuessWrong: lastGuessWrong ?? this.lastGuessWrong,
    score: score ?? this.score,
    correctCount: correctCount ?? this.correctCount,
  );
}

class GuessWhoSessionNotifier extends StateNotifier<GuessWhoState> {
  GuessWhoSessionNotifier(int level) : super(GuessWhoState(level: level)) {
    _init();
  }

  Future<void> _init() async {
    final all = await GuessWhoContentLoader.load();
    final filtered = all.where((c) => c.level == state.level).toList()..shuffle();
    state = state.copyWith(status: GuessWhoStatus.playing, characters: filtered);
  }

  int _pointsFor(int cluesUsed) => (50 - (cluesUsed - 1) * 10).clamp(10, 50);

  void submitGuess(String guess) {
    if (state.status != GuessWhoStatus.playing) return;
    final character = state.currentCharacter;
    if (character == null) return;

    final correct = character.matches(guess);
    if (correct) {
      SoundService.play(SfxSound.correct);
      state = state.copyWith(
        status: GuessWhoStatus.answered,
        wasCorrect: true,
        lastGuessWrong: false,
        score: state.score + _pointsFor(state.revealedClueCount),
        correctCount: state.correctCount + 1,
      );
      return;
    }

    SoundService.play(SfxSound.wrong);
    if (state.allCluesRevealed) {
      state = state.copyWith(status: GuessWhoStatus.answered, wasCorrect: false, lastGuessWrong: true);
    } else {
      state = state.copyWith(revealedClueCount: state.revealedClueCount + 1, lastGuessWrong: true);
    }
  }

  void giveUp() {
    if (state.status != GuessWhoStatus.playing) return;
    state = state.copyWith(status: GuessWhoStatus.answered, wasCorrect: false, lastGuessWrong: false);
  }

  void nextCharacter() {
    if (state.isLastCharacter) {
      SoundService.play(SfxSound.complete);
      state = state.copyWith(status: GuessWhoStatus.finished);
      return;
    }
    state = state.copyWith(
      status: GuessWhoStatus.playing,
      currentIndex: state.currentIndex + 1,
      revealedClueCount: 1,
      wasCorrect: false,
      lastGuessWrong: false,
    );
  }
}

final guessWhoSessionProvider = StateNotifierProvider.autoDispose.family<GuessWhoSessionNotifier, GuessWhoState, int>(
  (ref, level) => GuessWhoSessionNotifier(level),
);
