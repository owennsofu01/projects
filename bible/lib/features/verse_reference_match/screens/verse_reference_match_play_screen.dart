import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/answer_choice_button.dart';
import '../providers/verse_reference_match_session_provider.dart';
import 'verse_reference_match_result_screen.dart';

class VerseReferenceMatchPlayArgs {
  /// Each args instance is a fresh attempt, so retrying a level deals new verses.
  VerseReferenceMatchPlayArgs(this.level) : attempt = DateTime.now().microsecondsSinceEpoch;

  final int level;
  final int attempt;

  VerseReferenceMatchRound get round => (level: level, attempt: attempt);
}

class VerseReferenceMatchPlayScreen extends ConsumerWidget {
  const VerseReferenceMatchPlayScreen({super.key, required this.args});

  final VerseReferenceMatchPlayArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verseReferenceMatchSessionProvider(args.round));
    final notifier = ref.read(verseReferenceMatchSessionProvider(args.round).notifier);
    final theme = Theme.of(context);

    if (state.status == VerseReferenceMatchStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verse-to-Reference Match')),
        body: const Center(child: Text('No verses for this level yet.')),
      );
    }
    if (state.status == VerseReferenceMatchStatus.finished) {
      return VerseReferenceMatchResultScreen(state: state, level: args.level);
    }

    final item = state.currentItem!;
    final answered = state.status == VerseReferenceMatchStatus.answered;

    return Scaffold(
      appBar: AppBar(title: Text('Level ${args.level} · ${state.currentIndex + 1} of ${state.totalCount}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            LinearProgressIndicator(value: (state.currentIndex + 1) / state.totalCount),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${item.text}"', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(item.translation, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Where is this verse found?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final choice in state.currentChoices)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnswerChoiceButton(
                  label: choice,
                  result: !answered
                      ? null
                      : choice == item.reference
                      ? true
                      : choice == state.selectedReference
                      ? false
                      : null,
                  onPressed: answered ? null : () => notifier.submitAnswer(choice),
                ),
              ),
            if (answered) ...[
              const SizedBox(height: 8),
              Text(
                state.wasCorrect ? 'Correct!' : 'Not quite — it\'s ${item.reference}.',
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
