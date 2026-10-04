import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../bible_reader/providers/bible_reader_provider.dart';
import '../providers/guess_who_session_provider.dart';
import 'guess_who_result_screen.dart';

class GuessWhoPlayArgs {
  const GuessWhoPlayArgs({required this.level});

  final int level;
}

class GuessWhoPlayScreen extends ConsumerStatefulWidget {
  const GuessWhoPlayScreen({super.key, required this.args});

  final GuessWhoPlayArgs args;

  @override
  ConsumerState<GuessWhoPlayScreen> createState() => _GuessWhoPlayScreenState();
}

class _GuessWhoPlayScreenState extends ConsumerState<GuessWhoPlayScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(GuessWhoSessionNotifier notifier) {
    if (_controller.text.trim().isEmpty) return;
    notifier.submitGuess(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.args.level;
    final state = ref.watch(guessWhoSessionProvider(level));
    final notifier = ref.read(guessWhoSessionProvider(level).notifier);
    final accent = AppColors.accentFor('guess_who');

    if (state.status == GuessWhoStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.characters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('"Guess Who" Reveal')),
        body: const Center(child: Text('No characters for this level yet.')),
      );
    }
    if (state.status == GuessWhoStatus.finished) {
      return GuessWhoResultScreen(state: state, level: level);
    }

    final character = state.currentCharacter!;
    final isAnswered = state.status == GuessWhoStatus.answered;
    // Once the round ends, show every clue (even unrevealed ones) with the
    // scripture it comes from.
    final shownClues = isAnswered ? character.clues : character.clues.take(state.revealedClueCount).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Level $level · Character ${state.currentIndex + 1} of ${state.totalCount}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${state.score}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  if (isAnswered)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (state.wasCorrect ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        state.wasCorrect
                            ? 'Correct! It was ${character.characterName}.'
                            : 'It was ${character.characterName}.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  for (var i = 0; i < shownClues.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: accent.withValues(alpha: 0.15),
                            foregroundColor: accent,
                            child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(shownClues[i], style: Theme.of(context).textTheme.bodyLarge),
                                if (isAnswered && character.referenceFor(i) != null)
                                  _ScriptureSource(reference: character.referenceFor(i)!, accent: accent),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (!isAnswered) ...[
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Who is it?', border: OutlineInputBorder()),
                onSubmitted: (_) => _submit(notifier),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: notifier.giveUp, child: const Text('Give Up')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: () => _submit(notifier),
                      child: const Text('Guess'),
                    ),
                  ),
                ],
              ),
            ] else
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: accent),
                onPressed: notifier.nextCharacter,
                icon: Icon(state.isLastCharacter ? Icons.flag_outlined : Icons.arrow_forward),
                label: Text(state.isLastCharacter ? 'Finish' : 'Next Character'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScriptureSource extends ConsumerWidget {
  const _ScriptureSource({required this.reference, required this.accent});

  final String reference;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final passage = ref.watch(scripturePassageProvider(reference));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        border: Border(left: BorderSide(color: accent, width: 3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                reference,
                style: textTheme.labelLarge?.copyWith(color: accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          passage.when(
            data: (verses) => Text(
              verses.map((v) => verses.length > 1 ? '${v.number} ${v.text}' : v.text).join(' '),
              style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, height: 1.4),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => Text(
              'Verse text unavailable offline — look up $reference in the Bible reader.',
              style: textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
