import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/game_result.dart';
import '../../../core/progress/level_rules.dart';
import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/level_stars.dart';
import '../../../core/widgets/stat_pill.dart';
import '../providers/timeline_puzzle_session_provider.dart';

class TimelinePuzzleResultScreen extends ConsumerStatefulWidget {
  const TimelinePuzzleResultScreen({super.key, required this.state, required this.level});

  final TimelinePuzzleState state;
  final int level;

  @override
  ConsumerState<TimelinePuzzleResultScreen> createState() => _TimelinePuzzleResultScreenState();
}

class _TimelinePuzzleResultScreenState extends ConsumerState<TimelinePuzzleResultScreen> {
  bool _recorded = false;
  LevelOutcome? _levelOutcome;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = widget.state;
        final notifier = ref.read(userProfileProvider.notifier)
          ..recordGameResult(
            GameResult(
              gameModeId: 'timeline_puzzle',
              score: state.score,
              correctCount: state.totalCount,
              totalCount: state.totalCount,
              difficulty: 'level_${widget.level}',
            ),
          );
        final outcome = notifier.recordLevelStars(
          gameModeId: 'timeline_puzzle',
          level: widget.level,
          stars: state.stars,
        );
        if (mounted) setState(() => _levelOutcome = outcome);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final badges = ref.watch(lastEarnedBadgesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline complete')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: theme.colorScheme.secondary),
          const SizedBox(height: 16),
          Text(
            'All ${state.totalCount} events in order!',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatPill(icon: Icons.stars_outlined, label: 'Score', value: '${state.score}'),
              const SizedBox(width: 12),
              StatPill(icon: Icons.checklist_outlined, label: 'Checks', value: '${state.checks}'),
            ],
          ),
          if (_levelOutcome case final outcome?) ...[
            const SizedBox(height: 24),
            LevelResultBanner(
              outcome: outcome,
              nextStarHint: (stars) => switch (stars) {
                1 => 'Solve it in two checks for 2 stars.',
                2 => 'Solve it on your first check for 3 stars.',
                _ => null,
              },
            ),
          ],
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('New badge earned!', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            for (final b in badges) Text(b.title, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          Text('The timeline', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final (i, event) in state.order.indexed)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 14, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
              title: Text(event.event),
              subtitle: Text(event.reference),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref.read(lastEarnedBadgesProvider.notifier).state = [];
              context.go(RoutePaths.timelinePuzzle);
            },
            child: const Text('Back to levels'),
          ),
        ],
      ),
    );
  }
}
