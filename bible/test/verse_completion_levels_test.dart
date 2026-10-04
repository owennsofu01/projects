import 'dart:math';

import 'package:bible_gamehive/core/progress/tiered_levels.dart';
import 'package:bible_gamehive/features/verse_completion/data/verse_completion_levels.dart';
import 'package:bible_gamehive/features/verse_completion/models/verse_completion_item.dart';
import 'package:flutter_test/flutter_test.dart';

VerseCompletionItem _item(int i) => VerseCompletionItem(
  id: 'v$i',
  tier: 1,
  reference: 'Book 1:$i',
  translation: 'KJV',
  template: 'word ____ word',
  answer: 'a$i',
  distractors: ['b$i', 'c$i', 'd$i', 'e$i', 'f$i'],
);

void main() {
  final pool = [for (var i = 0; i < 50; i++) _item(i)];

  test('70% passes, 85% earns 2 stars, a perfect round earns 3', () {
    expect(TieredLevels.starsFor(correct: 13, total: 20), 0);
    expect(TieredLevels.starsFor(correct: 14, total: 20), 1);
    expect(TieredLevels.starsFor(correct: 17, total: 20), 2);
    expect(TieredLevels.starsFor(correct: 20, total: 20), 3);
  });

  test('levels move up a tier every 5 levels and add choices at 11 and 21', () {
    expect([1, 5, 6, 30].map(TieredLevels.tierFor), [1, 1, 2, 6]);
    expect([1, 10, 11, 20, 21, 30].map(TieredLevels.choiceCountFor), [4, 4, 5, 5, 6, 6]);
  });

  test('a retry gets 20 verses the player did not just see', () {
    final random = Random(1);
    final first = TieredLevels.pickRound(pool, (v) => v.id, const [], random);
    expect(first.length, 20);
    final seen = TieredLevels.markSeen(const [], first.map((v) => v.id));

    final retry = TieredLevels.pickRound(pool, (v) => v.id, seen, random);
    expect(retry.length, 20);
    expect(retry.map((v) => v.id).toSet().intersection(seen.toSet()), isEmpty);
  });

  test('once the pool runs out of unseen verses, the longest-ago ones come back first', () {
    final random = Random(2);
    var seen = <String>[];
    final rounds = <List<String>>[];
    for (var i = 0; i < 3; i++) {
      final round = TieredLevels.pickRound(pool, (v) => v.id, seen, random).map((v) => v.id).toList();
      rounds.add(round);
      seen = TieredLevels.markSeen(seen, round);
    }
    // Round 3 uses the 10 never-seen verses plus 10 from round 1, none from round 2.
    expect(rounds[2].toSet().intersection(rounds[1].toSet()), isEmpty);
    expect(rounds[2].toSet().intersection(rounds[0].toSet()).length, 10);
  });

  test('choices include the answer once and match the level size', () {
    final choices = VerseCompletionLevels.choicesFor(pool.first, 25, Random(3));
    expect(choices.length, 6);
    expect(choices.where((c) => c == 'a0').length, 1);
  });
}
