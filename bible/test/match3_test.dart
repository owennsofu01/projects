import 'package:bible_gamehive/features/match3/data/match3_content_loader.dart';
import 'package:bible_gamehive/features/match3/models/match3_level.dart';
import 'package:bible_gamehive/features/match3/providers/match3_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('30 levels in order, each with moves, a reachable tile count and a reward verse', () async {
    final levels = await Match3ContentLoader.load();
    expect(levels.map((l) => l.levelNumber), List.generate(30, (i) => i + 1));
    expect(levels.map((l) => l.id).toSet().length, 30);
    for (final l in levels) {
      expect(l.moves, greaterThan(0), reason: l.id);
      expect(l.tileKinds, inInclusiveRange(3, match3MaxKinds), reason: l.id);
      expect(l.targetScore, greaterThan(0), reason: l.id);
      expect(l.rewardVerse.trim(), isNotEmpty, reason: l.id);
      expect(l.rewardVerse, isNot(contains('¶')), reason: l.id);
    }
  });

  test('stars come from moves to spare; running out of moves earns none', () {
    expect(Match3Rules.starsFor(won: false, movesLeft: 0, moves: 20), 0);
    expect(Match3Rules.starsFor(won: true, movesLeft: 0, moves: 20), 1);
    expect(Match3Rules.starsFor(won: true, movesLeft: 3, moves: 20), 2);
    expect(Match3Rules.starsFor(won: true, movesLeft: 6, moves: 20), 3);
  });
}
