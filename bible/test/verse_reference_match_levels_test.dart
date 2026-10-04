import 'dart:math';

import 'package:bible_gamehive/features/verse_reference_match/data/verse_reference_match_levels.dart';
import 'package:bible_gamehive/features/verse_reference_match/models/verse_reference_match_item.dart';
import 'package:flutter_test/flutter_test.dart';

VerseReferenceMatchItem _item(String book, int chapter, int verse, {int chapterVerses = 30}) => VerseReferenceMatchItem(
  id: '$book$chapter:$verse',
  tier: 1,
  book: book,
  chapter: chapter,
  verse: verse,
  chapterVerses: chapterVerses,
  translation: 'KJV',
  text: 'text',
);

void main() {
  final john = _item('John', 3, 16, chapterVerses: 36);
  final pool = [
    john,
    _item('John', 14, 6),
    _item('Matthew', 5, 9),
    _item('Luke', 2, 11),
    _item('Mark', 16, 15),
    _item('Genesis', 1, 1),
    _item('Psalms', 23, 1),
    _item('Romans', 8, 28),
    _item('Isaiah', 40, 31),
    _item('Proverbs', 3, 5),
  ];

  test('books are grouped into the six sections of the Bible', () {
    expect(VerseReferenceMatchLevels.sectionOf('Genesis'), 0);
    expect(VerseReferenceMatchLevels.sectionOf('Esther'), 1);
    expect(VerseReferenceMatchLevels.sectionOf('Psalms'), 2);
    expect(VerseReferenceMatchLevels.sectionOf('Malachi'), 3);
    expect(VerseReferenceMatchLevels.sectionOf('Acts'), 4);
    expect(VerseReferenceMatchLevels.sectionOf('Revelation'), 5);
  });

  test('nearby references stay inside the chapter', () {
    final first = _item('Psalms', 23, 1, chapterVerses: 6);
    expect(VerseReferenceMatchLevels.nearbyReferences(first), [
      'Psalms 23:2',
      'Psalms 23:3',
      'Psalms 23:4',
      'Psalms 23:5',
      'Psalms 23:6',
    ]);
  });

  for (final level in [1, 15, 25, 30]) {
    test('level $level: right answer once, unique choices, sized to the level', () {
      final choices = VerseReferenceMatchLevels.choicesFor(john, level, pool, Random(level));
      expect(choices.where((c) => c == 'John 3:16').length, 1);
      expect(choices.toSet().length, choices.length);
      expect(choices.length, level <= 10 ? 4 : (level <= 20 ? 5 : 6));
    });
  }

  test('early levels only use other books; late levels add the same book and nearby verses', () {
    final easy = VerseReferenceMatchLevels.choicesFor(john, 1, pool, Random(1));
    expect(easy.where((c) => c != 'John 3:16' && c.startsWith('John ')), isEmpty);

    final hard = VerseReferenceMatchLevels.choicesFor(john, 30, pool, Random(1));
    expect(hard.where((c) => c.startsWith('John 3:') && c != 'John 3:16').length, 2);
    expect(hard, contains('John 14:6'));
  });

  test('middle levels prefer the same section (Gospels for John)', () {
    final mid = VerseReferenceMatchLevels.choicesFor(john, 15, pool, Random(1));
    final wrong = mid.where((c) => c != 'John 3:16').toList();
    expect(wrong.where((c) => ['Matthew', 'Luke', 'Mark'].any(c.startsWith)).length, 3);
  });
}
