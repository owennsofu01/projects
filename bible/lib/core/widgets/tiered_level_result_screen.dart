import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/game_result.dart';
import '../progress/level_rules.dart';
import '../progress/progress_providers.dart';
import '../progress/tiered_levels.dart';
import 'level_stars.dart';
import 'stat_pill.dart';

/// End-of-round screen for [TieredLevels] modes: records the result and
/// stars, then offers the next level on a pass or a fresh retry on a fail.
class TieredLevelResultScreen extends ConsumerStatefulWidget {
  const TieredLevelResultScreen({
    super.key,
    required this.gameModeId,
    required this.level,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.levelsRoute,
    required this.onPlayLevel,
  });

  final String gameModeId;
  final int level;
  final int score;
  final int correctCount;
  final int totalCount;

  /// Where "Back to levels" goes.
  final String levelsRoute;

  /// Starts [level] as a new round, replacing this screen.
  final void Function(BuildContext context, int level) onPlayLevel;

  @override
  ConsumerState<TieredLevelResultScreen> createState() => _TieredLevelResultScreenState();
}

class _TieredLevelResultScreenState extends ConsumerState<TieredLevelResultScreen> {
  bool _recorded = false;
  LevelOutcome? _outcome;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_recorded) return;
    _recorded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(userProfileProvider.notifier);
      notifier.recordGameResult(
        GameResult(
          gameModeId: widget.gameModeId,
          score: widget.score,
          correctCount: widget.correctCount,
          totalCount: widget.totalCount,
          difficulty: 'level_${widget.level}',
        ),
      );
      final outcome = notifier.recordLevelStars(
        gameModeId: widget.gameModeId,
        level: widget.level,
        stars: TieredLevels.starsFor(correct: widget.correctCount, total: widget.totalCount),
      );
      if (mounted) setState(() => _outcome = outcome);
    });
  }

  void _clearBadges() => ref.read(lastEarnedBadgesProvider.notifier).state = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badges = ref.watch(lastEarnedBadgesProvider);
    final outcome = _outcome;
    final passed = outcome?.passed ?? false;
    final hasNext = widget.level < TieredLevels.levelCount;

    return Scaffold(
      appBar: AppBar(title: Text('Level ${widget.level} complete')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              '${widget.correctCount} / ${widget.totalCount} correct',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: StatPill(icon: Icons.stars_outlined, label: 'Score', value: '${widget.score}'),
            ),
            const SizedBox(height: 24),
            if (outcome != null) LevelResultBanner(outcome: outcome, nextStarHint: TieredLevels.nextStarHint),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('New badge earned!', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              for (final b in badges) Text(b.title, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            if (outcome != null && passed && hasNext)
              FilledButton.icon(
                onPressed: () {
                  _clearBadges();
                  widget.onPlayLevel(context, widget.level + 1);
                },
                icon: const Icon(Icons.arrow_forward),
                label: Text('Level ${widget.level + 1}'),
              ),
            if (outcome != null && !passed)
              FilledButton.icon(
                onPressed: () {
                  _clearBadges();
                  widget.onPlayLevel(context, widget.level);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try again with new verses'),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _clearBadges();
                context.go(widget.levelsRoute);
              },
              child: const Text('Back to levels'),
            ),
          ],
        ),
      ),
    );
  }
}
