class HangmanWord {
  const HangmanWord({
    required this.id,
    required this.word,
    required this.category,
    required this.level,
    required this.hint,
  });

  final String id;
  final String word;
  final String category;

  /// 1-10; higher levels use longer, more obscure words.
  final int level;
  final String hint;

  factory HangmanWord.fromJson(Map<String, dynamic> json) => HangmanWord(
    id: json['id'] as String,
    word: (json['word'] as String).toUpperCase(),
    category: json['category'] as String,
    level: json['level'] as int,
    hint: json['hint'] as String,
  );
}
