import '../../../core/models/difficulty.dart';

class CrosswordEntry {
  const CrosswordEntry({required this.clue, required this.answer});

  final String clue;

  /// Display form, may contain spaces (e.g. "RED SEA"). Grid placement uses
  /// [answer] with spaces stripped.
  final String answer;

  factory CrosswordEntry.fromJson(Map<String, dynamic> json) =>
      CrosswordEntry(clue: json['clue'] as String, answer: (json['answer'] as String).toUpperCase());
}

class CrosswordPuzzle {
  const CrosswordPuzzle({required this.id, required this.theme, required this.difficulty, required this.entries});

  final String id;
  final String theme;
  final Difficulty difficulty;
  final List<CrosswordEntry> entries;

  factory CrosswordPuzzle.fromJson(Map<String, dynamic> json) => CrosswordPuzzle(
    id: json['id'] as String,
    theme: json['theme'] as String,
    difficulty: Difficulty.fromJson(json['difficulty'] as String),
    entries: (json['entries'] as List)
        .map((e) => CrosswordEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}
