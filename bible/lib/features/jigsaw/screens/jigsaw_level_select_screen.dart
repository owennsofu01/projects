import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_select_grid.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/jigsaw_content_loader.dart';
import '../models/jigsaw_scene.dart';
import 'jigsaw_play_screen.dart';

class JigsawLevelSelectScreen extends ConsumerWidget {
  const JigsawLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return FutureBuilder<List<JigsawScene>>(
      future: JigsawContentLoader.load(),
      builder: (context, snapshot) {
        final scenes = snapshot.data ?? const <JigsawScene>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bible Jigsaw'),
            actions: [
              if (profile != null && scenes.isNotEmpty)
                StarTotalChip(earned: profile.totalStars(JigsawRules.gameModeId), levelCount: scenes.length),
              const HowToPlayButton(
                title: 'Bible Jigsaw',
                steps: [
                  'Tap a piece, then tap another piece to swap them. Put every piece back to finish the picture.',
                  'Tap the eye to peek at the finished picture.',
                  'Pieces grow from 9 to 64. Up to level 10, a check mark shows when a piece is in place.',
                  'Use as few swaps as you can for more stars. Finishing unlocks the next level.',
                ],
              ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : LevelSelectGrid(
                  gameModeId: JigsawRules.gameModeId,
                  levels: [
                    for (final s in scenes)
                      LevelInfo(level: s.level, title: s.sceneName, subtitle: '${s.pieceCount} pieces'),
                  ],
                  onPlay: (level) => context.push(RoutePaths.jigsawPlay, extra: JigsawPlayArgs(level)),
                ),
        );
      },
    );
  }
}
