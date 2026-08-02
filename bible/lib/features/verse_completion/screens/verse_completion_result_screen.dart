import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/game_result.dart';
import '../../../core/progress/progress_providers.dart';
import '../../../core/widgets/stat_pill.dart';
import '../providers/verse_completion_session_provider.dart';

class VerseCompletionResultScreen extends ConsumerStatefulWidget {
  const VerseCompletionResultScreen({super.key, required this.state});

  final VerseCompletionState state;

  @override
  ConsumerState<VerseCompletionResultScreen> createState() => _VerseCompletionResultScreenState();
}

class _VerseCompletionResultScreenState extends ConsumerState<VerseCompletionResultScreen> {
  bool _recorded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(userProfileProvider.notifier).recordGameResult(GameResult(
              gameModeId: 'verse_completion',
              score: widget.state.score,
              correctCount: widget.state.correctCount,
              totalCount: widget.state.totalCount,
              difficulty: widget.state.items.first.difficulty.name,
            ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final badges = ref.watch(lastEarnedBadgesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Round complete')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 16),
            Text('${state.correctCount} / ${state.totalCount} correct',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            StatPill(icon: Icons.stars_outlined, label: 'Score', value: '${state.score}'),
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
