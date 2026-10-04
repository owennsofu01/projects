import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bible_books.dart';
import '../../../core/network/bible_content_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/how_to_play_button.dart';
import '../models/bible_reference.dart';
import '../providers/bible_reader_provider.dart';

BibleVersion? _findVersion(List<BibleVersion>? versions, String id) {
  if (versions == null) return null;
  for (final v in versions) {
    if (v.id == id) return v;
  }
  return null;
}

class BibleReaderScreen extends ConsumerWidget {
  const BibleReaderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = ref.watch(selectedBibleReferenceProvider);
    final version = ref.watch(selectedBibleVersionProvider);
    final versesAsync = ref.watch(bibleChapterProvider);
    final versionsAsync = ref.watch(bibleVersionsProvider);
    final accent = AppColors.accentFor('bible_reader');
    final previousBook = BibleBooks.previous(reference.book);
    final nextBook = BibleBooks.next(reference.book);
    final canGoPrevious = reference.chapter > 1 || previousBook != null;
    final canGoNext = reference.chapter < BibleBooks.byName(reference.book).chapterCount || nextBook != null;

    void goTo(BibleReference next) => ref.read(selectedBibleReferenceProvider.notifier).state = next;

    void goPrevious() {
      if (reference.chapter > 1) {
        goTo(reference.copyWith(chapter: reference.chapter - 1));
      } else if (previousBook != null) {
        goTo(BibleReference(book: previousBook.name, chapter: previousBook.chapterCount));
      }
    }

    void goNext() {
      final chapterCount = BibleBooks.byName(reference.book).chapterCount;
      if (reference.chapter < chapterCount) {
        goTo(reference.copyWith(chapter: reference.chapter + 1));
      } else if (nextBook != null) {
        goTo(BibleReference(book: nextBook.name, chapter: 1));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${reference.book} ${reference.chapter}'),
        actions: [
          TextButton(
            onPressed: () => _openVersionPicker(context, ref, version, versionsAsync),
            child: Text(
              _findVersion(versionsAsync.valueOrNull, version)?.abbreviation ?? version.toUpperCase(),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Choose book & chapter',
            onPressed: () => _openPicker(context, reference, goTo),
          ),
          const HowToPlayButton(
            title: 'Read the Bible',
            steps: [
              'Browse any book and chapter using the book icon above.',
              'Switch translations by tapping the version abbreviation next to it.',
              'Use Previous and Next at the bottom to move between chapters.',
            ],
          ),
        ],
      ),
      body: versesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is BibleApiException ? error.message : 'Something went wrong: $error',
          onRetry: () => ref.invalidate(bibleChapterProvider),
        ),
        data: (verses) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: verses.length,
          itemBuilder: (context, index) {
            final verse = verses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16, height: 1.4),
                  children: [
                    TextSpan(
                      text: '${verse.number} ',
                      style: TextStyle(fontWeight: FontWeight.bold, color: accent, fontSize: 13),
                    ),
                    TextSpan(text: verse.text),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canGoPrevious ? goPrevious : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: canGoNext ? goNext : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVersionPicker(
    BuildContext context,
    WidgetRef ref,
    String currentVersionId,
    AsyncValue<List<BibleVersion>> versionsAsync,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => versionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text(error is BibleApiException ? error.message : 'Could not load versions.')),
          data: (versions) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const _SectionHeader('Choose a translation'),
              for (final v in versions)
                ListTile(
                  title: Text(v.name),
                  trailing: Text(v.abbreviation, style: Theme.of(context).textTheme.labelLarge),
                  selected: v.id == currentVersionId,
                  onTap: () {
                    ref.read(selectedBibleVersionProvider.notifier).state = v.id;
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPicker(BuildContext context, BibleReference current, void Function(BibleReference) onSelect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const _SectionHeader('Old Testament'),
            for (final book in BibleBooks.oldTestament)
              _BookTile(book: book, isSelected: book.name == current.book, onSelectChapter: onSelect),
            const _SectionHeader('New Testament'),
            for (final book in BibleBooks.newTestament)
              _BookTile(book: book, isSelected: book.name == current.book, onSelectChapter: onSelect),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book, required this.isSelected, required this.onSelectChapter});

  final BibleBook book;
  final bool isSelected;
  final void Function(BibleReference) onSelectChapter;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(book.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var chapter = 1; chapter <= book.chapterCount; chapter++)
                InkWell(
                  onTap: () {
                    onSelectChapter(BibleReference(book: book.name, chapter: chapter));
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$chapter'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
