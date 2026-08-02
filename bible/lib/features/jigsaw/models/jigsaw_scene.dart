/// Schema stub for the Jigsaw Puzzles mode — not yet wired to gameplay.
/// Requires original/licensed artwork before real content ships; see
/// assets/content/jigsaw.json for the intended data shape.
class JigsawScene {
  const JigsawScene({
    required this.id,
    required this.sceneName,
    required this.imageAsset,
    required this.pieceCount,
    required this.difficulty,
  });

  final String id;
  final String sceneName;
  final String imageAsset;
  final int pieceCount;
  final String difficulty;

  factory JigsawScene.fromJson(Map<String, dynamic> json) => JigsawScene(
        id: json['id'] as String,
        sceneName: json['sceneName'] as String,
        imageAsset: json['imageAsset'] as String,
        pieceCount: json['pieceCount'] as int,
        difficulty: json['difficulty'] as String,
      );
}
