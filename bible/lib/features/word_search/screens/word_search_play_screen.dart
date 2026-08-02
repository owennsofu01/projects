import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/word_search_grid.dart';
import '../providers/word_search_session_provider.dart';
import 'word_search_result_screen.dart';

class WordSearchPlayScreen extends ConsumerStatefulWidget {
  const WordSearchPlayScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  ConsumerState<WordSearchPlayScreen> createState() => _WordSearchPlayScreenState();
}

class _WordSearchPlayScreenState extends ConsumerState<WordSearchPlayScreen> {
  final _gridKey = GlobalKey();
  Cell? _startCell;

  Cell? _cellAt(Offset globalPosition, int size, double cellSize) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(globalPosition);
    final row = (local.dy / cellSize).floor().clamp(0, size - 1);
    final col = (local.dx / cellSize).floor().clamp(0, size - 1);
    return (row, col);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wordSearchSessionProvider(widget.puzzleId));
    final notifier = ref.read(wordSearchSessionProvider(widget.puzzleId).notifier);
    final accent = AppColors.accentFor('word_search');

    if (state.status == WordSearchStatus.loading || state.grid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.status == WordSearchStatus.finished) {
      return WordSearchResultScreen(state: state);
    }

    final grid = state.grid!;

    return Scaffold(
      appBar: AppBar(title: Text(state.puzzle!.theme)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Found ${state.foundWords.length} / ${grid.placements.length}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = constraints.maxWidth / grid.size;
                  return GestureDetector(
                    onPanStart: (details) {
                      final cell = _cellAt(details.globalPosition, grid.size, cellSize);
                      if (cell == null) return;
                      _startCell = cell;
                      notifier.updateSelection(cell, cell);
                    },
                    onPanUpdate: (details) {
                      final start = _startCell;
                      final cell = _cellAt(details.globalPosition, grid.size, cellSize);
                      if (start == null || cell == null) return;
                      notifier.updateSelection(start, cell);
                    },
                    onPanEnd: (_) => notifier.endSelection(),
                    child: Container(
                      key: _gridKey,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: grid.size),
                        itemCount: grid.size * grid.size,
                        itemBuilder: (context, index) {
                          final row = index ~/ grid.size;
                          final col = index % grid.size;
                          final cell = (row, col);
                          final isSelected = state.selection.contains(cell);
                          final isFound = grid.placements.any(
                            (p) => state.foundWords.contains(p.word) && p.cells.contains(cell),
                          );
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isFound
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : isSelected
                                      ? accent.withValues(alpha: 0.35)
                                      : null,
                              border: Border.all(color: Colors.black12, width: 0.5),
                            ),
                            child: Text(
                              grid.letters[row][col],
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: grid.placements
                  .map((p) => Chip(
                        label: Text(p.label),
                        backgroundColor: state.foundWords.contains(p.word)
                            ? Colors.green.withValues(alpha: 0.2)
                            : null,
                        avatar: state.foundWords.contains(p.word) ? const Icon(Icons.check, size: 16) : null,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
