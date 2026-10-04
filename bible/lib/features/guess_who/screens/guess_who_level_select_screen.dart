import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_card.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/guess_who_content_loader.dart';
import '../models/guess_who_character.dart';
import 'guess_who_play_screen.dart';

const _levelTitles = [
  'The Icons',
  'Well Known',
  'Familiar Faces',
  'Digging Deeper',
  'Supporting Cast',
  'Behind the Scenes',
  'Lesser-Known Figures',
  'Hidden in the Text',
  'Deep Cuts',
  "Scholar's Corner",
  'Genesis Families',
  'Patriarchs & Tribes',
  'Wilderness & Conquest',
  'Judges & Early Kings',
  "David's Court",
  'Kings of Israel & Judah',
  'Exile & Return',
  'Gospel Encounters',
  'The Early Church',
  'Rulers & Rare Names',
];

class GuessWhoLevelSelectScreen extends ConsumerWidget {
  const GuessWhoLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final unlockedLevel = profile?.unlockedLevel('guess_who') ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('"Guess Who" Reveal'),
        actions: [
          if (profile != null) StarTotalChip(earned: profile.totalStars('guess_who'), levelCount: _levelTitles.length),
          HowToPlayButton(
            title: '"Guess Who" Reveal',
            steps: [
              'Pick a level, then read the clues that appear one at a time about a Bible figure.',
              'Type your guess and tap Guess as soon as you think you know who it is.',
              'Guessing right with fewer clues revealed earns a better score.',
              'Get 60% right to earn a star and unlock the next level. 80% earns 2 stars, a perfect round earns 3.',
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<GuessWhoCharacter>>(
        future: GuessWhoContentLoader.load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final characters = snapshot.data!;
          if (characters.isEmpty) {
            return const Center(child: Text('No characters available yet.'));
          }
          final byLevel = <int, List<GuessWhoCharacter>>{};
          for (final c in characters) {
            byLevel.putIfAbsent(c.level, () => []).add(c);
          }
          final levels = byLevel.keys.toList()..sort();

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              final levelCharacters = byLevel[level]!;
              final title = level <= _levelTitles.length ? _levelTitles[level - 1] : 'Level $level';
              final locked = level > unlockedLevel;
              final stars = profile?.starsFor('guess_who', level) ?? 0;

              return LevelCard(
                level: level,
                title: title,
                subtitle: '${levelCharacters.length} characters',
                locked: locked,
                stars: stars,
                onTap: locked
                    ? () => ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Clear the previous level to unlock this one.')))
                    : () => context.push(RoutePaths.guessWhoPlay, extra: GuessWhoPlayArgs(level: level)),
              );
            },
          );
        },
      ),
    );
  }
}
