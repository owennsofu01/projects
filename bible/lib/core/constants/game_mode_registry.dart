import 'package:flutter/material.dart';

import '../models/game_mode.dart';
import '../router/route_paths.dart';
import '../theme/app_colors.dart';

/// Single source of truth for every mini-game shown on the home hub.
/// Adding a new mode later means adding one entry here plus its route.
class GameModeRegistry {
  GameModeRegistry._();

  static final List<GameMode> all = [
    GameMode(
      id: 'trivia',
      title: 'Bible Trivia',
      description: 'Multiple choice, timed rounds across the whole Bible.',
      icon: Icons.quiz_outlined,
      accentColor: AppColors.accentFor('trivia'),
      routePath: RoutePaths.triviaLevels,
      status: GameModeStatus.available,
    ),
    GameMode(
      id: 'verse_completion',
      title: 'Verse Completion',
      description: 'Fill in the blank for famous — and obscure — verses.',
      icon: Icons.edit_note_outlined,
      accentColor: AppColors.accentFor('verse_completion'),
      routePath: RoutePaths.verseCompletion,
      status: GameModeStatus.available,
    ),
    GameMode(
      id: 'word_search',
      title: 'Word Search',
      description: 'Themed letter grids by book, character, or season.',
      icon: Icons.grid_on_outlined,
      accentColor: AppColors.accentFor('word_search'),
      routePath: RoutePaths.wordSearch,
      status: GameModeStatus.available,
    ),
    GameMode(
      id: 'verse_reference_match',
      title: 'Verse-to-Reference Match',
      description: 'Match a verse to its correct book, chapter, and verse.',
      icon: Icons.compare_arrows_outlined,
      accentColor: AppColors.accentFor('verse_reference_match'),
      routePath: RoutePaths.verseReferenceMatch,
      status: GameModeStatus.comingSoon,
    ),
    GameMode(
      id: 'crossword',
      title: 'Bible Crossword',
      description: 'Clues based on names, places, and events.',
      icon: Icons.grid_4x4_outlined,
      accentColor: AppColors.accentFor('crossword'),
      routePath: RoutePaths.crossword,
      status: GameModeStatus.comingSoon,
    ),
    GameMode(
      id: 'character_match',
      title: 'Character Match',
      description: 'Flip-card matching: name, description, and key act.',
      icon: Icons.style_outlined,
      accentColor: AppColors.accentFor('character_match'),
      routePath: RoutePaths.characterMatch,
      status: GameModeStatus.comingSoon,
    ),
    GameMode(
      id: 'timeline_puzzle',
      title: 'Timeline Puzzle',
      description: 'Drag events into chronological order.',
      icon: Icons.timeline_outlined,
      accentColor: AppColors.accentFor('timeline_puzzle'),
      routePath: RoutePaths.timelinePuzzle,
      status: GameModeStatus.comingSoon,
    ),
    GameMode(
      id: 'guess_who',
      title: '"Guess Who" Reveal',
      description: 'Progressive clues about a Bible figure.',
      icon: Icons.person_search_outlined,
      accentColor: AppColors.accentFor('guess_who'),
      routePath: RoutePaths.guessWho,
      status: GameModeStatus.comingSoon,
    ),
    GameMode(
      id: 'parable_matching',
      title: 'Parable Matching',
      description: 'Match each parable to its central lesson.',
      icon: Icons.auto_stories_outlined,
      accentColor: AppColors.accentFor('parable_matching'),
      routePath: RoutePaths.parableMatching,
      status: GameModeStatus.comingSoon,
    ),
    GameMode(
      id: 'map_puzzle',
      title: 'Bible Map Puzzle',
      description: 'Identify locations by tapping a map.',
      icon: Icons.map_outlined,
      accentColor: AppColors.accentFor('map_puzzle'),
      routePath: RoutePaths.mapPuzzle,
      status: GameModeStatus.comingSoon,
    ),
    GameMode(
      id: 'match3',
      title: 'Scripture Match-3',
      description: 'Match tiles to reveal a verse or Bible fact.',
      icon: Icons.apps_outlined,
      accentColor: AppColors.accentFor('match3'),
      routePath: RoutePaths.match3,
      status: GameModeStatus.comingSoon,
    ),
    GameMode(
      id: 'hangman',
      title: 'Hangman',
      description: 'Guess Bible names and places letter by letter.',
      icon: Icons.abc_outlined,
      accentColor: AppColors.accentFor('hangman'),
      routePath: RoutePaths.hangman,
      status: GameModeStatus.comingSoon,
    ),
    GameMode(
      id: 'jigsaw',
      title: 'Jigsaw Puzzles',
      description: 'Piece together Bible scene illustrations.',
      icon: Icons.extension_outlined,
      accentColor: AppColors.accentFor('jigsaw'),
      routePath: RoutePaths.jigsaw,
      status: GameModeStatus.comingSoon,
    ),
  ];

  static GameMode byId(String id) => all.firstWhere((m) => m.id == id);
}
