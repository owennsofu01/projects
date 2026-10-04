import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/jigsaw_scene.dart';
import '../providers/jigsaw_session_provider.dart';
import '../widgets/scene_art.dart';
import 'jigsaw_result_screen.dart';

class JigsawPlayArgs {
  /// Each args instance is a fresh attempt with a new shuffle.
  JigsawPlayArgs(this.level) : attempt = DateTime.now().microsecondsSinceEpoch;

  final int level;
  final int attempt;

  JigsawRound get round => (level: level, attempt: attempt);
}

class JigsawPlayScreen extends ConsumerWidget {
  const JigsawPlayScreen({super.key, required this.args});

  final JigsawPlayArgs args;

  void _peek(BuildContext context, JigsawScene scene, double aspectRatio) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: CustomPaint(painter: SceneArtPainter(scene.art)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('${scene.sceneName} · ${scene.reference}', textAlign: TextAlign.center),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jigsawSessionProvider(args.round));
    final notifier = ref.read(jigsawSessionProvider(args.round).notifier);
    final accent = AppColors.accentFor('jigsaw');

    if (state.status == JigsawStatus.loading || state.scene == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.status == JigsawStatus.finished) {
      return JigsawResultScreen(state: state);
    }

    final scene = state.scene!;
    final showChecks = scene.level <= JigsawRules.lastLevelWithChecks;
    // Square pieces keep the picture undistorted at any grid shape.
    final aspectRatio = state.cols / state.rows;

    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${scene.level} · ${scene.sceneName}'),
        actions: [
          IconButton(
            tooltip: 'Peek at the picture',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => _peek(context, scene, aspectRatio),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Swaps: ${state.moves}  ·  ${state.order.length} pieces',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                showChecks
                    ? 'Tap two pieces to swap them. A check mark means a piece is in the right spot.'
                    : 'Tap two pieces to swap them. No check marks from here on — tap the eye to peek.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: state.cols,
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                      ),
                      itemCount: state.order.length,
                      itemBuilder: (context, slot) {
                        final targetIndex = state.order[slot];
                        final isSelected = state.selectedIndex == slot;
                        final isCorrect = targetIndex == slot;

                        return GestureDetector(
                          onTap: () => notifier.selectTile(slot),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(
                                painter: SceneArtPainter(
                                  scene.art,
                                  rows: state.rows,
                                  cols: state.cols,
                                  piece: targetIndex,
                                ),
                              ),
                              if (isSelected)
                                DecoratedBox(
                                  decoration: BoxDecoration(border: Border.all(color: accent, width: 3)),
                                ),
                              if (showChecks && isCorrect)
                                const Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.check_circle, color: Colors.white, size: 14),
                                  ),
                                ),
                            ],
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
      ),
    );
  }
}
