import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/game_result.dart';
import '../../../core/progress/level_rules.dart';
import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/level_stars.dart';
import '../../../core/widgets/stat_pill.dart';
import '../../compete/models/compete_models.dart';
import '../../compete/providers/compete_providers.dart';
import '../providers/trivia_session_provider.dart';

class TriviaResultScreen extends ConsumerStatefulWidget {
  const TriviaResultScreen({super.key, required this.state, this.level, this.competition});

  final TriviaSessionState state;

  /// Set when this round was played from the Level Select screen; passing
  /// the round unlocks [level] + 1.
  final int? level;

  /// Set for daily/friend challenge rounds; the score is submitted there.
  final CompetitionContext? competition;

  @override
  ConsumerState<TriviaResultScreen> createState() => _TriviaResultScreenState();
}

class _TriviaResultScreenState extends ConsumerState<TriviaResultScreen> {
  bool _recorded = false;
  LevelOutcome? _levelOutcome;

  /// Null while submitting a competition score, then the outcome message.
  String? _submitError;
  bool _submitted = false;

  Future<void> _submitCompetition(CompetitionContext competition) async {
    try {
      await ref
          .read(competeActionsProvider)
          .submit(
            competition,
            score: widget.state.score,
            correct: widget.state.correctCount,
            total: widget.state.totalCount,
          );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) setState(() => _submitError = e.toString());
    }
  }

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
                gameModeId: 'trivia',
                score: widget.state.score,
                correctCount: widget.state.correctCount,
                totalCount: widget.state.totalCount,
                difficulty: widget.state.questions.first.difficulty.name,
              ),
            );
        final competition = widget.competition;
        if (competition != null) _submitCompetition(competition);
        final level = widget.level;
        if (level != null) {
          final outcome = ref
              .read(userProfileProvider.notifier)
              .recordLevel(
                gameModeId: 'trivia',
                level: level,
                correct: widget.state.correctCount,
                total: widget.state.totalCount,
              );
          if (mounted) setState(() => _levelOutcome = outcome);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final badges = ref.watch(lastEarnedBadgesProvider);
    final level = widget.level;

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
              '${state.correctCount} / ${state.totalCount} correct',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatPill(icon: Icons.stars_outlined, label: 'Score', value: '${state.score}'),
                const SizedBox(width: 12),
                StatPill(icon: Icons.local_fire_department_outlined, label: 'Best streak', value: '${state.streak}'),
              ],
            ),
            if (_levelOutcome case final outcome?) ...[const SizedBox(height: 24), LevelResultBanner(outcome: outcome)],
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('New badge earned!', style: Theme.of(context).textTheme.titleMedium),
              for (final b in badges) Text(b.title),
            ],
            if (widget.competition != null) ...[
              const SizedBox(height: 24),
              if (_submitError != null)
                Text(
                  _submitError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else if (!_submitted)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Submitting your score…'),
                  ],
                )
              else
                Text('Score submitted!', style: Theme.of(context).textTheme.titleMedium),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                ref.read(lastEarnedBadgesProvider.notifier).state = [];
                switch (widget.competition) {
                  case DailyCompetition():
                    context.go(RoutePaths.compete);
                  case FriendCompetition(:final code):
                    context.go(RoutePaths.challengeResult, extra: code);
                  case null:
                    context.go(level != null ? RoutePaths.triviaLevels : RoutePaths.home);
                }
              },
              child: Text(switch (widget.competition) {
                DailyCompetition() => "See today's leaderboard",
                FriendCompetition() => 'See challenge results',
                null => level != null ? 'Back to levels' : 'Back to hub',
              }),
            ),
          ],
        ),
      ),
    );
  }
}
