import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_select_grid.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/word_search_content_loader.dart';
import '../data/word_search_levels.dart';
import '../models/word_search_puzzle.dart';
import 'word_search_play_screen.dart';

class WordSearchLevelSelectScreen extends ConsumerWidget {
  const WordSearchLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return FutureBuilder<List<WordSearchPuzzle>>(
      future: WordSearchContentLoader.load(),
      builder: (context, snapshot) {
        final puzzles = WordSearchLevels.ordered(snapshot.data ?? const []);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Word Search'),
            actions: [
              if (profile != null && puzzles.isNotEmpty)
                StarTotalChip(earned: profile.totalStars(WordSearchLevels.gameModeId), levelCount: puzzles.length),
              const HowToPlayButton(
                title: 'Word Search',
                steps: [
                  'Drag across the letters to select a hidden word; it highlights when found.',
                  'Find every word to clear the level and unlock the next one.',
                  'Grids grow every 5 levels, and words start running diagonally, then backwards, then every direction.',
                  'Be quick for more stars: average 40 seconds a word for 2 stars, 20 seconds for 3.',
                ],
              ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : LevelSelectGrid(
                  gameModeId: WordSearchLevels.gameModeId,
                  levels: [
                    for (final (i, p) in puzzles.indexed)
                      LevelInfo(
                        level: i + 1,
                        title: p.theme,
                        subtitle: '${p.words.length} words · ${WordSearchLevels.directionsLabel(i + 1)}',
                      ),
                  ],
                  onPlay: (level) => context.push(RoutePaths.wordSearchPlay, extra: WordSearchPlayArgs(level)),
                ),
        );
      },
    );
  }
}
