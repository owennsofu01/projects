import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/game_result.dart';
import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/stat_pill.dart';
import '../providers/trivia_session_provider.dart';

class TriviaResultScreen extends ConsumerStatefulWidget {
  const TriviaResultScreen({super.key, required this.state, this.level});

  final TriviaSessionState state;

  /// Set when this round was played from the Level Select screen; passing
  /// the round unlocks [level] + 1.
  final int? level;

  @override
  ConsumerState<TriviaResultScreen> createState() => _TriviaResultScreenState();
}

class _TriviaResultScreenState extends ConsumerState<TriviaResultScreen> {
  bool _recorded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(userProfileProvider.notifier).recordGameResult(GameResult(
              gameModeId: 'trivia',
              score: widget.state.score,
              correctCount: widget.state.correctCount,
              totalCount: widget.state.totalCount,
              difficulty: widget.state.questions.first.difficulty.name,
            ));
        final level = widget.level;
        final passed = widget.state.totalCount > 0 &&
            widget.state.correctCount / widget.state.totalCount >= 0.6;
        if (level != null && passed) {
          ref.read(userProfileProvider.notifier).unlockTriviaLevel(level);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final badges = ref.watch(lastEarnedBadgesProvider);
    final level = widget.level;
    final passedLevel = level != null &&
        state.totalCount > 0 &&
        state.correctCount / state.totalCount >= 0.6;

    return Scaffold(
      appBar: AppBar(title: const Text('Round complete')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 16),
            Text('${state.correctCount} / ${state.totalCount} correct',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatPill(icon: Icons.stars_outlined, label: 'Score', value: '${state.score}'),
                const SizedBox(width: 12),
                StatPill(icon: Icons.local_fire_department_outlined, label: 'Best streak', value: '${state.streak}'),
              ],
            ),
            if (level != null) ...[
              const SizedBox(height: 24),
              Text(
                passedLevel ? 'Level $level cleared! Level ${level + 1} unlocked 🎉' : 'Score 60% or higher to unlock the next level.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('New badge earned!', style: Theme.of(context).textTheme.titleMedium),
              for (final b in badges) Text(b.title),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                ref.read(lastEarnedBadgesProvider.notifier).state = [];
                context.go(level != null ? RoutePaths.triviaLevels : RoutePaths.home);
              },
              child: Text(level != null ? 'Back to levels' : 'Back to hub'),
            ),
          ],
        ),
      ),
    );
  }
}
