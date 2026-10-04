import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/guess_who_character.dart';

class GuessWhoContentLoader {
  GuessWhoContentLoader._();

  static List<GuessWhoCharacter>? _cache;

  static Future<List<GuessWhoCharacter>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/guess_who.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list.map((item) => GuessWhoCharacter.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    return _cache!;
  }
}
