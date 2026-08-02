import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/difficulty.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/settings_providers.dart';
import 'trivia_play_screen.dart';

const _categories = ['All', 'Old Testament', 'New Testament', 'Miracles', 'Parables', 'Prophets', 'Kings', 'Women of the Bible'];

class TriviaSetupScreen extends ConsumerStatefulWidget {
  const TriviaSetupScreen({super.key});

  @override
  ConsumerState<TriviaSetupScreen> createState() => _TriviaSetupScreenState();
}

class _TriviaSetupScreenState extends ConsumerState<TriviaSetupScreen> {
  late String _category = _categories.first;
  late Difficulty _difficulty = ref.read(settingsProvider).defaultDifficulty;

  @override
  Widget build(BuildContext context) {
    final kidMode = ref.watch(settingsProvider).kidMode;
    return Scaffold(
      appBar: AppBar(title: const Text('Bible Trivia')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .map((c) => ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ))
                .toList(),
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
              RoutePaths.triviaPlay,
              extra: TriviaPlayArgs(category: _category, difficulty: _difficulty, kidMode: kidMode),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Round'),
          ),
        ],
      ),
    );
  }
}
