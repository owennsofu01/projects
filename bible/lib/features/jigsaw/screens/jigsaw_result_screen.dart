import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/game_result.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/level_complete_screen.dart';
import '../../../core/widgets/stat_pill.dart';
import '../data/jigsaw_content_loader.dart';
import '../models/jigsaw_scene.dart';
import '../providers/jigsaw_session_provider.dart';
import '../widgets/scene_art.dart';
import 'jigsaw_play_screen.dart';

class JigsawResultScreen extends StatelessWidget {
  const JigsawResultScreen({super.key, required this.state});

  final JigsawState state;

  @override
  Widget build(BuildContext context) {
    final scene = state.scene!;
    final pieces = state.order.length;
    return FutureBuilder<List<JigsawScene>>(
      future: JigsawContentLoader.load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return LevelCompleteScreen(
          result: GameResult(
            gameModeId: JigsawRules.gameModeId,
            score: pieces * 10,
            correctCount: pieces,
            totalCount: pieces,
            difficulty: 'level_${scene.level}',
          ),
          level: scene.level,
          stars: JigsawRules.starsFor(moves: state.moves, minimumMoves: state.minimumMoves, pieceCount: pieces),
          headline: '${scene.sceneName} pieced together!',
          stats: [
            StatPill(icon: Icons.touch_app_outlined, label: 'Swaps', value: '${state.moves}'),
            StatPill(icon: Icons.bolt_outlined, label: 'Fewest possible', value: '${state.minimumMoves}'),
          ],
          levelCount: snapshot.data!.length,
          levelsRoute: RoutePaths.jigsaw,
          nextStarHint: (stars) =>
              stars >= 3 ? null : 'Use fewer extra swaps for more stars — peek at the picture to plan.',
          footer: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: state.cols / state.rows,
                  child: CustomPaint(painter: SceneArtPainter(scene.art)),
                ),
              ),
              const SizedBox(height: 8),
              Text(scene.reference, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          onPlayLevel: (context, level) => context.pushReplacement(RoutePaths.jigsawPlay, extra: JigsawPlayArgs(level)),
        );
      },
    );
  }
}
