import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/bible_content_client.dart';
import '../data/bible_repository.dart';
import '../models/bible_reference.dart';
import '../models/bible_verse.dart';
import '../models/verse_range.dart';

final bibleContentClientProvider = Provider<BibleContentClient>((ref) => BibleContentClient());

final bibleRepositoryProvider = Provider<BibleRepository>(
  (ref) => BibleRepository(ref.watch(bibleContentClientProvider)),
);

final selectedBibleReferenceProvider = StateProvider<BibleReference>(
  (ref) => const BibleReference(book: 'Genesis', chapter: 1),
);

final selectedBibleVersionProvider = StateProvider<String>((ref) => 'en-kjv');

final bibleVersionsProvider = FutureProvider<List<BibleVersion>>(
  (ref) => ref.watch(bibleRepositoryProvider).getVersions(),
);

final bibleChapterProvider = FutureProvider.autoDispose<List<BibleVerse>>((ref) {
  final reference = ref.watch(selectedBibleReferenceProvider);
  final version = ref.watch(selectedBibleVersionProvider);
  return ref.watch(bibleRepositoryProvider).getChapter(reference, version);
});

final verseOfTheDayProvider = FutureProvider<(String text, String reference)>(
  (ref) => ref.watch(bibleRepositoryProvider).getVerseOfTheDay(DateTime.now()),
);

/// Verse text for a reference string like "Genesis 2:19-20", in the reader's
/// selected version.
final scripturePassageProvider = FutureProvider.autoDispose.family<List<BibleVerse>, String>((ref, reference) {
  final range = VerseRange.tryParse(reference);
  if (range == null) throw ArgumentError.value(reference, 'reference', 'Not a valid verse reference');
  final version = ref.watch(selectedBibleVersionProvider);
  return ref.watch(bibleRepositoryProvider).getPassage(range, version);
});
