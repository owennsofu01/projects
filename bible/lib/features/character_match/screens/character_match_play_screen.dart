import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/character_match_session_provider.dart';
import 'character_match_result_screen.dart';

class CharacterMatchPlayScreen extends ConsumerWidget {
  const CharacterMatchPlayScreen({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(characterMatchSessionProvider(level));
    final notifier = ref.read(characterMatchSessionProvider(level).notifier);
    final accent = AppColors.accentFor('character_match');

    if (state.status == CharacterMatchStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.characters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Character Match')),
        body: const Center(child: Text('No characters for this level yet.')),
      );
    }
    if (state.status == CharacterMatchStatus.finished) {
      return CharacterMatchResultScreen(state: state, level: level);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Level $level · ${state.level?.title ?? 'Character Match'}'),
        actions: const [
          HowToPlayButton(
            title: 'Character Match',
            steps: [
              'Flip two cards at a time to pair each Bible figure with their defining moment.',
              'Matched moments show where to find them in Scripture.',
              'Finish with no more misses than pairs for 3 stars, up to twice as many for 2.',
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Matched ${state.matchedCharacterIds.length} / ${state.totalPairs} · ${state.misses} misses',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.72,
                ),
                itemCount: state.cards.length,
                itemBuilder: (context, index) {
                  final card = state.cards[index];
                  final isRevealed =
                      state.flipped.contains(index) || state.matchedCharacterIds.contains(card.characterId);
                  final isMatched = state.matchedCharacterIds.contains(card.characterId);

                  return GestureDetector(
                    onTap: () => notifier.flipCard(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isMatched
                            ? Colors.green.withValues(alpha: 0.15)
                            : isRevealed
                            ? accent.withValues(alpha: 0.15)
                            : accent,
                        borderRadius: BorderRadius.circular(12),
                        border: isMatched ? Border.all(color: Colors.green, width: 2) : null,
                      ),
                      padding: const EdgeInsets.all(6),
                      alignment: Alignment.center,
                      child: isRevealed
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  card.primaryText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                if (card.secondaryText != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    card.secondaryText!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                                if (isMatched && card.reference != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    card.reference!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            )
                          : const Icon(Icons.auto_stories_outlined, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
