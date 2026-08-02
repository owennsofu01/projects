/// Schema stub for the Match-3 Puzzle mode — not yet wired to gameplay.
/// See assets/content/match3.json for sample data in this shape.
class Match3Level {
  const Match3Level({
    required this.id,
    required this.levelNumber,
    required this.targetScore,
    required this.rewardVerse,
    required this.rewardReference,
  });

  final String id;
  final int levelNumber;
  final int targetScore;
  final String rewardVerse;
  final String rewardReference;

  factory Match3Level.fromJson(Map<String, dynamic> json) => Match3Level(
        id: json['id'] as String,
        levelNumber: json['levelNumber'] as int,
        targetScore: json['targetScore'] as int,
        rewardVerse: json['rewardVerse'] as String,
        rewardReference: json['rewardReference'] as String,
      );
}
