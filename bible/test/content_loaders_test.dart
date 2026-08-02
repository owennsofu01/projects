import 'package:bible_gamehive/features/trivia/data/trivia_content_loader.dart';
import 'package:bible_gamehive/features/verse_completion/data/verse_completion_content_loader.dart';
import 'package:bible_gamehive/features/word_search/data/word_search_content_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TriviaContentLoader', () {
    test('parses all 80 questions with unique ids and 10 levels of 8 questions each', () async {
      final questions = await TriviaContentLoader.load();
      expect(questions.length, 80);
      expect(questions.map((q) => q.id).toSet().length, 80);

      final byLevel = <int, int>{};
      for (final q in questions) {
        byLevel[q.level] = (byLevel[q.level] ?? 0) + 1;
        expect(q.options, contains(q.answer));
      }
      expect(byLevel.keys.toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9, 10});
      for (final count in byLevel.values) {
        expect(count, 8);
      }
    });
  });

  group('VerseCompletionContentLoader', () {
    test('parses all 40 items with unique ids and valid word banks', () async {
      final items = await VerseCompletionContentLoader.load();
      expect(items.length, 40);
      expect(items.map((i) => i.id).toSet().length, 40);
      for (final item in items) {
        expect(item.wordBank, contains(item.answer));
        expect(item.template, contains('____'));
      }
    });
  });

  group('WordSearchContentLoader', () {
    test('parses all 20 puzzles with unique ids and no word too long for the grid', () async {
      final puzzles = await WordSearchContentLoader.load();
      expect(puzzles.length, 20);
      expect(puzzles.map((p) => p.id).toSet().length, 20);
      for (final puzzle in puzzles) {
        for (final word in puzzle.words) {
          expect(word.replaceAll(' ', '').length, lessThanOrEqualTo(12),
              reason: '${puzzle.id}: "$word" is too long for the 12x12 grid and would be silently dropped');
        }
      }
    });
  });
}
