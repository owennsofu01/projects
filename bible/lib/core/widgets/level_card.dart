import 'package:flutter/material.dart';

import 'level_stars.dart';

/// Shared level-select tile used by every leveled game mode (Trivia, Guess
/// Who, Hangman, ...) so the locked/cleared/playable layout — and its
/// overflow guards — only need to be gotten right once.
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.locked,
    required this.stars,
    required this.onTap,
  });

  final int level;
  final String title;
  final String subtitle;
  final bool locked;

  /// Best stars earned (0 = not yet passed).
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: locked ? 0.5 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            // Clamp text scaling within the card itself: on Android, OEM
            // "font size" accessibility settings routinely exceed 1.3x,
            // which is enough to push a wrapped title/subtitle past a
            // fixed-aspect-ratio grid cell no matter how the layout is
            // tuned — the same failure mode the home hub's GameCard hit.
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          locked
                              ? Icons.lock_outline
                              : stars > 0
                              ? Icons.check_circle_outline
                              : Icons.play_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text('Lvl $level', style: Theme.of(context).textTheme.labelLarge),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!locked) ...[const SizedBox(height: 8), StarRow(stars: stars, size: 18)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
