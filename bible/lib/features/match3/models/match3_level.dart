/// One Scripture Match-3 level: reach [targetScore] within [moves] swaps on a
/// board of [tileKinds] tile types (6 kinds means fewer natural matches).
class Match3Level {
  const Match3Level({
    required this.id,
    required this.levelNumber,
    required this.targetScore,
    required this.moves,
    required this.tileKinds,
    required this.rewardVerse,
    required this.rewardReference,
  });

  final String id;
  final int levelNumber;
  final int targetScore;
  final int moves;
  final int tileKinds;
  final String rewardVerse;
  final String rewardReference;

  factory Match3Level.fromJson(Map<String, dynamic> json) => Match3Level(
    id: json['id'] as String,
    levelNumber: json['levelNumber'] as int,
    targetScore: json['targetScore'] as int,
    moves: json['moves'] as int,
    tileKinds: json['tileKinds'] as int,
    rewardVerse: json['rewardVerse'] as String,
    rewardReference: json['rewardReference'] as String,
  );
}

class Match3Rules {
  Match3Rules._();

  static const gameModeId = 'match3';

  /// Winning earns at least 1 star; finishing with 30%+ of moves to spare
  /// earns 3, 15%+ earns 2. Running out of moves earns none.
  static int starsFor({required bool won, required int movesLeft, required int moves}) {
    if (!won) return 0;
    final spare = moves <= 0 ? 0.0 : movesLeft / moves;
    if (spare >= 0.3) return 3;
    if (spare >= 0.15) return 2;
    return 1;
  }
}
