class BibleBook {
  const BibleBook(this.name, this.chapterCount);

  final String name;
  final int chapterCount;
}

/// Canonical 66-book Protestant Bible, in reading order, with fixed chapter
/// counts — used to drive the reader's book/chapter picker and prev/next
/// navigation without an extra API call.
class BibleBooks {
  BibleBooks._();

  static const List<BibleBook> oldTestament = [
    BibleBook('Genesis', 50),
    BibleBook('Exodus', 40),
    BibleBook('Leviticus', 27),
    BibleBook('Numbers', 36),
    BibleBook('Deuteronomy', 34),
    BibleBook('Joshua', 24),
    BibleBook('Judges', 21),
    BibleBook('Ruth', 4),
    BibleBook('1 Samuel', 31),
    BibleBook('2 Samuel', 24),
    BibleBook('1 Kings', 22),
    BibleBook('2 Kings', 25),
    BibleBook('1 Chronicles', 29),
    BibleBook('2 Chronicles', 36),
    BibleBook('Ezra', 10),
    BibleBook('Nehemiah', 13),
    BibleBook('Esther', 10),
    BibleBook('Job', 42),
    BibleBook('Psalms', 150),
    BibleBook('Proverbs', 31),
    BibleBook('Ecclesiastes', 12),
    BibleBook('Song of Solomon', 8),
    BibleBook('Isaiah', 66),
    BibleBook('Jeremiah', 52),
    BibleBook('Lamentations', 5),
    BibleBook('Ezekiel', 48),
    BibleBook('Daniel', 12),
    BibleBook('Hosea', 14),
    BibleBook('Joel', 3),
    BibleBook('Amos', 9),
    BibleBook('Obadiah', 1),
    BibleBook('Jonah', 4),
    BibleBook('Micah', 7),
    BibleBook('Nahum', 3),
    BibleBook('Habakkuk', 3),
    BibleBook('Zephaniah', 3),
    BibleBook('Haggai', 2),
    BibleBook('Zechariah', 14),
    BibleBook('Malachi', 4),
  ];

  static const List<BibleBook> newTestament = [
    BibleBook('Matthew', 28),
    BibleBook('Mark', 16),
    BibleBook('Luke', 24),
    BibleBook('John', 21),
    BibleBook('Acts', 28),
    BibleBook('Romans', 16),
    BibleBook('1 Corinthians', 16),
    BibleBook('2 Corinthians', 13),
    BibleBook('Galatians', 6),
    BibleBook('Ephesians', 6),
    BibleBook('Philippians', 4),
    BibleBook('Colossians', 4),
    BibleBook('1 Thessalonians', 5),
    BibleBook('2 Thessalonians', 3),
    BibleBook('1 Timothy', 6),
    BibleBook('2 Timothy', 4),
    BibleBook('Titus', 3),
    BibleBook('Philemon', 1),
    BibleBook('Hebrews', 13),
    BibleBook('James', 5),
    BibleBook('1 Peter', 5),
    BibleBook('2 Peter', 3),
    BibleBook('1 John', 5),
    BibleBook('2 John', 1),
    BibleBook('3 John', 1),
    BibleBook('Jude', 1),
    BibleBook('Revelation', 22),
  ];

  static final List<BibleBook> all = [...oldTestament, ...newTestament];

  static BibleBook byName(String name) => all.firstWhere((b) => b.name == name);

  static BibleBook? next(String name) {
    final index = all.indexWhere((b) => b.name == name);
    if (index == -1 || index == all.length - 1) return null;
    return all[index + 1];
  }

  static BibleBook? previous(String name) {
    final index = all.indexWhere((b) => b.name == name);
    if (index <= 0) return null;
    return all[index - 1];
  }
}
