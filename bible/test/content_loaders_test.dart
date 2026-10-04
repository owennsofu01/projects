import 'package:bible_gamehive/core/constants/bible_books.dart';
import 'package:bible_gamehive/features/bible_reader/models/verse_range.dart';
import 'package:bible_gamehive/features/character_match/data/character_match_content_loader.dart';
import 'package:bible_gamehive/features/guess_who/data/guess_who_content_loader.dart';
import 'package:bible_gamehive/features/parable_matching/data/parable_matching_content_loader.dart';
import 'package:bible_gamehive/features/timeline_puzzle/data/timeline_puzzle_content_loader.dart';
import 'package:bible_gamehive/features/trivia/data/trivia_content_loader.dart';
import 'package:bible_gamehive/features/verse_completion/data/verse_completion_content_loader.dart';
import 'package:bible_gamehive/core/progress/tiered_levels.dart';
import 'package:bible_gamehive/features/verse_reference_match/data/verse_reference_match_content_loader.dart';
import 'package:bible_gamehive/features/word_search/data/word_search_content_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuessWhoContentLoader', () {
    test('every clue has a scripture reference pointing at a real book and chapter', () async {
      final characters = await GuessWhoContentLoader.load();
      expect(characters.length, 200);
      expect(characters.map((c) => c.characterName.toLowerCase()).toSet().length, 200, reason: 'duplicate character');
      expect(characters.map((c) => c.level).toSet(), Set.of(List.generate(20, (i) => i + 1)));
      final bookNames = BibleBooks.all.map((b) => b.name).toSet();
      for (final c in characters) {
        expect(c.references.length, c.clues.length, reason: '${c.id}: one reference per clue');
        for (final reference in c.references) {
          final range = VerseRange.tryParse(reference);
          expect(range, isNotNull, reason: '${c.id}: "$reference" does not parse');
          expect(bookNames, contains(range!.book), reason: '${c.id}: unknown book in "$reference"');
          expect(
            range.chapter,
            inInclusiveRange(1, BibleBooks.byName(range.book).chapterCount),
            reason: '${c.id}: chapter out of range in "$reference"',
          );
        }
      }
    });
  });

  group('ParableMatchingContentLoader', () {
    test('20 levels (6 parables, then 8 from level 11), each answer unique within its level', () async {
      final content = await ParableMatchingContentLoader.load();
      final byId = content.byId;
      expect(byId.length, content.parables.length, reason: 'parable ids must be unique');
      expect(content.levels.map((l) => l.level), List.generate(20, (i) => i + 1));
      for (final level in content.levels) {
        final pairs = level.level <= 10 ? 6 : 8;
        expect(level.parableIds.toSet().length, pairs, reason: 'level ${level.level}');
        final parables = [for (final id in level.parableIds) byId[id]];
        expect(parables, everyElement(isNotNull), reason: 'level ${level.level} references an unknown parable');
        final answers = parables.map((p) => level.match.answerFor(p!)).toSet();
        expect(answers.length, pairs, reason: 'level ${level.level} has two identical ${level.match.id} answers');
      }
      for (final p in content.parables) {
        final range = VerseRange.tryParse(p.reference);
        expect(range, isNotNull, reason: '${p.id}: "${p.reference}"');
        expect(BibleBooks.all.map((b) => b.name), contains(range!.book), reason: '${p.id}: unknown book');
      }
    });
  });

  group('TimelinePuzzleContentLoader', () {
    test('12 levels of 8 events, ordered 1..8, with valid references', () async {
      final levels = await TimelinePuzzleContentLoader.load();
      expect(levels.map((l) => l.level), List.generate(12, (i) => i + 1));
      final ids = <String>{};
      final bookNames = BibleBooks.all.map((b) => b.name).toSet();
      for (final level in levels) {
        expect(level.events.map((e) => e.order), List.generate(8, (i) => i + 1), reason: 'level ${level.level}');
        for (final e in level.events) {
          expect(ids.add(e.id), isTrue, reason: 'duplicate id ${e.id}');
          final range = VerseRange.tryParse(e.reference);
          expect(range, isNotNull, reason: '${e.event}: "${e.reference}"');
          expect(bookNames, contains(range!.book), reason: '${e.event}: unknown book');
        }
      }
    });
  });

  group('TriviaContentLoader', () {
    test('parses all 100 questions with unique ids and 10 levels of 10 questions each', () async {
      final questions = await TriviaContentLoader.load();
      expect(questions.length, 100);
      expect(questions.map((q) => q.id).toSet().length, 100);

      final byLevel = <int, int>{};
      for (final q in questions) {
        byLevel[q.level] = (byLevel[q.level] ?? 0) + 1;
        expect(q.options, contains(q.answer));
      }
      expect(byLevel.keys.toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9, 10});
      for (final count in byLevel.values) {
        expect(count, 10);
      }
    });
  });

  group('VerseCompletionContentLoader', () {
    test('every tier has enough verses for two fresh rounds, each with one blank and 5 distractors', () async {
      final items = await VerseCompletionContentLoader.load();
      expect(items.map((i) => i.id).toSet().length, items.length);
      expect(items.map((i) => i.reference).toSet().length, items.length, reason: 'a verse is used twice');
      for (var tier = 1; tier <= TieredLevels.tierCount; tier++) {
        expect(
          items.where((i) => i.tier == tier).length,
          greaterThanOrEqualTo(TieredLevels.questionsPerLevel * 2),
          reason: 'tier $tier needs enough verses that a retry gets all-new ones',
        );
      }
      for (final item in items) {
        expect('____'.allMatches(item.template).length, 1, reason: item.id);
        expect(item.distractors.length, 5, reason: item.id);
        expect(item.distractors, isNot(contains(item.answer)), reason: item.id);
      }
    });
  });

  group('VerseReferenceMatchContentLoader', () {
    test('every tier has enough verses for two fresh rounds, all with real book names and verse numbers', () async {
      final items = await VerseReferenceMatchContentLoader.load();
      expect(items.map((i) => i.id).toSet().length, items.length);
      expect(items.map((i) => i.reference).toSet().length, items.length, reason: 'a verse is used twice');
      for (var tier = 1; tier <= TieredLevels.tierCount; tier++) {
        expect(items.where((i) => i.tier == tier).length, greaterThanOrEqualTo(TieredLevels.questionsPerLevel * 2));
      }
      final bookNames = BibleBooks.all.map((b) => b.name).toSet();
      for (final item in items) {
        expect(bookNames, contains(item.book), reason: item.id);
        expect(item.verse, inInclusiveRange(1, item.chapterVerses), reason: item.id);
        expect(item.text, isNot(matches(RegExp(r'\d'))), reason: '${item.id} still has a marginal note');
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
          expect(
            word.replaceAll(' ', '').length,
            lessThanOrEqualTo(12),
            reason: '${puzzle.id}: "$word" is too long for the 12x12 grid and would be silently dropped',
          );
        }
      }
    });
  });

  group('CharacterMatchContentLoader', () {
    test('10 levels growing from 4 to 8 pairs, 60 unique characters with valid references', () async {
      final levels = await CharacterMatchContentLoader.load();
      expect(levels.map((l) => l.level), List.generate(10, (i) => i + 1));
      expect(levels.map((l) => l.characters.length), [4, 4, 5, 5, 6, 6, 7, 7, 8, 8]);
      final all = [for (final l in levels) ...l.characters];
      expect(all.map((c) => c.id).toSet(), hasLength(60));
      expect(all.map((c) => c.name).toSet(), hasLength(60), reason: 'each character appears once');
      final bookNames = BibleBooks.all.map((b) => b.name).toSet();
      for (final c in all) {
        expect(c.keyAct, isNotEmpty);
        final range = VerseRange.tryParse(c.reference);
        expect(range, isNotNull, reason: '${c.name}: "${c.reference}"');
        expect(bookNames, contains(range!.book), reason: '${c.name}: unknown book');
      }
    });
  });
}
