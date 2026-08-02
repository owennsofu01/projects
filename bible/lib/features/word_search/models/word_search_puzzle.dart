import '../../../core/models/difficulty.dart';

class WordSearchPuzzle {
  const WordSearchPuzzle({
    required this.id,
    required this.theme,
    required this.difficulty,
    required this.words,
  });

  final String id;
  final String theme;
  final Difficulty difficulty;
  final List<String> words;

  factory WordSearchPuzzle.fromJson(Map<String, dynamic> json) => WordSearchPuzzle(
        id: json['id'] as String,
        theme: json['theme'] as String,
        difficulty: Difficulty.fromJson(json['difficulty'] as String),
        words: List<String>.from(json['words'] as List).map((w) => w.toUpperCase()).toList(),
      );
}
