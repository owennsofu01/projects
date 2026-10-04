import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_select_grid.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/timeline_puzzle_content_loader.dart';
import '../models/timeline_event.dart';

class TimelinePuzzleLevelSelectScreen extends ConsumerWidget {
  const TimelinePuzzleLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return FutureBuilder<List<TimelineLevel>>(
      future: TimelinePuzzleContentLoader.load(),
      builder: (context, snapshot) {
        final levels = snapshot.data ?? const <TimelineLevel>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Timeline Puzzle'),
            actions: [
              if (profile != null && levels.isNotEmpty)
                StarTotalChip(earned: profile.totalStars('timeline_puzzle'), levelCount: levels.length),
              const HowToPlayButton(
                title: 'Timeline Puzzle',
                steps: [
                  'Each level covers one era of the Bible story, from Creation to the early church.',
                  'Drag the events into the order they happened, then tap Check Order.',
                  'Solve it on the first check for 3 stars, the second for 2, later for 1. Finishing unlocks the next level.',
                ],
              ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : LevelSelectGrid(
                  gameModeId: 'timeline_puzzle',
                  levels: [
                    for (final l in levels)
                      LevelInfo(level: l.level, title: l.title, subtitle: '${l.events.length} events'),
                  ],
                  onPlay: (level) => context.push(RoutePaths.timelinePuzzlePlay, extra: level),
                ),
        );
      },
    );
  }
}
