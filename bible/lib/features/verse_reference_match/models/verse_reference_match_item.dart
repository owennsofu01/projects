/// Schema stub for the Verse-to-Reference Match mode — not yet wired to gameplay.
/// See assets/content/verse_reference_match.json for sample data in this shape.
class VerseReferenceMatchItem {
  const VerseReferenceMatchItem({
    required this.id,
    required this.difficulty,
    required this.verseText,
    required this.translation,
    required this.correctReference,
    required this.referenceOptions,
  });

  final String id;
  final String difficulty;
  final String verseText;
  final String translation;
  final String correctReference;
  final List<String> referenceOptions;

  factory VerseReferenceMatchItem.fromJson(Map<String, dynamic> json) => VerseReferenceMatchItem(
        id: json['id'] as String,
        difficulty: json['difficulty'] as String,
        verseText: json['verseText'] as String,
        translation: json['translation'] as String,
        correctReference: json['correctReference'] as String,
        referenceOptions: List<String>.from(json['referenceOptions'] as List),
      );
}
