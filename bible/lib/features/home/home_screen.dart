import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/game_mode_registry.dart';
import '../../core/constants/verse_of_the_day.dart';
import '../../core/progress/progress_providers.dart';
import '../../core/widgets/game_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final verse = VerseOfTheDay.forDate(DateTime.now());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible GameHive'),
        actions: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 18),
                    const SizedBox(width: 4),
                    Text('${profile.currentStreak}'),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verse of the Day', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Text('"${verse.$1}"', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('— ${verse.$2}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final mode = GameModeRegistry.all[index];
                  return GameCard(mode: mode, onTap: () => context.push(mode.routePath));
                },
                childCount: GameModeRegistry.all.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
