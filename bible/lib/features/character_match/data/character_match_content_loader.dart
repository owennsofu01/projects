import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/character_match_pair.dart';

class CharacterMatchContentLoader {
  CharacterMatchContentLoader._();

  static List<CharacterMatchLevel>? _cache;

  static Future<List<CharacterMatchLevel>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/character_match.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache =
        (json['levels'] as List).map((l) => CharacterMatchLevel.fromJson(Map<String, dynamic>.from(l as Map))).toList()
          ..sort((a, b) => a.level.compareTo(b.level));
    return _cache!;
  }
}
