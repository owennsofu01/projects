/// Schema stub for the Hangman mode — not yet wired to gameplay.
/// See assets/content/hangman.json for sample data in this shape.
class HangmanWord {
  const HangmanWord({
    required this.id,
    required this.word,
    required this.category,
    required this.difficulty,
    required this.hint,
  });

  final String id;
  final String word;
  final String category;
  final String difficulty;
  final String hint;

  factory HangmanWord.fromJson(Map<String, dynamic> json) => HangmanWord(
        id: json['id'] as String,
        word: (json['word'] as String).toUpperCase(),
        category: json['category'] as String,
        difficulty: json['difficulty'] as String,
        hint: json['hint'] as String,
      );
}
