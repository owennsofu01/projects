import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/difficulty.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/settings_providers.dart';
import 'verse_completion_play_screen.dart';

class VerseCompletionSetupScreen extends ConsumerStatefulWidget {
  const VerseCompletionSetupScreen({super.key});

  @override
  ConsumerState<VerseCompletionSetupScreen> createState() => _VerseCompletionSetupScreenState();
}

class _VerseCompletionSetupScreenState extends ConsumerState<VerseCompletionSetupScreen> {
  late Difficulty _difficulty = ref.read(settingsProvider).defaultDifficulty;

  @override
  Widget build(BuildContext context) {
    final kidMode = ref.watch(settingsProvider).kidMode;
    return Scaffold(
      appBar: AppBar(title: const Text('Verse Completion')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            kidMode
                ? 'Tap the right word to complete each verse.'
                : 'Type the missing word or phrase for each verse.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Difficulty', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: Difficulty.values
                .map((d) => ChoiceChip(
                      label: Text(d.label),
                      selected: _difficulty == d,
                      onSelected: (_) => setState(() => _difficulty = d),
                    ))
                .toList(),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push(
              RoutePaths.verseCompletionPlay,
              extra: VerseCompletionPlayArgs(difficulty: _difficulty, kidMode: kidMode),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Round'),
          ),
        ],
      ),
    );
  }
}
