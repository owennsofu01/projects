import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/match3_level.dart';

class Match3ContentLoader {
  Match3ContentLoader._();

  static List<Match3Level>? _cache;

  static Future<List<Match3Level>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/match3.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final levels = list.map((item) => Match3Level.fromJson(Map<String, dynamic>.from(item as Map))).toList()
      ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
    _cache = levels;
    return _cache!;
  }
}
