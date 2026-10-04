import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/tiered_level_result_screen.dart';
import '../data/verse_completion_levels.dart';
import '../providers/verse_completion_session_provider.dart';
import 'verse_completion_play_screen.dart';

class VerseCompletionResultScreen extends StatelessWidget {
  const VerseCompletionResultScreen({super.key, required this.state, required this.level});

  final VerseCompletionState state;
  final int level;

  @override
  Widget build(BuildContext context) => TieredLevelResultScreen(
    gameModeId: VerseCompletionLevels.gameModeId,
    level: level,
    score: state.score,
    correctCount: state.correctCount,
    totalCount: state.totalCount,
    levelsRoute: RoutePaths.verseCompletion,
    onPlayLevel: (context, level) =>
        context.pushReplacement(RoutePaths.verseCompletionPlay, extra: VerseCompletionPlayArgs(level)),
  );
}
