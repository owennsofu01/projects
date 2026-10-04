import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/crossword_puzzle.dart';

class CrosswordContentLoader {
  CrosswordContentLoader._();

  static List<CrosswordPuzzle>? _cache;

  static Future<List<CrosswordPuzzle>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/crossword.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list.map((item) => CrosswordPuzzle.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    return _cache!;
  }
}
