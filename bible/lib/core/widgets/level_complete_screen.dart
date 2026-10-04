import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/game_result.dart';
import '../progress/level_rules.dart';
import '../progress/progress_providers.dart';
import 'level_stars.dart';

/// End screen for puzzle modes that always end solved (Word Search,
/// Crossword, Jigsaw): records the round and its [stars], then offers the
/// next level, a replay, or the level list.
class LevelCompleteScreen extends ConsumerStatefulWidget {
  const LevelCompleteScreen({
    super.key,
    required this.result,
    required this.level,
    required this.stars,
    required this.headline,
    required this.stats,
    required this.levelCount,
    required this.levelsRoute,
    required this.onPlayLevel,
    this.nextStarHint,
    this.footer,
  });

  final GameResult result;
  final int level;
  final int stars;
  final String headline;
  final List<Widget> stats;
  final int levelCount;

  /// Where "Back to levels" goes.
  final String levelsRoute;

  /// Starts [level] as a new round, replacing this screen.
  final void Function(BuildContext context, int level) onPlayLevel;
  final String? Function(int stars)? nextStarHint;

  /// Extra content under the stars, e.g. the finished picture.
  final Widget? footer;

  @override
  ConsumerState<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends ConsumerState<LevelCompleteScreen> {
  bool _recorded = false;
  LevelOutcome? _outcome;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_recorded) return;
    _recorded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(userProfileProvider.notifier);
      notifier.recordGameResult(widget.result);
      final outcome = notifier.recordLevelStars(
        gameModeId: widget.result.gameModeId,
        level: widget.level,
        stars: widget.stars,
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
    final hasNext = widget.level < widget.levelCount;

    return Scaffold(
      appBar: AppBar(title: Text('Level ${widget.level} complete')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text(widget.headline, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: widget.stats),
            const SizedBox(height: 24),
            if (outcome != null) LevelResultBanner(outcome: outcome, nextStarHint: widget.nextStarHint),
            if (widget.footer case final footer?) ...[const SizedBox(height: 24), footer],
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('New badge earned!', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              for (final b in badges) Text(b.title, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            if (hasNext)
              FilledButton.icon(
                onPressed: () {
                  _clearBadges();
                  widget.onPlayLevel(context, widget.level + 1);
                },
                icon: const Icon(Icons.arrow_forward),
                label: Text('Level ${widget.level + 1}'),
              ),
            if (widget.stars < 3) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _clearBadges();
                  widget.onPlayLevel(context, widget.level);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Play again for more stars'),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
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
