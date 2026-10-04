class CharacterMatchPair {
  const CharacterMatchPair({
    required this.id,
    required this.name,
    required this.description,
    required this.keyAct,
    required this.reference,
  });

  final String id;
  final String name;
  final String description;
  final String keyAct;

  /// Where [keyAct] happens; shown once the pair is matched.
  final String reference;

  factory CharacterMatchPair.fromJson(Map<String, dynamic> json) => CharacterMatchPair(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    keyAct: json['keyAct'] as String,
    reference: json['reference'] as String,
  );
}

class CharacterMatchLevel {
  const CharacterMatchLevel({required this.level, required this.title, required this.characters});

  final int level;
  final String title;
  final List<CharacterMatchPair> characters;

  factory CharacterMatchLevel.fromJson(Map<String, dynamic> json) => CharacterMatchLevel(
    level: json['level'] as int,
    title: json['title'] as String,
    characters: (json['characters'] as List)
        .map((c) => CharacterMatchPair.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList(),
  );
}
