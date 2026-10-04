import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../providers/timeline_puzzle_session_provider.dart';
import 'timeline_puzzle_result_screen.dart';

class TimelinePuzzlePlayScreen extends ConsumerWidget {
  const TimelinePuzzlePlayScreen({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelinePuzzleSessionProvider(level));
    final notifier = ref.read(timelinePuzzleSessionProvider(level).notifier);
    final accent = AppColors.accentFor('timeline_puzzle');

    if (state.status == TimelinePuzzleStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.order.isEmpty) {
      return const Scaffold(body: Center(child: Text('No timeline events yet.')));
    }
    if (state.status == TimelinePuzzleStatus.finished) {
      return TimelinePuzzleResultScreen(state: state, level: level);
    }

    final hasCheckedThisArrangement = state.correctIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Level $level · ${state.level?.title ?? 'Timeline'}'),
        actions: [
          HowToPlayButton(
            title: 'Timeline Puzzle',
            steps: [
              'Drag the events into the order you think they happened.',
              'Tap Check Order to see which ones are right.',
              'Keep rearranging the incorrect ones until the whole timeline is correct. Each event shows its Bible reference once it is in the right place.',
              'Solve it on the first check for 3 stars, the second for 2, later for 1.',
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Drag the events into the order they happened, then tap Check.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          if (state.checks > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${state.correctIds.length} / ${state.totalCount} in the right place · attempt ${state.checks}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              itemCount: state.order.length,
              onReorder: notifier.reorder,
              itemBuilder: (context, index) {
                final item = state.order[index];
                final isCorrect = hasCheckedThisArrangement && state.correctIds.contains(item.id);
                final isWrong = hasCheckedThisArrangement && !state.correctIds.contains(item.id);

                return Card(
                  key: ValueKey(item.id),
                  color: isCorrect
                      ? Colors.green.withValues(alpha: 0.15)
                      : isWrong
                      ? Colors.red.withValues(alpha: 0.08)
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: accent.withValues(alpha: 0.15),
                      foregroundColor: accent,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(item.event),
                    // The reference would give the order away, so it only
                    // appears once the event is in the right place.
                    subtitle: isCorrect ? Text(item.reference) : null,
                    trailing: isCorrect
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.drag_handle),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: accent),
                onPressed: notifier.checkOrder,
                icon: const Icon(Icons.checklist),
                label: const Text('Check Order'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
