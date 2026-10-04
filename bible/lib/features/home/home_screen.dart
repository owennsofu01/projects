import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/game_mode_registry.dart';
import '../../core/progress/progress_providers.dart';
import '../../core/widgets/game_card.dart';
import '../bible_reader/providers/bible_reader_provider.dart';
import '../compete/widgets/daily_challenge_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final verseAsync = ref.watch(verseOfTheDayProvider);
    final theme = Theme.of(context);

    // 2 columns fits phones; wider layouts (tablets, foldables, web) get
    // more columns instead of stretching cards or leaving dead space.
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);

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
                    verseAsync.when(
                      loading: () => SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.secondary),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (verse) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('"${verse.$1}"', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('— ${verse.$2}', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverToBoxAdapter(child: DailyChallengeCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final mode = GameModeRegistry.all[index];
                return GameCard(mode: mode, onTap: () => context.push(mode.routePath));
              }, childCount: GameModeRegistry.all.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
