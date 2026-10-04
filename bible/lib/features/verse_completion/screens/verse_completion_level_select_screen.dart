import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/progress/tiered_levels.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_select_grid.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/verse_completion_levels.dart';
import 'verse_completion_play_screen.dart';

class VerseCompletionLevelSelectScreen extends ConsumerWidget {
  const VerseCompletionLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    const id = VerseCompletionLevels.gameModeId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verse Completion'),
        actions: [
          if (profile != null) StarTotalChip(earned: profile.totalStars(id), levelCount: TieredLevels.levelCount),
          HowToPlayButton(
            title: 'Verse Completion',
            steps: [
              'Each level has ${TieredLevels.questionsPerLevel} verses with a missing word or phrase. '
                  'Tap the choice that completes it.',
              'Get ${(TieredLevels.oneStar * 100).round()}% right to pass and unlock the next level. '
                  '${(TieredLevels.twoStars * 100).round()}% earns 2 stars, a perfect round earns 3.',
              "Didn't pass? Try again — you'll get different verses.",
              'Verses get less familiar every 5 levels, and you get more choices from level 11 and 21.',
            ],
          ),
        ],
      ),
      body: LevelSelectGrid(
        gameModeId: id,
        levels: [
          for (var level = 1; level <= TieredLevels.levelCount; level++)
            LevelInfo(
              level: level,
              title: TieredLevels.titleFor(level),
              subtitle:
                  '${TieredLevels.questionsPerLevel} verses · '
                  '${TieredLevels.choiceCountFor(level)} choices',
            ),
        ],
        onPlay: (level) => context.push(RoutePaths.verseCompletionPlay, extra: VerseCompletionPlayArgs(level)),
      ),
    );
  }
}
