import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/verse_completion_item.dart';

class VerseCompletionContentLoader {
  VerseCompletionContentLoader._();

  static List<VerseCompletionItem>? _cache;

  static Future<List<VerseCompletionItem>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/verse_completion.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list
        .map((item) => VerseCompletionItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return _cache!;
  }
}
