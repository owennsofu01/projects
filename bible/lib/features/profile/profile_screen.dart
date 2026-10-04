import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/bible_books.dart';
import '../../core/progress/progress_providers.dart';
import '../../core/widgets/stat_pill.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final completedCount = profile.completedBooks.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatPill(
                icon: Icons.local_fire_department_outlined,
                label: 'Current streak',
                value: '${profile.currentStreak}',
              ),
              StatPill(icon: Icons.military_tech_outlined, label: 'Longest streak', value: '${profile.longestStreak}'),
              StatPill(icon: Icons.emoji_events_outlined, label: 'Badges', value: '${profile.badges.length}'),
            ],
          ),
          const SizedBox(height: 32),
          Text('Badges', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (profile.badges.isEmpty)
            Text('Play a round to start earning badges.', style: theme.textTheme.bodySmall)
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: profile.badges
                  .map((b) => Chip(avatar: const Icon(Icons.emoji_events, size: 16), label: Text(b.title)))
                  .toList(),
            ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bible Completion Map', style: theme.textTheme.titleMedium),
              Text('$completedCount / 66', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          _BookSection(
            title: 'Old Testament',
            books: BibleBooks.oldTestament.map((b) => b.name).toList(),
            completed: profile.completedBooks,
          ),
          const SizedBox(height: 16),
          _BookSection(
            title: 'New Testament',
            books: BibleBooks.newTestament.map((b) => b.name).toList(),
            completed: profile.completedBooks,
          ),
        ],
      ),
    );
  }
}

class _BookSection extends StatelessWidget {
  const _BookSection({required this.title, required this.books, required this.completed});

  final String title;
  final List<String> books;
  final Map<String, bool> completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: books.map((book) {
            final done = completed[book] ?? false;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: done
                    ? theme.colorScheme.secondary.withValues(alpha: 0.3)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(book, style: theme.textTheme.labelSmall),
            );
          }).toList(),
        ),
      ],
    );
  }
}
