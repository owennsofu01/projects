/// Schema stub for the Character Match / Memory mode — not yet wired to gameplay.
/// See assets/content/character_match.json for sample data in this shape.
class CharacterMatchPair {
  const CharacterMatchPair({
    required this.id,
    required this.name,
    required this.description,
    required this.keyAct,
  });

  final String id;
  final String name;
  final String description;
  final String keyAct;

  factory CharacterMatchPair.fromJson(Map<String, dynamic> json) => CharacterMatchPair(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        keyAct: json['keyAct'] as String,
      );
}
