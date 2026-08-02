class VerseOfTheDay {
  VerseOfTheDay._();

  /// Small public-domain (KJV) rotation. Real content should move to
  /// Firestore-hosted "content" docs so it can be refreshed without a
  /// release — see the Remote Config / Firestore-hosted content follow-up.
  static const _verses = [
    ('For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.', 'John 3:16'),
    ('I can do all things through Christ which strengtheneth me.', 'Philippians 4:13'),
    ('Trust in the Lord with all thine heart; and lean not unto thine own understanding.', 'Proverbs 3:5'),
    ('The Lord is my shepherd; I shall not want.', 'Psalm 23:1'),
    ('Be strong and of a good courage; be not afraid, neither be thou dismayed.', 'Joshua 1:9'),
    ('And we know that all things work together for good to them that love God.', 'Romans 8:28'),
    ('Fear thou not; for I am with thee: be not dismayed; for I am thy God.', 'Isaiah 41:10'),
  ];

  static (String text, String reference) forDate(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return _verses[dayOfYear % _verses.length];
  }
}
