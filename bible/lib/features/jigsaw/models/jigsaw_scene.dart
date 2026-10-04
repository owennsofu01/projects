import '../widgets/scene_art.dart';

/// One jigsaw level: [art] cut into [pieceCount] pieces.
class JigsawScene {
  const JigsawScene({
    required this.id,
    required this.level,
    required this.sceneName,
    required this.art,
    required this.pieceCount,
    required this.reference,
  });

  final String id;
  final int level;
  final String sceneName;
  final SceneArt art;
  final int pieceCount;
  final String reference;

  factory JigsawScene.fromJson(Map<String, dynamic> json) => JigsawScene(
    id: json['id'] as String,
    level: json['level'] as int,
    sceneName: json['sceneName'] as String,
    art: SceneArt.fromJson(json['scene'] as String),
    pieceCount: json['pieceCount'] as int,
    reference: json['reference'] as String,
  );
}

class JigsawRules {
  JigsawRules._();

  static const gameModeId = 'jigsaw';

  /// Up to this level, pieces in the right spot show a check mark.
  static const lastLevelWithChecks = 10;

  /// The fewest swaps that can solve [order]: each cycle of k misplaced
  /// pieces takes k - 1 swaps.
  static int minimumSwaps(List<int> order) {
    final seen = List.filled(order.length, false);
    var swaps = 0;
    for (var i = 0; i < order.length; i++) {
      var length = 0;
      for (var j = i; !seen[j]; j = order[j]) {
        seen[j] = true;
        length++;
      }
      if (length > 1) swaps += length - 1;
    }
    return swaps;
  }

  /// Stars from wasted swaps: within a quarter of the piece count of the
  /// minimum earns 3, within three quarters earns 2.
  static int starsFor({required int moves, required int minimumMoves, required int pieceCount}) {
    final extra = moves - minimumMoves;
    if (extra <= pieceCount * 0.25) return 3;
    if (extra <= pieceCount * 0.75) return 2;
    return 1;
  }
}
