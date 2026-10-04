import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/progress/tiered_levels.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_select_grid.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/verse_reference_match_levels.dart';
import 'verse_reference_match_play_screen.dart';

class VerseReferenceMatchLevelSelectScreen extends ConsumerWidget {
  const VerseReferenceMatchLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    const id = VerseReferenceMatchLevels.gameModeId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verse-to-Reference Match'),
        actions: [
          if (profile != null) StarTotalChip(earned: profile.totalStars(id), levelCount: TieredLevels.levelCount),
          HowToPlayButton(
            title: 'Verse-to-Reference Match',
            steps: [
              'Each level has ${TieredLevels.questionsPerLevel} verses. Read each one and tap the book, chapter and verse it comes from.',
              'Get ${TieredLevels.percent(TieredLevels.oneStar)} right to pass and unlock the next level. '
                  '${TieredLevels.percent(TieredLevels.twoStars)} earns 2 stars, a perfect round earns 3.',
              "Didn't pass? Try again — you'll get different verses.",
              'Higher levels use less familiar verses, and the wrong answers get closer: '
                  'the same part of the Bible from level 11, then the same book and nearby verses from level 21.',
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
              subtitle: '${TieredLevels.questionsPerLevel} verses · ${TieredLevels.choiceCountFor(level)} choices',
            ),
        ],
        onPlay: (level) => context.push(RoutePaths.verseReferenceMatchPlay, extra: VerseReferenceMatchPlayArgs(level)),
      ),
    );
  }
}
