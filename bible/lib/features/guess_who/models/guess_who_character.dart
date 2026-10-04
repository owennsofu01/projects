class GuessWhoCharacter {
  const GuessWhoCharacter({
    required this.id,
    required this.characterName,
    required this.level,
    required this.clues,
    this.references = const [],
    this.aliases = const [],
  });

  final String id;
  final String characterName;

  /// 1-20; higher levels use more obscure figures and less generous clues.
  final int level;

  /// Revealed one at a time, hardest/most-obscure clue first.
  final List<String> clues;

  /// Scripture reference for each clue, index-aligned with [clues]
  /// (e.g. "Genesis 2:7" or "Genesis 2:19-20").
  final List<String> references;

  /// Other accepted answers, e.g. "Pilate" for Pontius Pilate.
  final List<String> aliases;

  /// Whether [guess] names this character, ignoring case and extra spaces.
  bool matches(String guess) {
    String normalize(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final g = normalize(guess);
    return [characterName, ...aliases].any((name) => normalize(name) == g);
  }

  String? referenceFor(int clueIndex) => clueIndex < references.length ? references[clueIndex] : null;

  factory GuessWhoCharacter.fromJson(Map<String, dynamic> json) => GuessWhoCharacter(
    id: json['id'] as String,
    characterName: json['characterName'] as String,
    level: json['level'] as int,
    clues: List<String>.from(json['clues'] as List),
    references: List<String>.from(json['references'] as List? ?? const []),
    aliases: List<String>.from(json['aliases'] as List? ?? const []),
  );
}
