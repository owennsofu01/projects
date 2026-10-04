import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_card.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/hangman_content_loader.dart';
import '../models/hangman_word.dart';
import 'hangman_play_screen.dart';

const _levelTitles = [
  'First Names',
  'Familiar Faces',
  'Places & Terms',
  'Cities & Concepts',
  'Empires & Events',
  'Distant Towns',
  'Kings & Leaders',
  'Ancient Sites',
  'Minor Figures',
  'Deep Cuts',
];

class HangmanLevelSelectScreen extends ConsumerWidget {
  const HangmanLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final unlockedLevel = profile?.unlockedLevel('hangman') ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hangman'),
        actions: [
          if (profile != null) StarTotalChip(earned: profile.totalStars('hangman'), levelCount: 10),
          HowToPlayButton(
            title: 'Hangman',
            steps: [
              'Pick a level, then read the hint for the hidden Bible name or place.',
              'Tap letters to guess the word — correct guesses fill in the blanks.',
              'You can miss up to 6 times before the word is revealed and the round ends.',
              'Get 60% right to earn a star and unlock the next level. 80% earns 2 stars, a perfect round earns 3.',
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<HangmanWord>>(
        future: HangmanContentLoader.load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final words = snapshot.data!;
          if (words.isEmpty) {
            return const Center(child: Text('No words available yet.'));
          }
          final byLevel = <int, List<HangmanWord>>{};
          for (final w in words) {
            byLevel.putIfAbsent(w.level, () => []).add(w);
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
              final levelWords = byLevel[level]!;
              final title = level <= _levelTitles.length ? _levelTitles[level - 1] : 'Level $level';
              final locked = level > unlockedLevel;
              final stars = profile?.starsFor('hangman', level) ?? 0;

              return LevelCard(
                level: level,
                title: title,
                subtitle: '${levelWords.length} words',
                locked: locked,
                stars: stars,
                onTap: locked
                    ? () => ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Clear the previous level to unlock this one.')))
                    : () => context.push(RoutePaths.hangmanPlay, extra: HangmanPlayArgs(level: level)),
              );
            },
          );
        },
      ),
    );
  }
}
