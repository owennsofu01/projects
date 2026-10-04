import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/crossword_grid.dart';
import '../providers/crossword_session_provider.dart';
import 'crossword_result_screen.dart';

class CrosswordPlayArgs {
  /// Each args instance is a fresh attempt at the level.
  CrosswordPlayArgs(this.level) : attempt = DateTime.now().microsecondsSinceEpoch;

  final int level;
  final int attempt;

  CrosswordRound get round => (level: level, attempt: attempt);
}

class CrosswordPlayScreen extends ConsumerStatefulWidget {
  const CrosswordPlayScreen({super.key, required this.args});

  final CrosswordPlayArgs args;

  @override
  ConsumerState<CrosswordPlayScreen> createState() => _CrosswordPlayScreenState();
}

class _CrosswordPlayScreenState extends ConsumerState<CrosswordPlayScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // FocusNode.requestFocus() only shows the on-screen keyboard when focus
  // actually changes state. If the node is already focused (e.g. the user
  // tapped a cell, then a clue list tile, which can dismiss the OS keyboard
  // without the Flutter-side focus node ever losing focus), requestFocus()
  // becomes a no-op and the keyboard stays hidden. Explicitly asking the
  // platform to show it covers that case too.
  void _requestKeyboard() {
    _focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(crosswordSessionProvider(widget.args.round));
    final notifier = ref.read(crosswordSessionProvider(widget.args.round).notifier);
    final accent = AppColors.accentFor('crossword');

    if (state.status == CrosswordStatus.loading || state.grid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.status == CrosswordStatus.finished) {
      return CrosswordResultScreen(state: state, level: widget.args.level);
    }

    final grid = state.grid!;
    if (grid.placements.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(state.puzzle!.theme)),
        body: const Center(child: Text('This puzzle has no clues yet.')),
      );
    }

    final activePlacement = state.activePlacement;
    final activeCells = activePlacement?.cells.toSet() ?? const <Cell>{};

    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${widget.args.level} · ${state.puzzle!.theme}'),
        actions: [
          TextButton.icon(
            onPressed: activePlacement == null ? null : notifier.revealLetter,
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(state.hintsUsed == 0 ? 'Reveal' : 'Reveal (${state.hintsUsed})'),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _requestKeyboard(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  activePlacement == null
                      ? 'Tap a cell to begin'
                      : '${activePlacement.number}${activePlacement.isAcross ? "A" : "D"}. ${activePlacement.clue}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: AspectRatio(
                  aspectRatio: grid.cols / grid.rows,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: grid.cols),
                    itemCount: grid.rows * grid.cols,
                    itemBuilder: (context, index) {
                      final row = index ~/ grid.cols;
                      final col = index % grid.cols;
                      final cell = (row, col);

                      if (!grid.isOpen(row, col)) {
                        return Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
                      }

                      final isSelected = state.selectedCell == cell;
                      final isActiveWord = activeCells.contains(cell);
                      final number = grid.numbers[row][col];
                      final letter = state.entries[cell] ?? '';

                      return GestureDetector(
                        onTap: () {
                          notifier.selectCell(cell);
                          _requestKeyboard();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.55)
                                : isActiveWord
                                ? accent.withValues(alpha: 0.2)
                                : Theme.of(context).colorScheme.surface,
                            border: Border.all(color: Colors.black45, width: 0.5),
                          ),
                          child: Stack(
                            children: [
                              if (number != null)
                                Positioned(
                                  top: 1,
                                  left: 2,
                                  child: Text('$number', style: const TextStyle(fontSize: 8, color: Colors.black54)),
                                ),
                              Center(
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    // Revealed letters stand out from ones the player typed.
                                    color: state.revealed.contains(cell) ? Colors.deepOrange : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Opacity(
              // A degenerate 1x1 hidden field is unreliable on real Android
              // hardware — several OEM IME implementations won't raise the
              // soft keyboard for a focused view that small, even though
              // it works fine on emulators. Give it a real, if invisible,
              // footprint instead.
              opacity: 0,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                      notifier.backspace();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    showCursor: false,
                    autocorrect: false,
                    enableInteractiveSelection: false,
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged: (value) {
                      if (value.isEmpty) return;
                      final letter = value.substring(value.length - 1);
                      if (RegExp(r'[a-zA-Z]').hasMatch(letter)) {
                        notifier.inputLetter(letter);
                      }
                      _controller.clear();
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _ClueSection(
                    title: 'Across',
                    placements: grid.placements.where((p) => p.isAcross).toList(),
                    state: state,
                    onTap: (p) {
                      notifier.selectClue(p);
                      _requestKeyboard();
                    },
                  ),
                  const SizedBox(height: 12),
                  _ClueSection(
                    title: 'Down',
                    placements: grid.placements.where((p) => !p.isAcross).toList(),
                    state: state,
                    onTap: (p) {
                      notifier.selectClue(p);
                      _requestKeyboard();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClueSection extends StatelessWidget {
  const _ClueSection({required this.title, required this.placements, required this.state, required this.onTap});

  final String title;
  final List<CrosswordPlacement> placements;
  final CrosswordState state;
  final void Function(CrosswordPlacement) onTap;

  bool _isSolved(CrosswordPlacement p) =>
      p.cells.asMap().entries.every((e) => state.entries[e.value] == p.answer[e.key]);

  @override
  Widget build(BuildContext context) {
    if (placements.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final p in placements)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(width: 24, child: Text('${p.number}', style: Theme.of(context).textTheme.bodyMedium)),
            title: Text(p.clue),
            trailing: _isSolved(p) ? const Icon(Icons.check_circle, color: Colors.green, size: 18) : null,
            selected: state.activePlacement == p,
            onTap: () => onTap(p),
          ),
      ],
    );
  }
}
