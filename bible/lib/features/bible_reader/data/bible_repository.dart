import '../../../core/constants/verse_of_the_day.dart';
import '../../../core/network/bible_content_client.dart';
import '../../../core/storage/local_cache_service.dart';
import '../models/bible_reference.dart';
import '../models/bible_verse.dart';
import '../models/verse_range.dart';

/// Fetches chapter text and version listings from [BibleContentClient] and
/// caches both in the existing offline-first content cache box, so repeat
/// reads don't need the network.
class BibleRepository {
  BibleRepository(this._client);

  final BibleContentClient _client;

  static const _versionsCacheKey = 'bible:versions:eng';

  String _chapterCacheKey(String version, BibleReference ref) => 'bible:$version:${ref.book}:${ref.chapter}';

  Future<List<BibleVerse>> getChapter(BibleReference ref, String version) async {
    final cacheKey = _chapterCacheKey(version, ref);
    final cached = LocalCacheService.contentCacheBox.get(cacheKey);
    if (cached != null) {
      return (cached as List).map((e) => BibleVerse.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }

    final fetched = await _client.fetchChapter(version: version, book: ref.book, chapter: ref.chapter);
    final verses = fetched.map((v) => BibleVerse(number: v.number, text: v.text)).toList();
    await LocalCacheService.contentCacheBox.put(cacheKey, verses.map((v) => v.toJson()).toList());
    return verses;
  }

  /// Goes through [getChapter] so a passage shares the reader's chapter cache
  /// and works offline once its chapter has been loaded.
  Future<List<BibleVerse>> getPassage(VerseRange range, String version) async {
    final chapter = await getChapter(range.chapterReference, version);
    return chapter.where((v) => v.number >= range.startVerse && v.number <= range.endVerse).toList();
  }

  Future<List<BibleVersion>> getVersions() async {
    final cached = LocalCacheService.contentCacheBox.get(_versionsCacheKey);
    if (cached != null) {
      return (cached as List).map((e) => BibleVersion.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }

    final versions = await _client.fetchVersions();
    await LocalCacheService.contentCacheBox.put(_versionsCacheKey, versions.map((v) => v.toJson()).toList());
    return versions;
  }

  /// Verse text is deterministic per (version, reference), so it's cached
  /// without regard to the date — the same day-of-year always rotates back
  /// to the same reference. Never throws: falls back to bundled text if the
  /// fetch fails, so the Home hub banner is never broken by a network blip.
  Future<(String text, String reference)> getVerseOfTheDay(DateTime date, {String version = 'en-kjv'}) async {
    final ref = VerseOfTheDay.forDate(date);
    final cacheKey = 'bible:votd:$version:${ref.book}:${ref.chapter}:${ref.verse}';

    final cached = LocalCacheService.contentCacheBox.get(cacheKey);
    if (cached != null) return (cached as String, ref.reference);

    try {
      final verse = await _client.fetchVerse(version: version, book: ref.book, chapter: ref.chapter, verse: ref.verse);
      await LocalCacheService.contentCacheBox.put(cacheKey, verse.text);
      return (verse.text, ref.reference);
    } catch (_) {
      return (ref.fallbackText, ref.reference);
    }
  }
}
