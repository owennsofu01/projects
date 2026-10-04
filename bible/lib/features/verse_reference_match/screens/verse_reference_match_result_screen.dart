import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/tiered_level_result_screen.dart';
import '../data/verse_reference_match_levels.dart';
import '../providers/verse_reference_match_session_provider.dart';
import 'verse_reference_match_play_screen.dart';

class VerseReferenceMatchResultScreen extends StatelessWidget {
  const VerseReferenceMatchResultScreen({super.key, required this.state, required this.level});

  final VerseReferenceMatchState state;
  final int level;

  @override
  Widget build(BuildContext context) => TieredLevelResultScreen(
    gameModeId: VerseReferenceMatchLevels.gameModeId,
    level: level,
    score: state.score,
    correctCount: state.correctCount,
    totalCount: state.totalCount,
    levelsRoute: RoutePaths.verseReferenceMatch,
    onPlayLevel: (context, level) =>
        context.pushReplacement(RoutePaths.verseReferenceMatchPlay, extra: VerseReferenceMatchPlayArgs(level)),
  );
}
