import 'package:flutter/material.dart';

/// Warm, calming palette: soft blues, golds, and creams. Each game mode gets
/// a complementary accent drawn from [gameAccents] so the hub reads as one
/// coherent system rather than a grab-bag of colors.
class AppColors {
  AppColors._();

  static const cream = Color(0xFFFBF6EC);
  static const creamDark = Color(0xFF1E1B16);

  static const softBlue = Color(0xFF5B7A9D);
  static const softBlueLight = Color(0xFFDCE7F0);

  static const gold = Color(0xFFC79A3E);
  static const goldLight = Color(0xFFF3E3BF);

  static const ink = Color(0xFF2E2A24);
  static const inkMuted = Color(0xFF6B6459);

  static const success = Color(0xFF5E8C6A);
  static const warning = Color(0xFFC96A4C);

  static const Map<String, Color> gameAccents = {
    'bible_reader': Color(0xFF3E6B5B),
    'trivia': Color(0xFF5B7A9D),
    'verse_completion': Color(0xFFC79A3E),
    'word_search': Color(0xFF6B9080),
    'verse_reference_match': Color(0xFF8E7CC3),
    'crossword': Color(0xFFB5654B),
    'character_match': Color(0xFF4A8FA6),
    'timeline_puzzle': Color(0xFF9C8A5E),
    'guess_who': Color(0xFFA65D6E),
    'parable_matching': Color(0xFF6A8E6B),
    'map_puzzle': Color(0xFF5E7A8C),
    'match3': Color(0xFFC77F3E),
    'hangman': Color(0xFF7A6B9C),
    'jigsaw': Color(0xFF8C6B5E),
  };

  static Color accentFor(String gameModeId) => gameAccents[gameModeId] ?? softBlue;
}
