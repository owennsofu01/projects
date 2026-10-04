import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../models/parable.dart';
import '../providers/parable_matching_session_provider.dart';
import 'parable_matching_result_screen.dart';

class ParableMatchingPlayScreen extends ConsumerWidget {
  const ParableMatchingPlayScreen({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(parableMatchingSessionProvider(level));
    final notifier = ref.read(parableMatchingSessionProvider(level).notifier);
    final accent = AppColors.accentFor('parable_matching');

    if (state.status == ParableMatchingStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.parables.isEmpty) {
      return const Scaffold(body: Center(child: Text('No parables to match yet.')));
    }
    if (state.status == ParableMatchingStatus.finished) {
      return ParableMatchingResultScreen(state: state, level: level);
    }

    final byId = {for (final p in state.parables) p.id: p};
    final match = state.level!.match;

    Widget tile({required String id, required String text, required bool isLeft}) {
      final isMatched = state.matchedIds.contains(id);
      final isSelected = isLeft && state.selectedLeftId == id;
      final isWrong = isLeft ? state.wrongLeftId == id : state.wrongRightId == id;

      final color = isMatched
          ? Colors.green.withValues(alpha: 0.15)
          : isWrong
          ? Colors.red.withValues(alpha: 0.12)
          : isSelected
          ? accent.withValues(alpha: 0.25)
          : Theme.of(context).colorScheme.surfaceContainerHighest;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isMatched ? null : () => isLeft ? notifier.selectLeft(id) : notifier.selectRight(id),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: accent, width: 2) : null,
            ),
            child: Row(
              children: [
                if (isMatched)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ),
                Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Level $level · ${state.level!.title}'),
        actions: [
          HowToPlayButton(
            title: 'Parable Matching',
            steps: [
              'Tap a parable on the left, then tap its match on the right: its lesson, a moment from the story, or where it is found, depending on the level.',
              "If it's a match, both are marked correct; if not, try again.",
              'A perfect round earns 3 stars, one mistake 2 stars, two mistakes 1 star. One star unlocks the next level.',
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${match.instructions} ${state.matchedIds.length} / ${state.totalCount} matched · ${state.mistakes} mistake${state.mistakes == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        for (final id in state.leftOrder)
                          tile(id: id, text: (byId[id] as Parable).parable, isLeft: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final id in state.rightOrder)
                          tile(id: id, text: match.answerFor(byId[id] as Parable), isLeft: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
