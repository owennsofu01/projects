import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/settings_providers.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../../../core/widgets/level_card.dart';
import '../../../core/widgets/level_stars.dart';
import '../data/trivia_content_loader.dart';
import '../models/trivia_question.dart';
import 'trivia_play_screen.dart';

const _levelTitles = [
  'Creation & Beginnings',
  'Noah & the Flood',
  'The Patriarchs',
  'Exodus & Moses',
  'Judges & Kings',
  'The Prophets',
  'Life of Jesus',
  'Miracles & Parables',
  'Acts & the Early Church',
  'Epistles & Revelation',
];

class TriviaLevelSelectScreen extends ConsumerWidget {
  const TriviaLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kidMode = ref.watch(settingsProvider).kidMode;
    final profile = ref.watch(userProfileProvider);
    final unlockedLevel = profile?.unlockedLevel('trivia') ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Trivia'),
        actions: [
          if (profile != null) StarTotalChip(earned: profile.totalStars('trivia'), levelCount: 10),
          TextButton(onPressed: () => context.push(RoutePaths.trivia), child: const Text('Free Play')),
          const HowToPlayButton(
            title: 'Bible Trivia',
            steps: [
              'Pick a level to answer 10 multiple-choice questions, or use Free Play to choose your own category and difficulty.',
              'Tap the answer you think is correct before time runs out.',
              'Get 60% right to earn a star and unlock the next level. 80% earns 2 stars, a perfect round earns 3.',
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<TriviaQuestion>>(
        future: TriviaContentLoader.load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final questions = snapshot.data!;
          if (questions.isEmpty) {
            return const Center(child: Text('No trivia questions available yet.'));
          }
          final byLevel = <int, List<TriviaQuestion>>{};
          for (final q in questions) {
            byLevel.putIfAbsent(q.level, () => []).add(q);
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
              final levelQuestions = byLevel[level]!;
              final title = level <= _levelTitles.length ? _levelTitles[level - 1] : 'Level $level';
              final locked = level > unlockedLevel;
              final stars = profile?.starsFor('trivia', level) ?? 0;

              return LevelCard(
                level: level,
                title: title,
                subtitle: '${levelQuestions.length} questions · ${levelQuestions.first.difficulty.label}',
                locked: locked,
                stars: stars,
                onTap: locked
                    ? () => ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Clear the previous level to unlock this one.')))
                    : () => context.push(
                        RoutePaths.triviaPlay,
                        extra: TriviaPlayArgs(
                          category: 'All',
                          difficulty: levelQuestions.first.difficulty,
                          kidMode: kidMode,
                          level: level,
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
