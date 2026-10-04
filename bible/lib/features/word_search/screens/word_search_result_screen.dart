import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/game_result.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/level_complete_screen.dart';
import '../../../core/widgets/stat_pill.dart';
import '../data/word_search_levels.dart';
import '../providers/word_search_session_provider.dart';
import 'word_search_play_screen.dart';

class WordSearchResultScreen extends StatelessWidget {
  const WordSearchResultScreen({super.key, required this.state, required this.level});

  final WordSearchState state;
  final int level;

  @override
  Widget build(BuildContext context) {
    final words = state.grid!.placements.length;
    final seconds = state.elapsed.inSeconds;
    return LevelCompleteScreen(
      result: GameResult(
        gameModeId: WordSearchLevels.gameModeId,
        score: words * 10,
        correctCount: words,
        totalCount: words,
        difficulty: 'level_$level',
      ),
      level: level,
      stars: WordSearchLevels.starsFor(elapsed: state.elapsed, wordCount: words),
      headline: 'All $words words found!',
      stats: [
        StatPill(icon: Icons.stars_outlined, label: 'Score', value: '${words * 10}'),
        StatPill(
          icon: Icons.timer_outlined,
          label: 'Time',
          value: '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
        ),
      ],
      levelCount: WordSearchLevels.levelCount,
      levelsRoute: RoutePaths.wordSearch,
      nextStarHint: WordSearchLevels.nextStarHint,
      onPlayLevel: (context, level) =>
          context.pushReplacement(RoutePaths.wordSearchPlay, extra: WordSearchPlayArgs(level)),
    );
  }
}
