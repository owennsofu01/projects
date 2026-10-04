import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_select_grid.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/match3_content_loader.dart';
import '../models/match3_level.dart';
import 'match3_play_screen.dart';

class Match3LevelSelectScreen extends ConsumerWidget {
  const Match3LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return FutureBuilder<List<Match3Level>>(
      future: Match3ContentLoader.load(),
      builder: (context, snapshot) {
        final levels = snapshot.data ?? const <Match3Level>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Scripture Match-3'),
            actions: [
              if (profile != null && levels.isNotEmpty)
                StarTotalChip(earned: profile.totalStars(Match3Rules.gameModeId), levelCount: levels.length),
              const HowToPlayButton(
                title: 'Scripture Match-3',
                steps: [
                  'Tap a tile, then tap an adjacent tile to swap them.',
                  'Line up 3 or more matching tiles in a row or column to clear them and score points.',
                  'Reach the target score before you run out of moves to win the reward verse and unlock the next level.',
                  'Finish with moves to spare for more stars: 15% for 2 stars, 30% for 3.',
                  'Higher levels set bigger targets, and from level 16 there is a sixth tile, so matches are rarer.',
                ],
              ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : LevelSelectGrid(
                  gameModeId: Match3Rules.gameModeId,
                  levels: [
                    for (final l in levels)
                      LevelInfo(
                        level: l.levelNumber,
                        title: '${l.targetScore} points',
                        subtitle: '${l.moves} moves · ${l.tileKinds} tiles',
                      ),
                  ],
                  onPlay: (level) {
                    final match = levels.firstWhere((l) => l.levelNumber == level);
                    context.push(RoutePaths.match3Play, extra: Match3PlayArgs(match.id));
                  },
                ),
        );
      },
    );
  }
}
