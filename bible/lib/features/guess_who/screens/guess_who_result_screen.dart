import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/game_result.dart';
import '../../../core/progress/level_rules.dart';
import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/level_stars.dart';
import '../../../core/widgets/stat_pill.dart';
import '../providers/guess_who_session_provider.dart';

class GuessWhoResultScreen extends ConsumerStatefulWidget {
  const GuessWhoResultScreen({super.key, required this.state, required this.level});

  final GuessWhoState state;
  final int level;

  @override
  ConsumerState<GuessWhoResultScreen> createState() => _GuessWhoResultScreenState();
}

class _GuessWhoResultScreenState extends ConsumerState<GuessWhoResultScreen> {
  bool _recorded = false;
  LevelOutcome? _levelOutcome;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(userProfileProvider.notifier)
            .recordGameResult(
              GameResult(
                gameModeId: 'guess_who',
                score: widget.state.score,
                correctCount: widget.state.correctCount,
                totalCount: widget.state.totalCount,
                difficulty: 'level_${widget.level}',
              ),
            );
        final outcome = ref
            .read(userProfileProvider.notifier)
            .recordLevel(
              gameModeId: 'guess_who',
              level: widget.level,
              correct: widget.state.correctCount,
              total: widget.state.totalCount,
            );
        if (mounted) setState(() => _levelOutcome = outcome);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final badges = ref.watch(lastEarnedBadgesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Round complete')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              '${state.correctCount} / ${state.totalCount} characters guessed',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatPill(icon: Icons.stars_outlined, label: 'Score', value: '${state.score}'),
                const SizedBox(width: 12),
                StatPill(icon: Icons.check_circle_outline, label: 'Correct', value: '${state.correctCount}'),
              ],
            ),
            const SizedBox(height: 24),
            if (_levelOutcome case final outcome?) LevelResultBanner(outcome: outcome),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('New badge earned!', style: Theme.of(context).textTheme.titleMedium),
              for (final b in badges) Text(b.title),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                ref.read(lastEarnedBadgesProvider.notifier).state = [];
                context.go(RoutePaths.guessWho);
              },
              child: const Text('Back to levels'),
            ),
          ],
        ),
      ),
    );
  }
}
