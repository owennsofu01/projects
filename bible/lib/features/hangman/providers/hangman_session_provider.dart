import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../data/hangman_content_loader.dart';
import '../models/hangman_word.dart';

const hangmanMaxMisses = 6;

enum HangmanStatus { loading, playing, roundOver, finished }

class HangmanState {
  const HangmanState({
    this.status = HangmanStatus.loading,
    this.level = 1,
    this.words = const [],
    this.currentIndex = 0,
    this.guessedLetters = const {},
    this.misses = 0,
    this.wonRound = false,
    this.score = 0,
    this.correctCount = 0,
  });

  final HangmanStatus status;
  final int level;
  final List<HangmanWord> words;
  final int currentIndex;
  final Set<String> guessedLetters;
  final int misses;
  final bool wonRound;
  final int score;
  final int correctCount;

  HangmanWord? get currentWord => currentIndex < words.length ? words[currentIndex] : null;
  int get totalCount => words.length;
  bool get isLastWord => currentIndex >= words.length - 1;

  HangmanState copyWith({
    HangmanStatus? status,
    int? level,
    List<HangmanWord>? words,
    int? currentIndex,
    Set<String>? guessedLetters,
    int? misses,
    bool? wonRound,
    int? score,
    int? correctCount,
  }) => HangmanState(
    status: status ?? this.status,
    level: level ?? this.level,
    words: words ?? this.words,
    currentIndex: currentIndex ?? this.currentIndex,
    guessedLetters: guessedLetters ?? this.guessedLetters,
    misses: misses ?? this.misses,
    wonRound: wonRound ?? this.wonRound,
    score: score ?? this.score,
    correctCount: correctCount ?? this.correctCount,
  );
}

class HangmanSessionNotifier extends StateNotifier<HangmanState> {
  HangmanSessionNotifier(int level) : super(HangmanState(level: level)) {
    _init();
  }

  Future<void> _init() async {
    final all = await HangmanContentLoader.load();
    final filtered = all.where((w) => w.level == state.level).toList()..shuffle();
    state = state.copyWith(status: HangmanStatus.playing, words: filtered);
  }

  int _pointsFor(int misses) => (30 - misses * 4).clamp(6, 30);

  void guessLetter(String letter) {
    if (state.status != HangmanStatus.playing) return;
    final word = state.currentWord;
    if (word == null) return;

    final upper = letter.toUpperCase();
    if (state.guessedLetters.contains(upper)) return;

    final guessed = {...state.guessedLetters, upper};
    final inWord = word.word.contains(upper);
    final misses = inWord ? state.misses : state.misses + 1;

    final solved = word.word.split('').every((c) => !RegExp(r'[A-Z]').hasMatch(c) || guessed.contains(c));
    final lost = misses >= hangmanMaxMisses;

    SoundService.play(inWord ? SfxSound.correct : SfxSound.wrong);
    if (solved) {
      SoundService.play(SfxSound.complete);
      state = state.copyWith(
        guessedLetters: guessed,
        misses: misses,
        status: HangmanStatus.roundOver,
        wonRound: true,
        score: state.score + _pointsFor(misses),
        correctCount: state.correctCount + 1,
      );
    } else if (lost) {
      state = state.copyWith(guessedLetters: guessed, misses: misses, status: HangmanStatus.roundOver, wonRound: false);
    } else {
      state = state.copyWith(guessedLetters: guessed, misses: misses);
    }
  }

  void nextWord() {
    if (state.isLastWord) {
      state = state.copyWith(status: HangmanStatus.finished);
      return;
    }
    state = state.copyWith(
      status: HangmanStatus.playing,
      currentIndex: state.currentIndex + 1,
      guessedLetters: const {},
      misses: 0,
      wonRound: false,
    );
  }
}

final hangmanSessionProvider = StateNotifierProvider.autoDispose.family<HangmanSessionNotifier, HangmanState, int>(
  (ref, level) => HangmanSessionNotifier(level),
);
