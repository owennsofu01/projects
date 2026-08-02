import 'package:go_router/go_router.dart';

import '../../features/character_match/character_match_screen.dart';
import '../../features/crossword/crossword_screen.dart';
import '../../features/guess_who/guess_who_screen.dart';
import '../../features/hangman/hangman_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/jigsaw/jigsaw_screen.dart';
import '../../features/map_puzzle/map_puzzle_screen.dart';
import '../../features/match3/match3_screen.dart';
import '../../features/parable_matching/parable_matching_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/timeline_puzzle/timeline_puzzle_screen.dart';
import '../../features/trivia/screens/trivia_level_select_screen.dart';
import '../../features/trivia/screens/trivia_play_screen.dart';
import '../../features/trivia/screens/trivia_setup_screen.dart';
import '../../features/verse_completion/screens/verse_completion_play_screen.dart';
import '../../features/verse_completion/screens/verse_completion_setup_screen.dart';
import '../../features/verse_reference_match/verse_reference_match_screen.dart';
import '../../features/word_search/screens/word_search_play_screen.dart';
import '../../features/word_search/screens/word_search_select_screen.dart';
import 'app_shell.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: RoutePaths.home, builder: (context, state) => const HomeScreen()),
        GoRoute(path: RoutePaths.progress, builder: (context, state) => const ProfileScreen()),
        GoRoute(path: RoutePaths.settings, builder: (context, state) => const SettingsScreen()),
      ],
    ),

    // Trivia
    GoRoute(path: RoutePaths.trivia, builder: (context, state) => const TriviaSetupScreen()),
    GoRoute(path: RoutePaths.triviaLevels, builder: (context, state) => const TriviaLevelSelectScreen()),
    GoRoute(
      path: RoutePaths.triviaPlay,
      builder: (context, state) => TriviaPlayScreen(args: state.extra as TriviaPlayArgs),
    ),

    // Verse Completion
    GoRoute(path: RoutePaths.verseCompletion, builder: (context, state) => const VerseCompletionSetupScreen()),
    GoRoute(
      path: RoutePaths.verseCompletionPlay,
      builder: (context, state) => VerseCompletionPlayScreen(args: state.extra as VerseCompletionPlayArgs),
    ),

    // Word Search
    GoRoute(path: RoutePaths.wordSearch, builder: (context, state) => const WordSearchSelectScreen()),
    GoRoute(
      path: RoutePaths.wordSearchPlay,
      builder: (context, state) => WordSearchPlayScreen(puzzleId: state.extra as String),
    ),

    // Placeholders
    GoRoute(path: RoutePaths.verseReferenceMatch, builder: (context, state) => const VerseReferenceMatchScreen()),
    GoRoute(path: RoutePaths.crossword, builder: (context, state) => const CrosswordScreen()),
    GoRoute(path: RoutePaths.characterMatch, builder: (context, state) => const CharacterMatchScreen()),
    GoRoute(path: RoutePaths.timelinePuzzle, builder: (context, state) => const TimelinePuzzleScreen()),
    GoRoute(path: RoutePaths.guessWho, builder: (context, state) => const GuessWhoScreen()),
    GoRoute(path: RoutePaths.parableMatching, builder: (context, state) => const ParableMatchingScreen()),
    GoRoute(path: RoutePaths.mapPuzzle, builder: (context, state) => const MapPuzzleScreen()),
    GoRoute(path: RoutePaths.match3, builder: (context, state) => const Match3Screen()),
    GoRoute(path: RoutePaths.hangman, builder: (context, state) => const HangmanScreen()),
    GoRoute(path: RoutePaths.jigsaw, builder: (context, state) => const JigsawScreen()),
  ],
);
