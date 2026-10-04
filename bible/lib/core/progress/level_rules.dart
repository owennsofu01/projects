/// The one star/unlock rule every leveled game mode shares, so "passing a
/// level" means the same thing everywhere.
class LevelRules {
  LevelRules._();

  static const maxStars = 3;

  /// Accuracy needed for 1, 2 and 3 stars. One star is a pass and unlocks
  /// the next level.
  static const oneStar = 0.6;
  static const twoStars = 0.8;
  static const threeStars = 1.0;

  static int starsFor({required int correct, required int total}) {
    if (total <= 0) return 0;
    final accuracy = correct / total;
    if (accuracy >= threeStars) return 3;
    if (accuracy >= twoStars) return 2;
    if (accuracy >= oneStar) return 1;
    return 0;
  }
}

/// What happened when a level round was recorded, for the result screen.
class LevelOutcome {
  const LevelOutcome({
    required this.level,
    required this.stars,
    required this.previousBest,
    required this.unlockedLevel,
  });

  final int level;
  final int stars;
  final int previousBest;

  /// The next level, if this round unlocked it (it wasn't open before).
  final int? unlockedLevel;

  bool get passed => stars > 0;
  bool get isNewBest => stars > previousBest;
}
