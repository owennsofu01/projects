import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_select_grid.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/crossword_content_loader.dart';
import '../data/crossword_levels.dart';
import '../models/crossword_puzzle.dart';
import 'crossword_play_screen.dart';

class CrosswordLevelSelectScreen extends ConsumerWidget {
  const CrosswordLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return FutureBuilder<List<CrosswordPuzzle>>(
      future: CrosswordContentLoader.load(),
      builder: (context, snapshot) {
        final puzzles = CrosswordLevels.ordered(snapshot.data ?? const []);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bible Crossword'),
            actions: [
              if (profile != null && puzzles.isNotEmpty)
                StarTotalChip(earned: profile.totalStars(CrosswordLevels.gameModeId), levelCount: puzzles.length),
              const HowToPlayButton(
                title: 'Bible Crossword',
                steps: [
                  'Tap a cell to select a word, then type letters using your keyboard.',
                  'Tap a clue in the Across or Down list to jump straight to it.',
                  'Stuck? Tap Reveal to fill in the right letter — but each reveal costs stars.',
                  'Solve it with no reveals for 3 stars, or up to 2 reveals for 2. Solving unlocks the next level.',
                ],
              ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : LevelSelectGrid(
                  gameModeId: CrosswordLevels.gameModeId,
                  levels: [
                    for (final (i, p) in puzzles.indexed)
                      LevelInfo(
                        level: i + 1,
                        title: p.theme,
                        subtitle: '${p.entries.length} clues · ${p.difficulty.label}',
                      ),
                  ],
                  onPlay: (level) => context.push(RoutePaths.crosswordPlay, extra: CrosswordPlayArgs(level)),
                ),
        );
      },
    );
  }
}
