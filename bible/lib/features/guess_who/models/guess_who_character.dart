/// Schema stub for the "Guess Who" Character Reveal mode — not yet wired to gameplay.
/// See assets/content/guess_who.json for sample data in this shape.
class GuessWhoCharacter {
  const GuessWhoCharacter({
    required this.id,
    required this.characterName,
    required this.difficulty,
    required this.clues,
  });

  final String id;
  final String characterName;
  final String difficulty;

  /// Revealed one at a time, hardest/most-obscure clue first.
  final List<String> clues;

  factory GuessWhoCharacter.fromJson(Map<String, dynamic> json) => GuessWhoCharacter(
        id: json['id'] as String,
        characterName: json['characterName'] as String,
        difficulty: json['difficulty'] as String,
        clues: List<String>.from(json['clues'] as List),
      );
}
