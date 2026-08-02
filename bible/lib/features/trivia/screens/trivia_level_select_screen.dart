import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/settings_providers.dart';
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
    final unlockedLevel = ref.watch(userProfileProvider)?.triviaUnlockedLevel ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Trivia'),
        actions: [
          TextButton(
            onPressed: () => context.push(RoutePaths.trivia),
            child: const Text('Free Play'),
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
              childAspectRatio: 1.05,
            ),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              final levelQuestions = byLevel[level]!;
              final title = level <= _levelTitles.length ? _levelTitles[level - 1] : 'Level $level';
              final locked = level > unlockedLevel;
              final cleared = level < unlockedLevel;

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: locked
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Clear the previous level to unlock this one.')),
                          )
                      : () => context.push(
                            RoutePaths.triviaPlay,
                            extra: TriviaPlayArgs(
                              category: 'All',
                              difficulty: levelQuestions.first.difficulty,
                              kidMode: kidMode,
                              level: level,
                            ),
                          ),
                  child: Opacity(
                    opacity: locked ? 0.5 : 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  locked
                                      ? Icons.lock_outline
                                      : cleared
                                          ? Icons.check_circle_outline
                                          : Icons.play_circle_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text('Lvl $level', style: Theme.of(context).textTheme.labelLarge),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(title, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${levelQuestions.length} questions · ${levelQuestions.first.difficulty.label}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
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
