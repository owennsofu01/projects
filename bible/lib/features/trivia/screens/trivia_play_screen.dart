import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/difficulty.dart';
import '../../compete/models/compete_models.dart';
import '../providers/trivia_session_provider.dart';
import 'trivia_result_screen.dart';

class TriviaPlayArgs {
  const TriviaPlayArgs({
    required this.category,
    required this.difficulty,
    required this.kidMode,
    this.level,
    this.competition,
  });

  /// A daily or friend challenge round with a fixed, shared question set.
  const TriviaPlayArgs.competition(CompetitionContext this.competition)
    : category = 'All',
      difficulty = Difficulty.adult,
      kidMode = false,
      level = null;

  final String category;
  final Difficulty difficulty;
  final bool kidMode;

  /// Set when launched from the Level Select screen; see [TriviaConfig.level].
  final int? level;

  final CompetitionContext? competition;
}

class TriviaPlayScreen extends ConsumerWidget {
  const TriviaPlayScreen({super.key, required this.args});

  final TriviaPlayArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = TriviaConfig(
      category: args.category,
      difficulty: args.difficulty,
      kidMode: args.kidMode,
      level: args.level,
      seed: args.competition?.seed,
    );
    final state = ref.watch(triviaSessionProvider(config));
    final notifier = ref.read(triviaSessionProvider(config).notifier);

    if (state.status == TriviaStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bible Trivia')),
        body: const Center(child: Text('No questions match that category and difficulty yet.')),
      );
    }

    if (state.status == TriviaStatus.finished) {
      return TriviaResultScreen(state: state, level: args.level, competition: args.competition);
    }

    final question = state.currentQuestion!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${state.currentIndex + 1} of ${state.totalCount}'),
        actions: [
          if (!args.kidMode)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('⏱ ${state.secondsRemaining}s')),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (state.currentIndex + 1) / state.totalCount),
            const SizedBox(height: 8),
            Text(
              'Score: ${state.score}${state.streak >= 3 ? '  🔥 x${state.streak}' : ''}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 24),
            Text(question.question, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('${question.category} · ${question.subcategory}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            ...question.options.map((option) {
              final isSelected = state.selectedAnswer == option;
              final isCorrectOption = option == question.answer;
              final showFeedback = state.status == TriviaStatus.answered;

              Color? color;
              if (showFeedback) {
                if (isCorrectOption) {
                  color = Colors.green.withValues(alpha: 0.2);
                } else if (isSelected) {
                  color = Colors.red.withValues(alpha: 0.2);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: showFeedback ? null : () => notifier.selectAnswer(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text(option),
                    ),
                  ),
                ),
              );
            }),
            if (state.status == TriviaStatus.answered) ...[
              const SizedBox(height: 8),
              Text(
                'Reference: ${question.reference} (${question.translation})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              FilledButton(
                onPressed: notifier.nextQuestion,
                child: Text(state.isLastQuestion ? 'See results' : 'Next question'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
