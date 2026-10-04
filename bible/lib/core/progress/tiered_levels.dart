import 'dart:math';

/// The 30-level ladder shared by the verse quiz modes (Verse Completion,
/// Verse → Reference).
///
/// Every 5 levels share a tier of ~50 verses, so verses get less familiar as
/// levels go up; the number of choices also grows at levels 11 and 21. Each
/// round draws the tier's least-recently-seen verses, so replaying a level
/// (or moving to the next one) brings new questions until the whole tier has
/// been seen.
class TieredLevels {
  TieredLevels._();

  static const levelCount = 30;
  static const questionsPerLevel = 20;
  static const levelsPerTier = 5;
  static const tierCount = levelCount ~/ levelsPerTier;

  /// Stricter than the shared 60% rule in LevelRules: 70% passes and unlocks
  /// the next level.
  static const oneStar = 0.7;
  static const twoStars = 0.85;

  static const tierTitles = [
    'Famous Verses',
    'Well-Known Words',
    'Phrases & Promises',
    'Deeper Passages',
    'Prophets & Letters',
    "Scholar's Challenge",
  ];

  static int tierFor(int level) => (level - 1) ~/ levelsPerTier + 1;

  static int choiceCountFor(int level) => level <= 10 ? 4 : (level <= 20 ? 5 : 6);

  static String titleFor(int level) => tierTitles[tierFor(level) - 1];

  static int starsFor({required int correct, required int total}) {
    if (total <= 0) return 0;
    final accuracy = correct / total;
    if (accuracy >= 1.0) return 3;
    if (accuracy >= twoStars) return 2;
    if (accuracy >= oneStar) return 1;
    return 0;
  }

  static String percent(double fraction) => '${(fraction * 100).round()}%';

  static String? nextStarHint(int stars) => switch (stars) {
    0 => 'Get ${percent(oneStar)} right to pass and unlock the next level.',
    1 => 'Get ${percent(twoStars)} right for 2 stars.',
    2 => 'Get every verse right for 3 stars.',
    _ => null,
  };

  /// Picks a round from [tierPool]: items never seen first, then the ones
  /// seen longest ago. [seenIds] is ordered oldest → most recent.
  static List<T> pickRound<T>(List<T> tierPool, String Function(T) idOf, List<String> seenIds, Random random) {
    final seenOrder = {for (var i = 0; i < seenIds.length; i++) seenIds[i]: i};
    final unseen = tierPool.where((v) => !seenOrder.containsKey(idOf(v))).toList()..shuffle(random);
    final seen = tierPool.where((v) => seenOrder.containsKey(idOf(v))).toList()
      ..sort((a, b) => seenOrder[idOf(a)]!.compareTo(seenOrder[idOf(b)]!));
    return [...unseen, ...seen].take(questionsPerLevel).toList()..shuffle(random);
  }

  /// [seenIds] with [roundIds] moved to the most-recent end.
  static List<String> markSeen(List<String> seenIds, Iterable<String> roundIds) {
    final round = roundIds.toSet();
    return [...seenIds.where((id) => !round.contains(id)), ...round];
  }
}
