import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/verse_reference_match_item.dart';

class VerseReferenceMatchContentLoader {
  VerseReferenceMatchContentLoader._();

  static List<VerseReferenceMatchItem>? _cache;

  static Future<List<VerseReferenceMatchItem>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/verse_reference_match.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list.map((item) => VerseReferenceMatchItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    return _cache!;
  }
}
