import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../progress/level_rules.dart';

const _starColor = Color(0xFFE0A526);

/// Filled/empty stars for a level's best rating.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 20, this.animate = false});

  final int stars;
  final double size;

  /// Pop the earned stars in one after another (result screens).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final empty = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 0; i < LevelRules.maxStars; i++) _star(i < stars, empty, i)],
    );
  }

  Widget _star(bool filled, Color empty, int index) {
    final icon = Icon(
      filled ? Icons.star_rounded : Icons.star_outline_rounded,
      size: size,
      color: filled ? _starColor : empty,
    );
    if (!animate || !filled) return icon;
    return icon
        .animate(delay: (250 * index).ms)
        .scale(begin: const Offset(0.2, 0.2), duration: 400.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 150.ms);
  }
}

/// "★ 17 / 30" summary for the top of a level select screen.
class StarTotalChip extends StatelessWidget {
  const StarTotalChip({super.key, required this.earned, required this.levelCount});

  final int earned;
  final int levelCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Chip(
        avatar: const Icon(Icons.star_rounded, color: _starColor, size: 20),
        label: Text('$earned / ${levelCount * LevelRules.maxStars}'),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Result-screen summary of a level round: stars, new best, what unlocked,
/// and what accuracy the next star needs.
class LevelResultBanner extends StatelessWidget {
  const LevelResultBanner({super.key, required this.outcome, this.nextStarHint});

  final LevelOutcome outcome;

  /// Overrides the default accuracy-based "how to earn the next star" text,
  /// for modes graded another way (moves, checks). Null hides the hint.
  final String? Function(int stars)? nextStarHint;

  String? get _nextStarHint => nextStarHint != null
      ? nextStarHint!(outcome.stars)
      : switch (outcome.stars) {
          0 => 'Get ${(LevelRules.oneStar * 100).round()}% right to pass and unlock the next level.',
          1 => 'Get ${(LevelRules.twoStars * 100).round()}% right for 2 stars.',
          2 => 'Get every answer right for 3 stars.',
          _ => null,
        };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _nextStarHint;
    return Column(
      children: [
        StarRow(stars: outcome.stars, size: 48, animate: true),
        const SizedBox(height: 12),
        if (outcome.unlockedLevel != null)
          Text(
            'Level ${outcome.level} cleared! Level ${outcome.unlockedLevel} unlocked 🎉',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.3)
        else if (outcome.isNewBest && outcome.previousBest > 0)
          Text(
            'New best for level ${outcome.level}!',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.3),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
