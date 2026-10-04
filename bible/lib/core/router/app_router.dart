import 'package:go_router/go_router.dart';

import '../../features/bible_reader/screens/bible_reader_screen.dart';
import '../../features/character_match/screens/character_match_play_screen.dart';
import '../../features/character_match/screens/character_match_level_select_screen.dart';
import '../../features/compete/screens/challenge_result_screen.dart';
import '../../features/compete/screens/compete_screen.dart';
import '../../features/crossword/screens/crossword_play_screen.dart';
import '../../features/crossword/screens/crossword_level_select_screen.dart';
import '../../features/guess_who/screens/guess_who_level_select_screen.dart';
import '../../features/guess_who/screens/guess_who_play_screen.dart';
import '../../features/hangman/screens/hangman_level_select_screen.dart';
import '../../features/hangman/screens/hangman_play_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/jigsaw/screens/jigsaw_play_screen.dart';
import '../../features/jigsaw/screens/jigsaw_level_select_screen.dart';
import '../../features/map_puzzle/screens/map_puzzle_level_select_screen.dart';
import '../../features/map_puzzle/screens/map_puzzle_play_screen.dart';
import '../../features/match3/screens/match3_level_select_screen.dart';
import '../../features/match3/screens/match3_play_screen.dart';
import '../../features/parable_matching/screens/parable_matching_level_select_screen.dart';
import '../../features/parable_matching/screens/parable_matching_play_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/timeline_puzzle/screens/timeline_puzzle_level_select_screen.dart';
import '../../features/timeline_puzzle/screens/timeline_puzzle_play_screen.dart';
import '../../features/trivia/screens/trivia_level_select_screen.dart';
import '../../features/trivia/screens/trivia_play_screen.dart';
import '../../features/trivia/screens/trivia_setup_screen.dart';
import '../../features/verse_completion/screens/verse_completion_play_screen.dart';
import '../../features/verse_completion/screens/verse_completion_level_select_screen.dart';
import '../../features/verse_reference_match/screens/verse_reference_match_play_screen.dart';
import '../../features/verse_reference_match/screens/verse_reference_match_level_select_screen.dart';
import '../../features/word_search/screens/word_search_play_screen.dart';
import '../../features/word_search/screens/word_search_level_select_screen.dart';
import 'app_shell.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: RoutePaths.home, builder: (context, state) => const HomeScreen()),
        GoRoute(path: RoutePaths.compete, builder: (context, state) => const CompeteScreen()),
        GoRoute(path: RoutePaths.progress, builder: (context, state) => const ProfileScreen()),
        GoRoute(path: RoutePaths.settings, builder: (context, state) => const SettingsScreen()),
      ],
    ),

    // Friend challenge standings
    GoRoute(
      path: RoutePaths.challengeResult,
      builder: (context, state) => ChallengeResultScreen(code: state.extra as String),
    ),

    // Bible Reader
    GoRoute(path: RoutePaths.bibleReader, builder: (context, state) => const BibleReaderScreen()),

    // Trivia
    GoRoute(path: RoutePaths.trivia, builder: (context, state) => const TriviaSetupScreen()),
    GoRoute(path: RoutePaths.triviaLevels, builder: (context, state) => const TriviaLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.triviaPlay,
      builder: (context, state) => TriviaPlayScreen(args: state.extra as TriviaPlayArgs),
    ),

    // Verse Completion
    GoRoute(path: RoutePaths.verseCompletion, builder: (context, state) => const VerseCompletionLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.verseCompletionPlay,
      builder: (context, state) => VerseCompletionPlayScreen(args: state.extra as VerseCompletionPlayArgs),
    ),

    // Word Search
    GoRoute(path: RoutePaths.wordSearch, builder: (context, state) => const WordSearchLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.wordSearchPlay,
      builder: (context, state) => WordSearchPlayScreen(args: state.extra as WordSearchPlayArgs),
    ),

    // Verse-to-Reference Match
    GoRoute(
      path: RoutePaths.verseReferenceMatch,
      builder: (context, state) => const VerseReferenceMatchLevelSelectScreen(),
    ),
    GoRoute(
      path: RoutePaths.verseReferenceMatchPlay,
      builder: (context, state) => VerseReferenceMatchPlayScreen(args: state.extra as VerseReferenceMatchPlayArgs),
    ),

    // Crossword
    GoRoute(path: RoutePaths.crossword, builder: (context, state) => const CrosswordLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.crosswordPlay,
      builder: (context, state) => CrosswordPlayScreen(args: state.extra as CrosswordPlayArgs),
    ),

    // Character Match
    GoRoute(path: RoutePaths.characterMatch, builder: (context, state) => const CharacterMatchLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.characterMatchPlay,
      builder: (context, state) => CharacterMatchPlayScreen(level: state.extra as int),
    ),

    // Timeline Puzzle
    GoRoute(path: RoutePaths.timelinePuzzle, builder: (context, state) => const TimelinePuzzleLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.timelinePuzzlePlay,
      builder: (context, state) => TimelinePuzzlePlayScreen(level: state.extra as int),
    ),

    // Guess Who
    GoRoute(path: RoutePaths.guessWho, builder: (context, state) => const GuessWhoLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.guessWhoPlay,
      builder: (context, state) => GuessWhoPlayScreen(args: state.extra as GuessWhoPlayArgs),
    ),

    // Parable Matching
    GoRoute(path: RoutePaths.parableMatching, builder: (context, state) => const ParableMatchingLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.parableMatchingPlay,
      builder: (context, state) => ParableMatchingPlayScreen(level: state.extra as int),
    ),

    // Map Puzzle
    GoRoute(path: RoutePaths.mapPuzzle, builder: (context, state) => const MapPuzzleLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.mapPuzzlePlay,
      builder: (context, state) => MapPuzzlePlayScreen(level: state.extra as int),
    ),

    // Hangman
    GoRoute(path: RoutePaths.hangman, builder: (context, state) => const HangmanLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.hangmanPlay,
      builder: (context, state) => HangmanPlayScreen(args: state.extra as HangmanPlayArgs),
    ),

    // Match-3
    GoRoute(path: RoutePaths.match3, builder: (context, state) => const Match3LevelSelectScreen()),
    GoRoute(
      path: RoutePaths.match3Play,
      builder: (context, state) => Match3PlayScreen(args: state.extra as Match3PlayArgs),
    ),

    // Jigsaw
    GoRoute(path: RoutePaths.jigsaw, builder: (context, state) => const JigsawLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.jigsawPlay,
      builder: (context, state) => JigsawPlayScreen(args: state.extra as JigsawPlayArgs),
    ),
  ],
);
