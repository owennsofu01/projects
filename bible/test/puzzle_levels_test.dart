import 'package:bible_gamehive/core/models/difficulty.dart';
import 'package:bible_gamehive/features/crossword/data/crossword_content_loader.dart';
import 'package:bible_gamehive/features/crossword/data/crossword_levels.dart';
import 'package:bible_gamehive/features/jigsaw/data/jigsaw_content_loader.dart';
import 'package:bible_gamehive/features/jigsaw/models/jigsaw_scene.dart';
import 'package:bible_gamehive/features/jigsaw/providers/jigsaw_session_provider.dart';
import 'package:bible_gamehive/features/jigsaw/widgets/scene_art.dart';
import 'package:bible_gamehive/features/word_search/data/word_search_content_loader.dart';
import 'package:bible_gamehive/features/word_search/data/word_search_levels.dart';
import 'package:bible_gamehive/features/word_search/models/word_search_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('levels are ordered easiest first, keeping file order within a difficulty', () {
    final items = [
      ('a', Difficulty.adult),
      ('k1', Difficulty.kids),
      ('s', Difficulty.scholar),
      ('k2', Difficulty.kids),
    ];
    expect(sortedByDifficulty(items, (i) => i.$2).map((i) => i.$1), ['k1', 'k2', 'a', 's']);
  });

  group('Word Search', () {
    test('one puzzle per level, and every word is placed at every level', () async {
      final puzzles = WordSearchLevels.ordered(await WordSearchContentLoader.load());
      expect(puzzles.length, WordSearchLevels.levelCount);
      for (var level = 1; level <= puzzles.length; level++) {
        final puzzle = puzzles[level - 1];
        final grid = WordSearchGrid.generateComplete(
          puzzle,
          size: WordSearchLevels.gridSizeFor(level),
          directions: WordSearchLevels.directionsFor(level),
          seed: level,
        );
        expect(grid.placements.length, puzzle.words.length, reason: 'level $level (${puzzle.id})');
      }
    });

    test('early levels only run words forwards; later ones add more directions', () {
      expect(WordSearchLevels.directionsFor(1), [(0, 1), (1, 0)]);
      expect(WordSearchLevels.directionsFor(6).length, 4);
      expect(WordSearchLevels.directionsFor(20).length, 8);
      expect([1, 6, 11, 16].map(WordSearchLevels.gridSizeFor), [9, 10, 11, 12]);
    });

    test('stars come from average seconds per word', () {
      expect(WordSearchLevels.starsFor(elapsed: const Duration(seconds: 200), wordCount: 10), 3);
      expect(WordSearchLevels.starsFor(elapsed: const Duration(seconds: 400), wordCount: 10), 2);
      expect(WordSearchLevels.starsFor(elapsed: const Duration(seconds: 401), wordCount: 10), 1);
    });
  });

  test('Crossword: fewer reveals, more stars', () async {
    final puzzles = CrosswordLevels.ordered(await CrosswordContentLoader.load());
    expect(puzzles.first.difficulty, Difficulty.kids);
    expect(puzzles.last.difficulty, Difficulty.scholar);
    expect([0, 1, 2, 3].map((h) => CrosswordLevels.starsFor(hintsUsed: h)), [3, 2, 2, 1]);
  });

  group('Jigsaw', () {
    test('20 levels, pieces never shrink, and each piece count makes a grid', () async {
      final scenes = await JigsawContentLoader.load();
      expect(scenes.map((s) => s.level), List.generate(20, (i) => i + 1));
      for (var i = 1; i < scenes.length; i++) {
        expect(scenes[i].pieceCount, greaterThanOrEqualTo(scenes[i - 1].pieceCount));
      }
      for (final s in scenes) {
        final (rows, cols) = jigsawGridDimensions(s.pieceCount);
        expect(rows * cols, s.pieceCount);
        expect(cols, greaterThan(1), reason: '${s.id}: a single column is not a jigsaw');
      }
    });

    test('minimum swaps counts cycles', () {
      expect(JigsawRules.minimumSwaps([0, 1, 2]), 0);
      expect(JigsawRules.minimumSwaps([1, 0, 2]), 1);
      expect(JigsawRules.minimumSwaps([1, 2, 0]), 2);
      expect(JigsawRules.minimumSwaps([1, 0, 3, 2]), 2);
    });

    testWidgets('every scene paints, whole and as pieces', (tester) async {
      for (final art in SceneArt.values) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                SizedBox(width: 120, height: 160, child: CustomPaint(painter: SceneArtPainter(art))),
                SizedBox(
                  width: 30,
                  height: 40,
                  child: CustomPaint(painter: SceneArtPainter(art, rows: 4, cols: 4, piece: 5)),
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: art.name);
      }
    });
  });
}
