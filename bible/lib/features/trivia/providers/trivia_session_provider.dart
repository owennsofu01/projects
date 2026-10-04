import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../../../core/models/difficulty.dart';
import '../data/trivia_content_loader.dart';
import '../models/trivia_question.dart';

class TriviaConfig {
  const TriviaConfig({required this.category, required this.difficulty, required this.kidMode, this.level, this.seed});

  final String category; // 'All', 'Old Testament', 'New Testament', or a theme
  final Difficulty difficulty;
  final bool kidMode;

  /// When set, the round is a numbered Level Select round: questions are
  /// filtered strictly by [TriviaQuestion.level] and [category]/[difficulty]
  /// are ignored.
  final int? level;

  /// When set, the round is a shared competition round (daily challenge or
  /// friend challenge): [seededQuestionCount] questions are drawn
  /// deterministically from the whole bank, so everyone with the same seed
  /// gets the same questions in the same order. Overrides [level].
  final int? seed;

  static const seededQuestionCount = 10;

  @override
  bool operator ==(Object other) =>
      other is TriviaConfig &&
      other.category == category &&
      other.difficulty == difficulty &&
      other.kidMode == kidMode &&
      other.level == level &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(category, difficulty, kidMode, level, seed);
}

enum TriviaStatus { loading, playing, answered, finished }

class TriviaSessionState {
  const TriviaSessionState({
    this.status = TriviaStatus.loading,
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.streak = 0,
    this.correctCount = 0,
    this.selectedAnswer,
    this.secondsRemaining = 20,
  });

  final TriviaStatus status;
  final List<TriviaQuestion> questions;
  final int currentIndex;
  final int score;
  final int streak;
  final int correctCount;
  final String? selectedAnswer;
  final int secondsRemaining;

  TriviaQuestion? get currentQuestion => currentIndex < questions.length ? questions[currentIndex] : null;
  int get totalCount => questions.length;
  bool get isLastQuestion => currentIndex >= questions.length - 1;

  TriviaSessionState copyWith({
    TriviaStatus? status,
    List<TriviaQuestion>? questions,
    int? currentIndex,
    int? score,
    int? streak,
    int? correctCount,
    String? selectedAnswer,
    bool clearSelectedAnswer = false,
    int? secondsRemaining,
  }) => TriviaSessionState(
    status: status ?? this.status,
    questions: questions ?? this.questions,
    currentIndex: currentIndex ?? this.currentIndex,
    score: score ?? this.score,
    streak: streak ?? this.streak,
    correctCount: correctCount ?? this.correctCount,
    selectedAnswer: clearSelectedAnswer ? null : (selectedAnswer ?? this.selectedAnswer),
    secondsRemaining: secondsRemaining ?? this.secondsRemaining,
  );
}

const _questionSeconds = 20;

class TriviaSessionNotifier extends StateNotifier<TriviaSessionState> {
  TriviaSessionNotifier(this.config) : super(const TriviaSessionState()) {
    _init();
  }

  final TriviaConfig config;
  Timer? _timer;

  Future<void> _init() async {
    final all = await TriviaContentLoader.load();
    List<TriviaQuestion> filtered;
    if (config.seed != null) {
      // Sort first so the draw depends only on the seed, not on file order.
      filtered = ([...all]..sort((a, b) => a.id.compareTo(b.id)))
        ..shuffle(Random(config.seed))
        ..length = min(TriviaConfig.seededQuestionCount, all.length);
      state = state.copyWith(status: TriviaStatus.playing, questions: filtered, secondsRemaining: _questionSeconds);
      if (!config.kidMode) _startTimer();
      return;
    } else if (config.level != null) {
      filtered = all.where((q) => q.level == config.level).toList();
    } else {
      filtered = all.where((q) => q.difficulty == config.difficulty).toList();
      if (config.category != 'All') {
        filtered = filtered.where((q) => q.category == config.category).toList();
      }
    }
    filtered.shuffle();
    state = state.copyWith(status: TriviaStatus.playing, questions: filtered, secondsRemaining: _questionSeconds);
    if (!config.kidMode) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != TriviaStatus.playing) return;
      if (state.secondsRemaining <= 1) {
        _timer?.cancel();
        selectAnswer(null); // time's up, counts as incorrect
      } else {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      }
    });
  }

  void selectAnswer(String? answer) {
    if (state.status != TriviaStatus.playing) return;
    _timer?.cancel();
    final question = state.currentQuestion;
    if (question == null) return;

    final isCorrect = answer != null && answer == question.answer;
    final newStreak = isCorrect ? state.streak + 1 : 0;
    final streakBonus = isCorrect ? (newStreak >= 3 ? 15 : 10) : 0;

    SoundService.play(isCorrect ? SfxSound.correct : SfxSound.wrong);
    state = state.copyWith(
      status: TriviaStatus.answered,
      selectedAnswer: answer ?? '',
      score: state.score + streakBonus,
      streak: newStreak,
      correctCount: state.correctCount + (isCorrect ? 1 : 0),
    );
  }

  void nextQuestion() {
    if (state.isLastQuestion) {
      SoundService.play(SfxSound.complete);
      state = state.copyWith(status: TriviaStatus.finished);
      return;
    }
    state = state.copyWith(
      status: TriviaStatus.playing,
      currentIndex: state.currentIndex + 1,
      clearSelectedAnswer: true,
      secondsRemaining: _questionSeconds,
    );
    if (!config.kidMode) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final triviaSessionProvider = StateNotifierProvider.autoDispose
    .family<TriviaSessionNotifier, TriviaSessionState, TriviaConfig>((ref, config) => TriviaSessionNotifier(config));
