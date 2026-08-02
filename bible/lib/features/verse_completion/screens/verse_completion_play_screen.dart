import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/difficulty.dart';
import '../providers/verse_completion_session_provider.dart';
import 'verse_completion_result_screen.dart';

class VerseCompletionPlayArgs {
  const VerseCompletionPlayArgs({required this.difficulty, required this.kidMode});

  final Difficulty difficulty;
  final bool kidMode;
}

class VerseCompletionPlayScreen extends ConsumerStatefulWidget {
  const VerseCompletionPlayScreen({super.key, required this.args});

  final VerseCompletionPlayArgs args;

  @override
  ConsumerState<VerseCompletionPlayScreen> createState() => _VerseCompletionPlayScreenState();
}

class _VerseCompletionPlayScreenState extends ConsumerState<VerseCompletionPlayScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = VerseCompletionConfig(difficulty: widget.args.difficulty, kidMode: widget.args.kidMode);
    final state = ref.watch(verseCompletionSessionProvider(config));
    final notifier = ref.read(verseCompletionSessionProvider(config).notifier);

    if (state.status == VerseCompletionStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verse Completion')),
        body: const Center(child: Text('No verses match that difficulty yet.')),
      );
    }
    if (state.status == VerseCompletionStatus.finished) {
      return VerseCompletionResultScreen(state: state);
    }

    final item = state.currentItem!;
    final answered = state.status == VerseCompletionStatus.answered;

    return Scaffold(
      appBar: AppBar(title: Text('Verse ${state.currentIndex + 1} of ${state.totalCount}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (state.currentIndex + 1) / state.totalCount),
            const SizedBox(height: 24),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineSmall,
                children: [
                  TextSpan(text: item.textBeforeBlank),
                  TextSpan(
                    text: answered ? (state.wasCorrect ? item.answer : state.lastAnswer) : '_____',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: answered
                          ? (state.wasCorrect ? Colors.green : Colors.red)
                          : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  TextSpan(text: item.textAfterBlank),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('${item.reference} (${item.translation})', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 32),
            if (!answered && widget.args.kidMode)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: item.wordBank
                    .map((word) => ActionChip(label: Text(word), onPressed: () => notifier.submitAnswer(word)))
                    .toList(),
              )
            else if (!answered)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Type the missing words…',
                      ),
                      onSubmitted: (value) => notifier.submitAnswer(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => notifier.submitAnswer(_controller.text),
                    child: const Text('Check'),
                  ),
                ],
              ),
            if (answered) ...[
              Text(
                state.wasCorrect ? 'Correct!' : 'Not quite — the answer was "${item.answer}".',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: state.wasCorrect ? Colors.green : Colors.red),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  _controller.clear();
                  notifier.nextItem();
                },
                child: Text(state.isLastItem ? 'See results' : 'Next verse'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
