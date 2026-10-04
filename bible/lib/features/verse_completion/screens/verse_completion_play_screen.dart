import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/answer_choice_button.dart';
import '../providers/verse_completion_session_provider.dart';
import 'verse_completion_result_screen.dart';

class VerseCompletionPlayArgs {
  /// Each args instance is a fresh attempt, so retrying a level deals new verses.
  VerseCompletionPlayArgs(this.level) : attempt = DateTime.now().microsecondsSinceEpoch;

  final int level;
  final int attempt;

  VerseCompletionRound get round => (level: level, attempt: attempt);
}

class VerseCompletionPlayScreen extends ConsumerWidget {
  const VerseCompletionPlayScreen({super.key, required this.args});

  final VerseCompletionPlayArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verseCompletionSessionProvider(args.round));
    final notifier = ref.read(verseCompletionSessionProvider(args.round).notifier);
    final theme = Theme.of(context);

    if (state.status == VerseCompletionStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verse Completion')),
        body: const Center(child: Text('No verses for this level yet.')),
      );
    }
    if (state.status == VerseCompletionStatus.finished) {
      return VerseCompletionResultScreen(state: state, level: args.level);
    }

    final item = state.currentItem!;
    final answered = state.status == VerseCompletionStatus.answered;

    return Scaffold(
      appBar: AppBar(title: Text('Level ${args.level} · ${state.currentIndex + 1} of ${state.totalCount}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            LinearProgressIndicator(value: (state.currentIndex + 1) / state.totalCount),
            const SizedBox(height: 24),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: item.textBeforeBlank),
                  TextSpan(
                    text: answered ? item.answer : '_____',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: answered ? Colors.green : theme.colorScheme.secondary,
                    ),
                  ),
                  TextSpan(text: item.textAfterBlank),
                ],
              ),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('${item.reference} (${item.translation})', style: theme.textTheme.bodySmall),
            const SizedBox(height: 28),
            for (final choice in state.currentChoices)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnswerChoiceButton(
                  label: choice,
                  result: !answered
                      ? null
                      : choice == item.answer
                      ? true
                      : choice == state.lastAnswer
                      ? false
                      : null,
                  onPressed: answered ? null : () => notifier.submitAnswer(choice),
                ),
              ),
            if (answered) ...[
              const SizedBox(height: 8),
              Text(
                state.wasCorrect ? 'Correct!' : 'Not quite — the answer was "${item.answer}".',
                style: theme.textTheme.titleMedium?.copyWith(color: state.wasCorrect ? Colors.green : Colors.red),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: notifier.nextItem, child: Text(state.isLastItem ? 'See results' : 'Next verse')),
            ],
          ],
        ),
      ),
    );
  }
}
