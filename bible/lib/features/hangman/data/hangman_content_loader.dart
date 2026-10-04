import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/hangman_word.dart';

class HangmanContentLoader {
  HangmanContentLoader._();

  static List<HangmanWord>? _cache;

  static Future<List<HangmanWord>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/hangman.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list.map((item) => HangmanWord.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    return _cache!;
  }
}
