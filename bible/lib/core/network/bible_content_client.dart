import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown when the Bible content CDN is unreachable or returns something we
/// can't parse. The message is safe to surface directly in the UI.
class BibleApiException implements Exception {
  BibleApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BibleVerseData {
  const BibleVerseData({required this.number, required this.text});

  final int number;
  final String text;
}

class BibleVersion {
  const BibleVersion({required this.id, required this.name, required this.abbreviation});

  final String id;
  final String name;
  final String abbreviation;

  factory BibleVersion.fromJson(Map<String, dynamic> json) {
    final abbreviation = json['localVersionAbbreviation'] as String?;
    return BibleVersion(
      id: json['id'] as String,
      name: json['version'] as String,
      abbreviation: (abbreviation != null && abbreviation.trim().isNotEmpty)
          ? abbreviation
          : (json['id'] as String).toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'version': name, 'localVersionAbbreviation': abbreviation};
}

/// Fetches chapter text from the wldeh/bible-api static JSON dataset,
/// mirrored on jsDelivr's CDN — no API key required.
/// https://github.com/wldeh/bible-api
class BibleContentClient {
  static const _baseUrl = 'https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles';

  static String slugifyBook(String book) => book.toLowerCase().replaceAll(' ', '');

  /// Only English, full-canon versions — the dataset also has 190+ other
  /// languages and many New-Testament-only / Old-Testament-only entries
  /// that would 404 for whichever half of the Bible they're missing.
  Future<List<BibleVersion>> fetchVersions() async {
    final uri = Uri.parse('$_baseUrl/bibles.json');

    final http.Response response;
    try {
      response = await http.get(uri);
    } catch (e) {
      throw BibleApiException('Could not reach the Bible content service: $e');
    }

    if (response.statusCode != 200) {
      throw BibleApiException('Could not load Bible versions (${response.statusCode}).');
    }

    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as List<dynamic>;
    } catch (e) {
      throw BibleApiException('Unexpected response loading Bible versions: $e');
    }

    final versions =
        decoded
            .map((e) => e as Map<String, dynamic>)
            .where((e) => (e['language'] as Map<String, dynamic>?)?['code'] == 'eng')
            .where((e) => (e['scope'] as String?)?.startsWith('Bible') ?? false)
            .map(BibleVersion.fromJson)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return versions;
  }

  Future<List<BibleVerseData>> fetchChapter({
    required String version,
    required String book,
    required int chapter,
  }) async {
    final uri = Uri.parse('$_baseUrl/$version/books/${slugifyBook(book)}/chapters/$chapter.json');

    final http.Response response;
    try {
      response = await http.get(uri);
    } catch (e) {
      throw BibleApiException('Could not reach the Bible content service: $e');
    }

    if (response.statusCode != 200) {
      throw BibleApiException('Bible content not found for "$book $chapter" (${response.statusCode}).');
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw BibleApiException('Unexpected response for "$book $chapter": $e');
    }

    final data = decoded['data'] as List? ?? const [];
    final verses = data.map((raw) {
      final entry = raw as Map<String, dynamic>;
      final number = int.parse(entry['verse'] as String);
      return BibleVerseData(number: number, text: _cleanVerseText(entry['text'] as String, chapter, number));
    }).toList()..sort((a, b) => a.number.compareTo(b.number));

    if (verses.isEmpty) {
      throw BibleApiException('No verses found for "$book $chapter".');
    }
    return verses;
  }

  Future<BibleVerseData> fetchVerse({
    required String version,
    required String book,
    required int chapter,
    required int verse,
  }) async {
    final uri = Uri.parse('$_baseUrl/$version/books/${slugifyBook(book)}/chapters/$chapter/verses/$verse.json');

    final http.Response response;
    try {
      response = await http.get(uri);
    } catch (e) {
      throw BibleApiException('Could not reach the Bible content service: $e');
    }

    if (response.statusCode != 200) {
      throw BibleApiException('Verse not found for "$book $chapter:$verse" (${response.statusCode}).');
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw BibleApiException('Unexpected response for "$book $chapter:$verse": $e');
    }

    return BibleVerseData(number: verse, text: _cleanVerseText(decoded['text'] as String, chapter, verse));
  }

  // The dataset appends footnotes directly after the verse text as
  // "<chapter>.<verse> <note>" with no separating punctuation, and prefixes
  // some verses with a paragraph pilcrow — strip both since callers render
  // clean verse-only text.
  static String _cleanVerseText(String raw, int chapter, int verse) {
    var text = raw.trim();
    final footnoteMarker = '$chapter.$verse ';
    final markerIndex = text.indexOf(footnoteMarker);
    if (markerIndex > 0) {
      text = text.substring(0, markerIndex).trimRight();
    }
    return text.replaceFirst(RegExp(r'^¶\s*'), '');
  }
}
