import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../models/map_location.dart';
import '../providers/map_puzzle_session_provider.dart';
import '../widgets/bible_map_painter.dart';
import 'map_puzzle_result_screen.dart';

class MapPuzzlePlayScreen extends ConsumerWidget {
  const MapPuzzlePlayScreen({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapPuzzleSessionProvider(level));
    final notifier = ref.read(mapPuzzleSessionProvider(level).notifier);
    final accent = AppColors.accentFor('map_puzzle');
    final theme = Theme.of(context);

    if (state.status == MapPuzzleStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mapLevel = state.level;
    final geography = state.geography;
    if (mapLevel == null || geography == null || state.locations.isEmpty) {
      return const Scaffold(body: Center(child: Text('No locations to find yet.')));
    }
    if (state.status == MapPuzzleStatus.finished) {
      return MapPuzzleResultScreen(state: state, level: level);
    }

    final target = state.currentLocation!;
    final isAnswered = state.status == MapPuzzleStatus.answered;

    return Scaffold(
      appBar: AppBar(
        title: Text('Level $level · ${state.currentIndex + 1} of ${state.totalCount}'),
        actions: const [
          HowToPlayButton(
            title: 'Bible Map Puzzle',
            steps: [
              'Read the place and its clue, then tap where you think it is on the map.',
              'Pinch to zoom in for small towns. Your tap must land closer to the right place than to any other place in the level.',
              'Find 6 of 10 for a star and to unlock the next level; 8 for 2 stars; all 10 for 3.',
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Find: ${target.name}', style: theme.textTheme.titleLarge)),
                Text('Score ${state.score}', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(target.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isAnswered
                  ? _AnswerBanner(key: ValueKey(target.id), correct: state.wasCorrect, location: target)
                  : Text('Tap the map · pinch to zoom', key: const ValueKey('hint'), style: theme.textTheme.bodySmall),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: mapLevel.region.aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      maxScale: 6,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.biggest;
                          final targetPos = mapLevel.region.project(target.lat, target.lon);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: isAnswered
                                ? null
                                : (details) => notifier.submitTap(
                                    (details.localPosition.dx / size.width).clamp(0.0, 1.0),
                                    (details.localPosition.dy / size.height).clamp(0.0, 1.0),
                                  ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _MapCanvas(region: mapLevel.region, geography: geography),
                                ),
                                if (isAnswered) ...[
                                  if (!state.wasCorrect && state.lastTap != null)
                                    _Marker(
                                      at: Offset(state.lastTap!.dx * size.width, state.lastTap!.dy * size.height),
                                      child: const Icon(Icons.close, color: Colors.red, size: 22),
                                    ),
                                  _Marker(
                                    at: Offset(targetPos.dx * size.width, targetPos.dy * size.height),
                                    anchorBottom: true,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            target.name,
                                            style: const TextStyle(color: Colors.white, fontSize: 11),
                                          ),
                                        ),
                                        const Icon(Icons.location_on, color: Colors.green, size: 30),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(mapLevel.title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: isAnswered
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: notifier.nextLocation,
                  icon: Icon(state.isLastLocation ? Icons.flag_outlined : Icons.arrow_forward),
                  label: Text(state.isLastLocation ? 'Finish' : 'Next Location'),
                )
              : const SizedBox(height: 48),
        ),
      ),
    );
  }
}

class _AnswerBanner extends StatelessWidget {
  const _AnswerBanner({super.key, required this.correct, required this.location});

  final bool correct;
  final MapLocation location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          correct ? Icons.check_circle : Icons.info_outline,
          color: correct ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            correct ? 'Correct!' : 'Not quite. The green pin shows ${location.name}.',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Chip(
          avatar: const Icon(Icons.menu_book_outlined, size: 16),
          label: Text(location.reference),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// Places [child] centred on [at] (or with its bottom edge on [at], for pins).
class _Marker extends StatelessWidget {
  const _Marker({required this.at, required this.child, this.anchorBottom = false});

  final Offset at;
  final Widget child;
  final bool anchorBottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: FractionalTranslation(
        translation: Offset(-0.5, anchorBottom ? -1.0 : -0.5),
        child: IgnorePointer(child: child),
      ),
    );
  }
}

/// Holds one painter per region so its cached paths survive rebuilds.
class _MapCanvas extends StatefulWidget {
  const _MapCanvas({required this.region, required this.geography});

  final MapRegion region;
  final MapGeography geography;

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  BibleMapPainter? _painter;

  @override
  Widget build(BuildContext context) {
    final colors = BibleMapColors.of(context);
    final current = _painter;
    if (current == null ||
        current.region != widget.region ||
        current.geography != widget.geography ||
        current.colors.sea != colors.sea) {
      _painter = BibleMapPainter(region: widget.region, geography: widget.geography, colors: colors);
    }
    return RepaintBoundary(
      child: CustomPaint(painter: _painter, size: Size.infinite),
    );
  }
}
