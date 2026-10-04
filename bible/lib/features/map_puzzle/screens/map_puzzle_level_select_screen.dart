import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_select_grid.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/map_puzzle_content_loader.dart';
import '../models/map_location.dart';

class MapPuzzleLevelSelectScreen extends ConsumerWidget {
  const MapPuzzleLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return FutureBuilder<List<MapLevel>>(
      future: MapPuzzleContentLoader.loadLevels(),
      builder: (context, snapshot) {
        final levels = snapshot.data ?? const <MapLevel>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bible Map Puzzle'),
            actions: [
              if (profile != null && levels.isNotEmpty)
                StarTotalChip(earned: profile.totalStars('map_puzzle'), levelCount: levels.length),
              const HowToPlayButton(
                title: 'Bible Map Puzzle',
                steps: [
                  'Each level shows a real map of a Bible region and asks you to find 10 places.',
                  'Tap where you think each place is; pinch to zoom for small towns.',
                  'Find 6 for a star and to unlock the next level, 8 for 2 stars, all 10 for 3.',
                ],
              ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : LevelSelectGrid(
                  gameModeId: 'map_puzzle',
                  levels: [
                    for (final l in levels)
                      LevelInfo(level: l.level, title: l.title, subtitle: '${l.locations.length} places'),
                  ],
                  onPlay: (level) => context.push(RoutePaths.mapPuzzlePlay, extra: level),
                ),
        );
      },
    );
  }
}
