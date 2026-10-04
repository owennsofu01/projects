import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/parable.dart';

class ParableMatchingContentLoader {
  ParableMatchingContentLoader._();

  static ParableContent? _cache;

  static Future<ParableContent> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/parable_matching.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = ParableContent(
      parables: (json['parables'] as List)
          .map((item) => Parable.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      levels:
          (json['levels'] as List).map((item) => ParableLevel.fromJson(Map<String, dynamic>.from(item as Map))).toList()
            ..sort((a, b) => a.level.compareTo(b.level)),
    );
    return _cache!;
  }
}
