/// Schema stub for the Bible Crossword mode — not yet wired to gameplay.
/// See assets/content/crossword.json for sample data in this shape.
class CrosswordClue {
  const CrosswordClue({
    required this.id,
    required this.clue,
    required this.answer,
    required this.direction,
    required this.startRow,
    required this.startCol,
  });

  final String id;
  final String clue;
  final String answer;
  final String direction; // 'across' | 'down'
  final int startRow;
  final int startCol;

  factory CrosswordClue.fromJson(Map<String, dynamic> json) => CrosswordClue(
        id: json['id'] as String,
        clue: json['clue'] as String,
        answer: json['answer'] as String,
        direction: json['direction'] as String,
        startRow: json['startRow'] as int,
        startCol: json['startCol'] as int,
      );
}
