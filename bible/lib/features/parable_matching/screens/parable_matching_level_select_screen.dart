import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_select_grid.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/parable_matching_content_loader.dart';
import '../models/parable.dart';

class ParableMatchingLevelSelectScreen extends ConsumerWidget {
  const ParableMatchingLevelSelectScreen({super.key});

  static String _subtitle(ParableLevel level) => switch (level.match) {
    ParableMatchType.lesson => 'Match the lessons',
    ParableMatchType.detail => 'Match the story moments',
    ParableMatchType.reference => 'Match the references',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return FutureBuilder<ParableContent>(
      future: ParableMatchingContentLoader.load(),
      builder: (context, snapshot) {
        final levels = snapshot.data?.levels ?? const <ParableLevel>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Parable Matching'),
            actions: [
              if (profile != null && levels.isNotEmpty)
                StarTotalChip(earned: profile.totalStars('parable_matching'), levelCount: levels.length),
              const HowToPlayButton(
                title: 'Parable Matching',
                steps: [
                  'Match parables of Jesus to their lesson, a moment from the story, or where they are found in Scripture.',
                  'Levels 1–10 have 6 parables. Levels 11–20 have 8, grouped so they are easier to mix up.',
                  'A perfect round earns 3 stars and one mistake earns 2. You can pass with two mistakes, or three on the 8-parable levels.',
                  'Earn at least one star to unlock the next level.',
                ],
              ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : LevelSelectGrid(
                  gameModeId: 'parable_matching',
                  levels: [for (final l in levels) LevelInfo(level: l.level, title: l.title, subtitle: _subtitle(l))],
                  onPlay: (level) => context.push(RoutePaths.parableMatchingPlay, extra: level),
                ),
        );
      },
    );
  }
}
