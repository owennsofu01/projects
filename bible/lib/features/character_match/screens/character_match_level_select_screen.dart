import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_select_grid.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/character_match_content_loader.dart';
import '../models/character_match_pair.dart';

class CharacterMatchLevelSelectScreen extends ConsumerWidget {
  const CharacterMatchLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return FutureBuilder<List<CharacterMatchLevel>>(
      future: CharacterMatchContentLoader.load(),
      builder: (context, snapshot) {
        final levels = snapshot.data ?? const <CharacterMatchLevel>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Character Match'),
            actions: [
              if (profile != null && levels.isNotEmpty)
                StarTotalChip(earned: profile.totalStars('character_match'), levelCount: levels.length),
              const HowToPlayButton(
                title: 'Character Match',
                steps: [
                  "Flip two cards at a time to pair each Bible figure's name with their defining moment.",
                  'Levels grow from 4 pairs to 8, with lesser-known figures as you go.',
                  'Finish with no more misses than pairs for 3 stars, up to twice as many for 2. Finishing unlocks the next level.',
                ],
              ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : LevelSelectGrid(
                  gameModeId: 'character_match',
                  levels: [
                    for (final l in levels)
                      LevelInfo(level: l.level, title: l.title, subtitle: '${l.characters.length} pairs'),
                  ],
                  onPlay: (level) => context.push(RoutePaths.characterMatchPlay, extra: level),
                ),
        );
      },
    );
  }
}
