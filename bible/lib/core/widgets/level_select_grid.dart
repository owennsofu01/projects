import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../progress/progress_providers.dart';
import 'level_card.dart';

class LevelInfo {
  const LevelInfo({required this.level, required this.title, required this.subtitle});

  final int level;
  final String title;
  final String subtitle;
}

/// The level grid every leveled game mode shows: stars, locks, and the
/// shared unlock rule, driven by [gameModeId]'s progress in the profile.
class LevelSelectGrid extends ConsumerWidget {
  const LevelSelectGrid({super.key, required this.gameModeId, required this.levels, required this.onPlay});

  final String gameModeId;
  final List<LevelInfo> levels;
  final void Function(int level) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final unlockedLevel = profile?.unlockedLevel(gameModeId) ?? 1;

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final info = levels[index];
        final locked = info.level > unlockedLevel;
        return LevelCard(
          level: info.level,
          title: info.title,
          subtitle: info.subtitle,
          locked: locked,
          stars: profile?.starsFor(gameModeId, info.level) ?? 0,
          onTap: locked
              ? () => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Earn a star on the previous level to unlock this one.')))
              : () => onPlay(info.level),
        );
      },
    );
  }
}
