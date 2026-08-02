import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../data/word_search_content_loader.dart';
import '../models/word_search_puzzle.dart';

class WordSearchSelectScreen extends ConsumerWidget {
  const WordSearchSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Search')),
      body: FutureBuilder<List<WordSearchPuzzle>>(
        future: WordSearchContentLoader.load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final puzzles = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: puzzles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final puzzle = puzzles[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(puzzle.theme),
                  subtitle: Text('${puzzle.words.length} words · ${puzzle.difficulty.label}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RoutePaths.wordSearchPlay, extra: puzzle.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
