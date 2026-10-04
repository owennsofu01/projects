import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/game_result.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/level_complete_screen.dart';
import '../../../core/widgets/stat_pill.dart';
import '../data/crossword_levels.dart';
import '../providers/crossword_session_provider.dart';
import 'crossword_play_screen.dart';

class CrosswordResultScreen extends StatelessWidget {
  const CrosswordResultScreen({super.key, required this.state, required this.level});

  final CrosswordState state;
  final int level;

  @override
  Widget build(BuildContext context) {
    final total = state.grid!.placements.length;
    return LevelCompleteScreen(
      result: GameResult(
        gameModeId: CrosswordLevels.gameModeId,
        score: total * 10,
        correctCount: total,
        totalCount: total,
        difficulty: 'level_$level',
      ),
      level: level,
      stars: CrosswordLevels.starsFor(hintsUsed: state.hintsUsed),
      headline: 'All $total clues solved!',
      stats: [
        StatPill(icon: Icons.stars_outlined, label: 'Score', value: '${total * 10}'),
        StatPill(icon: Icons.lightbulb_outline, label: 'Reveals', value: '${state.hintsUsed}'),
      ],
      levelCount: CrosswordLevels.levelCount,
      levelsRoute: RoutePaths.crossword,
      nextStarHint: CrosswordLevels.nextStarHint,
      onPlayLevel: (context, level) =>
          context.pushReplacement(RoutePaths.crosswordPlay, extra: CrosswordPlayArgs(level)),
    );
  }
}
