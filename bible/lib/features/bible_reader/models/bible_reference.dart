class BibleReference {
  const BibleReference({required this.book, required this.chapter});

  final String book;
  final int chapter;

  BibleReference copyWith({String? book, int? chapter}) =>
      BibleReference(book: book ?? this.book, chapter: chapter ?? this.chapter);

  @override
  bool operator ==(Object other) => other is BibleReference && other.book == book && other.chapter == chapter;

  @override
  int get hashCode => Object.hash(book, chapter);

  @override
  String toString() => '$book $chapter';
}
