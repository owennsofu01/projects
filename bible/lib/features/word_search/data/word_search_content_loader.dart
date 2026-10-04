import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/word_search_puzzle.dart';

class WordSearchContentLoader {
  WordSearchContentLoader._();

  static List<WordSearchPuzzle>? _cache;

  static Future<List<WordSearchPuzzle>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/word_search.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list.map((item) => WordSearchPuzzle.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    return _cache!;
  }
}
