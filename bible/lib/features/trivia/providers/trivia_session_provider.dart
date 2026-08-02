import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/difficulty.dart';
import '../data/trivia_content_loader.dart';
import '../models/trivia_question.dart';

class TriviaConfig {
  const TriviaConfig({required this.category, required this.difficulty, required this.kidMode, this.level});

  final String category; // 'All', 'Old Testament', 'New Testament', or a theme
  final Difficulty difficulty;
  final bool kidMode;

  /// When set, the round is a numbered Level Select round: questions are
  /// filtered strictly by [TriviaQuestion.level] and [category]/[difficulty]
  /// are ignored.
  final int? level;

  @override
  bool operator ==(Object other) =>
      other is TriviaConfig &&
      other.category == category &&
      other.difficulty == difficulty &&
      other.kidMode == kidMode &&
      other.level == level;

  @override
  int get hashCode => Object.hash(category, difficulty, kidMode, level);
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

  TriviaQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;
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
  }) =>
      TriviaSessionState(
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
    if (config.level != null) {
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
    .family<TriviaSessionNotifier, TriviaSessionState, TriviaConfig>(
  (ref, config) => TriviaSessionNotifier(config),
);
