import 'dart:math';

import '../../../core/constants/bible_books.dart';
import '../../../core/progress/tiered_levels.dart';
import '../models/verse_reference_match_item.dart';

/// Verse → Reference's take on [TieredLevels]: on top of less familiar
/// verses, the wrong references get closer to the right one as levels go up —
/// other books, then the same part of the Bible, then the same book and
/// neighbouring verses.
class VerseReferenceMatchLevels {
  VerseReferenceMatchLevels._();

  static const gameModeId = 'verse_reference_match';

  /// Start index in [BibleBooks.all] of each section: Law, History, Wisdom,
  /// Prophets, Gospels & Acts, Letters & Revelation.
  static const _sectionStarts = [0, 5, 17, 22, 39, 44];

  static int sectionOf(String book) {
    final index = BibleBooks.all.indexWhere((b) => b.name == book);
    return _sectionStarts.lastIndexWhere((start) => index >= start);
  }

  /// Other verses in the same chapter, closest first (up to 6 away).
  static List<String> nearbyReferences(VerseReferenceMatchItem item) => [
    for (var d = 1; d <= 6; d++)
      for (final v in [item.verse - d, item.verse + d])
        if (v >= 1 && v <= item.chapterVerses) '${item.book} ${item.chapter}:$v',
  ];

  /// The right reference plus wrong ones drawn from [pool], shuffled.
  static List<String> choicesFor(
    VerseReferenceMatchItem item,
    int level,
    List<VerseReferenceMatchItem> pool,
    Random random,
  ) {
    final others = pool.where((v) => v.reference != item.reference).toList()..shuffle(random);
    final section = sectionOf(item.book);
    final otherBooks = [
      for (final v in others)
        if (v.book != item.book) v.reference,
    ];
    final sameSection = [
      for (final v in others)
        if (v.book != item.book && sectionOf(v.book) == section) v.reference,
    ];
    final sameBook = [
      for (final v in others)
        if (v.book == item.book) v.reference,
    ];
    final nearby = nearbyReferences(item).take(4).toList()..shuffle(random);

    final candidates = switch (TieredLevels.tierFor(level)) {
      1 || 2 => otherBooks,
      3 || 4 => [...sameSection, ...sameBook, ...otherBooks],
      5 => [...nearby.take(1), ...sameBook, ...sameSection, ...otherBooks],
      _ => [...nearby.take(2), ...sameBook, ...sameSection, ...otherBooks],
    };
    final wrong = <String>{...candidates}..remove(item.reference);
    return [item.reference, ...wrong.take(TieredLevels.choiceCountFor(level) - 1)]..shuffle(random);
  }
}
