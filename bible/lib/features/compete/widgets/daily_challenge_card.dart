import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../trivia/providers/trivia_session_provider.dart';
import '../../trivia/screens/trivia_play_screen.dart';
import '../models/compete_models.dart';
import '../providers/compete_providers.dart';

/// Today's shared trivia challenge, shown on both Home and Compete.
class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dayKey = ref.watch(todayKeyProvider);
    final entryAsync = ref.watch(myDailyEntryProvider);
    final player = ref.watch(myPlayerProvider).value;
    final streak = player?.dailyStreak ?? 0;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily Challenge',
                    style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                if (streak > 0)
                  Chip(
                    avatar: const Icon(Icons.local_fire_department, size: 18),
                    label: Text('$streak day${streak == 1 ? '' : 's'}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${TriviaConfig.seededQuestionCount} trivia questions — the same for every player today. One attempt only.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            entryAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(
                "Couldn't load today's challenge. Check your connection.",
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
              data: (entry) => entry != null
                  ? Text(
                      "Done for today: ${entry.score} points (${entry.correctCount}/${entry.totalCount}). "
                      'Come back tomorrow!',
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    )
                  : player == null
                  // Daily scores go on a public leaderboard, so a display
                  // name is needed first; the Compete tab handles joining.
                  ? FilledButton.icon(
                      onPressed: () => context.go(RoutePaths.compete),
                      icon: const Icon(Icons.emoji_events_outlined),
                      label: const Text('Join the leaderboard to play'),
                    )
                  : FilledButton.icon(
                      onPressed: () => context.push(
                        RoutePaths.triviaPlay,
                        extra: TriviaPlayArgs.competition(DailyCompetition(dayKey)),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Play today's challenge"),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
