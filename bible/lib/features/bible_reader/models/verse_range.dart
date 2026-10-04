import 'bible_reference.dart';

/// A single verse or a same-chapter verse range, parsed from strings like
/// "Genesis 2:7" or "1 Samuel 17:48-49".
class VerseRange {
  const VerseRange({required this.book, required this.chapter, required this.startVerse, required this.endVerse});

  final String book;
  final int chapter;
  final int startVerse;
  final int endVerse;

  static final _pattern = RegExp(r'^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$');

  static VerseRange? tryParse(String input) {
    final match = _pattern.firstMatch(input.trim());
    if (match == null) return null;
    final start = int.parse(match.group(3)!);
    final end = match.group(4) == null ? start : int.parse(match.group(4)!);
    if (end < start) return null;
    return VerseRange(book: match.group(1)!, chapter: int.parse(match.group(2)!), startVerse: start, endVerse: end);
  }

  BibleReference get chapterReference => BibleReference(book: book, chapter: chapter);

  @override
  String toString() => startVerse == endVerse ? '$book $chapter:$startVerse' : '$book $chapter:$startVerse-$endVerse';
}
