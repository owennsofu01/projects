import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/game_result.dart';
import '../../../core/progress/level_rules.dart';
import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/level_stars.dart';
import '../../../core/widgets/stat_pill.dart';
import '../data/match3_content_loader.dart';
import '../models/match3_level.dart';
import '../providers/match3_session_provider.dart';
import 'match3_play_screen.dart';

class Match3ResultScreen extends ConsumerStatefulWidget {
  const Match3ResultScreen({super.key, required this.state});

  final Match3State state;

  @override
  ConsumerState<Match3ResultScreen> createState() => _Match3ResultScreenState();
}

class _Match3ResultScreenState extends ConsumerState<Match3ResultScreen> {
  /// Seconds before a won round moves on to the next level by itself.
  static const _autoAdvanceSeconds = 8;

  bool _recorded = false;
  LevelOutcome? _outcome;
  Match3Level? _nextLevel;
  Timer? _timer;
  int _secondsLeft = _autoAdvanceSeconds;

  Match3Level get _level => widget.state.level!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_recorded) return;
    _recorded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = widget.state;
      final notifier = ref.read(userProfileProvider.notifier);
      notifier.recordGameResult(
        GameResult(
          gameModeId: Match3Rules.gameModeId,
          score: state.score,
          correctCount: state.won ? 1 : 0,
          totalCount: 1,
          difficulty: 'level_${_level.levelNumber}',
        ),
      );
      final outcome = notifier.recordLevelStars(
        gameModeId: Match3Rules.gameModeId,
        level: _level.levelNumber,
        stars: Match3Rules.starsFor(won: state.won, movesLeft: state.movesLeft, moves: _level.moves),
      );
      final levels = await Match3ContentLoader.load();
      final next = levels.where((l) => l.levelNumber == _level.levelNumber + 1).firstOrNull;
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _nextLevel = state.won ? next : null;
      });
      if (_nextLevel != null) _startCountdown();
    });
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_secondsLeft <= 1) {
        timer.cancel();
        _play(_nextLevel!);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
    setState(() => _timer = null);
  }

  void _play(Match3Level level) {
    _timer?.cancel();
    ref.read(lastEarnedBadgesProvider.notifier).state = [];
    context.pushReplacement(RoutePaths.match3Play, extra: Match3PlayArgs(level.id));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final badges = ref.watch(lastEarnedBadgesProvider);
    final outcome = _outcome;
    final next = _nextLevel;
    final counting = _timer?.isActive ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(state.won ? 'Level complete' : 'Out of moves')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              state.won ? Icons.emoji_events_outlined : Icons.hourglass_empty,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              state.won
                  ? 'Level ${_level.levelNumber} cleared!'
                  : '${state.score} of ${_level.targetScore} — so close!',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatPill(icon: Icons.stars_outlined, label: 'Score', value: '${state.score}'),
                const SizedBox(width: 12),
                StatPill(icon: Icons.swap_horiz, label: 'Moves left', value: '${state.movesLeft}'),
              ],
            ),
            const SizedBox(height: 24),
            if (outcome != null)
              LevelResultBanner(
                outcome: outcome,
                nextStarHint: (stars) => switch (stars) {
                  0 => 'Reach ${_level.targetScore} points within ${_level.moves} moves to clear the level.',
                  1 => 'Finish with 15% of your moves to spare for 2 stars.',
                  2 => 'Finish with 30% of your moves to spare for 3 stars.',
                  _ => null,
                },
              ),
            if (state.won) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('"${_level.rewardVerse}"', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('— ${_level.rewardReference}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('New badge earned!', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              for (final b in badges) Text(b.title, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            if (next != null) ...[
              FilledButton.icon(
                onPressed: () => _play(next),
                icon: const Icon(Icons.arrow_forward),
                label: Text(counting ? 'Level ${next.levelNumber} in $_secondsLeft…' : 'Level ${next.levelNumber}'),
              ),
              if (counting) TextButton(onPressed: _stopCountdown, child: const Text('Stay here')),
            ] else if (!state.won)
              FilledButton.icon(
                onPressed: () => _play(_level),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _timer?.cancel();
                ref.read(lastEarnedBadgesProvider.notifier).state = [];
                context.go(RoutePaths.match3);
              },
              child: const Text('Back to levels'),
            ),
          ],
        ),
      ),
    );
  }
}
