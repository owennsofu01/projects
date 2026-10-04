import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/match3_session_provider.dart';
import 'match3_result_screen.dart';

// One per tile kind, up to match3MaxKinds.
const _tileIcons = [Icons.star, Icons.favorite, Icons.water_drop, Icons.wb_sunny, Icons.local_florist, Icons.diamond];
const _tileColors = [Colors.amber, Colors.pinkAccent, Colors.lightBlue, Colors.deepOrange, Colors.green, Colors.purple];

class Match3PlayArgs {
  /// Each args instance is a fresh attempt, so a retry starts a new board.
  Match3PlayArgs(this.levelId) : attempt = DateTime.now().microsecondsSinceEpoch;

  final String levelId;
  final int attempt;

  Match3Round get round => (levelId: levelId, attempt: attempt);
}

class Match3PlayScreen extends ConsumerWidget {
  const Match3PlayScreen({super.key, required this.args});

  final Match3PlayArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(match3SessionProvider(args.round));
    final notifier = ref.read(match3SessionProvider(args.round).notifier);
    final accent = AppColors.accentFor('match3');

    if (state.status == Match3Status.loading || state.level == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.status == Match3Status.finished) {
      return Match3ResultScreen(state: state);
    }

    final level = state.level!;
    final progress = (state.score / level.targetScore).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text('Level ${level.levelNumber}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score: ${state.score} / ${level.targetScore}', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  'Moves left: ${state.movesLeft}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: state.movesLeft <= 3 ? Theme.of(context).colorScheme.error : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: accent,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: match3Cols / match3Rows,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: match3Cols,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: state.grid.length,
                    itemBuilder: (context, index) {
                      final kind = state.grid[index];
                      final isSelected = state.selectedIndex == index;
                      return InkWell(
                        onTap: () => notifier.selectTile(index),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: _tileColors[kind].withValues(alpha: isSelected ? 0.35 : 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected ? Border.all(color: accent, width: 2) : null,
                          ),
                          child: Icon(_tileIcons[kind], color: _tileColors[kind]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
