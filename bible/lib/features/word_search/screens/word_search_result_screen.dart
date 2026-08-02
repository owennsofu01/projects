import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/game_result.dart';
import '../../../core/progress/progress_providers.dart';
import '../../../core/widgets/stat_pill.dart';
import '../providers/word_search_session_provider.dart';

class WordSearchResultScreen extends ConsumerStatefulWidget {
  const WordSearchResultScreen({super.key, required this.state});

  final WordSearchState state;

  @override
  ConsumerState<WordSearchResultScreen> createState() => _WordSearchResultScreenState();
}

class _WordSearchResultScreenState extends ConsumerState<WordSearchResultScreen> {
  bool _recorded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final total = widget.state.grid!.placements.length;
        ref.read(userProfileProvider.notifier).recordGameResult(GameResult(
              gameModeId: 'word_search',
              score: widget.state.foundWords.length * 10,
              correctCount: widget.state.foundWords.length,
              totalCount: total,
              difficulty: widget.state.puzzle!.difficulty.name,
            ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final badges = ref.watch(lastEarnedBadgesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle complete')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 16),
            Text('All ${state.foundWords.length} words found!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            StatPill(icon: Icons.stars_outlined, label: 'Score', value: '${state.foundWords.length * 10}'),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('New badge earned!', style: Theme.of(context).textTheme.titleMedium),
              for (final b in badges) Text(b.title),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                ref.read(lastEarnedBadgesProvider.notifier).state = [];
                context.go('/');
              },
              child: const Text('Back to hub'),
            ),
          ],
        ),
      ),
    );
  }
}
