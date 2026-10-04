import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/trivia_question.dart';

class TriviaContentLoader {
  TriviaContentLoader._();

  static List<TriviaQuestion>? _cache;

  static Future<List<TriviaQuestion>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/trivia.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list.map((item) => TriviaQuestion.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    return _cache!;
  }
}
