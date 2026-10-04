import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/hangman_session_provider.dart';
import 'hangman_result_screen.dart';

class HangmanPlayArgs {
  const HangmanPlayArgs({required this.level});

  final int level;
}

class HangmanPlayScreen extends ConsumerWidget {
  const HangmanPlayScreen({super.key, required this.args});

  final HangmanPlayArgs args;

  static const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = args.level;
    final state = ref.watch(hangmanSessionProvider(level));
    final notifier = ref.read(hangmanSessionProvider(level).notifier);
    final accent = AppColors.accentFor('hangman');

    if (state.status == HangmanStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hangman')),
        body: const Center(child: Text('No words for this level yet.')),
      );
    }
    if (state.status == HangmanStatus.finished) {
      return HangmanResultScreen(state: state, level: level);
    }

    final word = state.currentWord!;
    final isRoundOver = state.status == HangmanStatus.roundOver;
    final masked = word.word
        .split('')
        .map((c) => !RegExp(r'[A-Z]').hasMatch(c) ? c : (state.guessedLetters.contains(c) ? c : '_'))
        .join(' ');

    return Scaffold(
      appBar: AppBar(title: Text('Level $level · Word ${state.currentIndex + 1} of ${state.totalCount}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${state.score} · Category: ${word.category}', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < hangmanMaxMisses; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.circle,
                      size: 14,
                      color: i < state.misses ? Colors.red : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                const SizedBox(width: 8),
                Text('${state.misses} / $hangmanMaxMisses misses', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                masked,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 4),
              ),
            ),
            const SizedBox(height: 12),
            Text('Hint: ${word.hint}', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: isRoundOver
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (state.wonRound ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            state.wonRound
                                ? 'Solved it! The word was ${word.word}.'
                                : 'Out of misses — it was ${word.word}.',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final letter in _letters.split(''))
                              _LetterKey(
                                letter: letter,
                                guessed: state.guessedLetters.contains(letter),
                                correct: word.word.contains(letter),
                                accent: accent,
                                onTap: () => notifier.guessLetter(letter),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: isRoundOver
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: notifier.nextWord,
                  icon: Icon(state.isLastWord ? Icons.flag_outlined : Icons.arrow_forward),
                  label: Text(state.isLastWord ? 'Finish' : 'Next Word'),
                )
              : const SizedBox(height: 48),
        ),
      ),
    );
  }
}

class _LetterKey extends StatelessWidget {
  const _LetterKey({
    required this.letter,
    required this.guessed,
    required this.correct,
    required this.accent,
    required this.onTap,
  });

  final String letter;
  final bool guessed;
  final bool correct;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !guessed
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : (correct ? Colors.green : Colors.red).withValues(alpha: 0.2);

    return InkWell(
      onTap: guessed ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(
          letter,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: guessed ? null : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
