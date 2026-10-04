import 'package:bible_gamehive/core/models/user_profile.dart';
import 'package:bible_gamehive/core/progress/level_rules.dart';
import 'package:bible_gamehive/features/character_match/models/character_match_pair.dart';
import 'package:bible_gamehive/features/character_match/providers/character_match_session_provider.dart';
import 'package:bible_gamehive/features/timeline_puzzle/models/timeline_event.dart';
import 'package:bible_gamehive/features/timeline_puzzle/providers/timeline_puzzle_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelRules.starsFor', () {
    test('maps accuracy to 0-3 stars at 60/80/100%', () {
      expect(LevelRules.starsFor(correct: 5, total: 10), 0);
      expect(LevelRules.starsFor(correct: 6, total: 10), 1);
      expect(LevelRules.starsFor(correct: 7, total: 10), 1);
      expect(LevelRules.starsFor(correct: 8, total: 10), 2);
      expect(LevelRules.starsFor(correct: 9, total: 10), 2);
      expect(LevelRules.starsFor(correct: 10, total: 10), 3);
    });

    test('an empty round earns nothing', () {
      expect(LevelRules.starsFor(correct: 0, total: 0), 0);
    });
  });

  group('UserProfile level stars', () {
    test('level 1 is open on a fresh profile', () {
      final profile = UserProfile.guest('u');
      expect(profile.unlockedLevel('trivia'), 1);
      expect(profile.totalStars('trivia'), 0);
    });

    test('unlocked level is one past the highest passed level', () {
      const profile = UserProfile(
        uid: 'u',
        levelStars: {
          'trivia': {1: 3, 2: 1, 3: 2},
        },
      );
      expect(profile.unlockedLevel('trivia'), 4);
      expect(profile.totalStars('trivia'), 6);
      expect(profile.starsFor('trivia', 2), 1);
      expect(profile.unlockedLevel('hangman'), 1);
    });

    test('round-trips through JSON (string keys for Firestore)', () {
      const profile = UserProfile(
        uid: 'u',
        levelStars: {
          'guess_who': {1: 2, 2: 3},
        },
      );
      final json = profile.toJson();
      expect((json['levelStars'] as Map)['guess_who'], {'1': 2, '2': 3});
      expect(UserProfile.fromJson(json).levelStars, profile.levelStars);
    });

    test('migrates old unlocked-level fields so nobody loses progress', () {
      final profile = UserProfile.fromJson({
        'uid': 'u',
        'triviaUnlockedLevel': 4,
        'guessWhoUnlockedLevel': 1,
        'hangmanUnlockedLevel': 2,
      });
      expect(profile.levelStars['trivia'], {1: 1, 2: 1, 3: 1});
      expect(profile.unlockedLevel('trivia'), 4);
      expect(profile.levelStars.containsKey('guess_who'), isFalse);
      expect(profile.unlockedLevel('hangman'), 2);
    });

    test('migration never overwrites stars already earned', () {
      final profile = UserProfile.fromJson({
        'uid': 'u',
        'triviaUnlockedLevel': 3,
        'levelStars': {
          'trivia': {'1': 3},
        },
      });
      expect(profile.levelStars['trivia'], {1: 3, 2: 1});
    });
  });

  group('LevelOutcome', () {
    test('reports new bests only when stars improve', () {
      const better = LevelOutcome(level: 2, stars: 3, previousBest: 1, unlockedLevel: null);
      const same = LevelOutcome(level: 2, stars: 1, previousBest: 1, unlockedLevel: null);
      expect(better.isNewBest, isTrue);
      expect(same.isNewBest, isFalse);
      expect(same.passed, isTrue);
    });
  });

  group('Timeline stars (by checks)', () {
    TimelinePuzzleState solvedAfter(int checks) => TimelinePuzzleState(
      order: List.generate(8, (i) => TimelineEvent(id: '$i', event: '', reference: '', order: i + 1)),
      checks: checks,
    );

    test('first check 3, second 2, later 1', () {
      expect(solvedAfter(1).stars, 3);
      expect(solvedAfter(2).stars, 2);
      expect(solvedAfter(3).stars, 1);
      expect(solvedAfter(9).stars, 1);
    });
  });

  group('Character Match stars (by misses)', () {
    CharacterMatchState finishedWith({required int pairs, required int misses}) => CharacterMatchState(
      characters: List.generate(
        pairs,
        (i) => CharacterMatchPair(id: '$i', name: '', description: '', keyAct: '', reference: ''),
      ),
      matchedCharacterIds: {for (var i = 0; i < pairs; i++) '$i'},
      moves: pairs + misses,
    );

    test('up to one miss per pair is 3 stars, up to two is 2, more is 1', () {
      expect(finishedWith(pairs: 4, misses: 0).stars, 3);
      expect(finishedWith(pairs: 4, misses: 4).stars, 3);
      expect(finishedWith(pairs: 4, misses: 5).stars, 2);
      expect(finishedWith(pairs: 4, misses: 8).stars, 2);
      expect(finishedWith(pairs: 4, misses: 9).stars, 1);
    });
  });
}
