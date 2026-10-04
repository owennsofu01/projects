class VerseOfTheDayReference {
  const VerseOfTheDayReference({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.fallbackText,
  });

  final String book;
  final int chapter;
  final int verse;

  /// Shown if the live fetch fails (e.g. first launch while offline), so
  /// the Home hub's banner never looks broken.
  final String fallbackText;

  String get reference => '$book $chapter:$verse';
}

class VerseOfTheDay {
  VerseOfTheDay._();

  /// Small rotation of well-known references. Text is fetched live from
  /// the Bible content API per the selected translation — see
  /// [VerseOfTheDayReference.fallbackText] for the offline fallback.
  static const _references = [
    VerseOfTheDayReference(
      book: 'John',
      chapter: 3,
      verse: 16,
      fallbackText:
          'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
    ),
    VerseOfTheDayReference(
      book: 'Philippians',
      chapter: 4,
      verse: 13,
      fallbackText: 'I can do all things through Christ which strengtheneth me.',
    ),
    VerseOfTheDayReference(
      book: 'Proverbs',
      chapter: 3,
      verse: 5,
      fallbackText: 'Trust in the Lord with all thine heart; and lean not unto thine own understanding.',
    ),
    VerseOfTheDayReference(
      book: 'Psalms',
      chapter: 23,
      verse: 1,
      fallbackText: 'The Lord is my shepherd; I shall not want.',
    ),
    VerseOfTheDayReference(
      book: 'Joshua',
      chapter: 1,
      verse: 9,
      fallbackText: 'Be strong and of a good courage; be not afraid, neither be thou dismayed.',
    ),
    VerseOfTheDayReference(
      book: 'Romans',
      chapter: 8,
      verse: 28,
      fallbackText: 'And we know that all things work together for good to them that love God.',
    ),
    VerseOfTheDayReference(
      book: 'Isaiah',
      chapter: 41,
      verse: 10,
      fallbackText: 'Fear thou not; for I am with thee: be not dismayed; for I am thy God.',
    ),
  ];

  static VerseOfTheDayReference forDate(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return _references[dayOfYear % _references.length];
  }
}
