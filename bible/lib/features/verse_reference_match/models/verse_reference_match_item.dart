/// A verse to place. [tier] (1–6) groups verses by how familiar they are;
/// see TieredLevels. [chapterVerses] is how many verses the chapter has, so
/// "nearby verse" wrong answers are always real references.
class VerseReferenceMatchItem {
  const VerseReferenceMatchItem({
    required this.id,
    required this.tier,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.chapterVerses,
    required this.translation,
    required this.text,
  });

  final String id;
  final int tier;
  final String book;
  final int chapter;
  final int verse;
  final int chapterVerses;
  final String translation;
  final String text;

  String get reference => '$book $chapter:$verse';

  factory VerseReferenceMatchItem.fromJson(Map<String, dynamic> json) => VerseReferenceMatchItem(
    id: json['id'] as String,
    tier: json['tier'] as int,
    book: json['book'] as String,
    chapter: json['chapter'] as int,
    verse: json['verse'] as int,
    chapterVerses: json['chapterVerses'] as int,
    translation: json['translation'] as String,
    text: json['text'] as String,
  );
}
