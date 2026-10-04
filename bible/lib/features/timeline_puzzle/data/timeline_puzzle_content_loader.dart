import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/timeline_event.dart';

class TimelinePuzzleContentLoader {
  TimelinePuzzleContentLoader._();

  static List<TimelineLevel>? _cache;

  static Future<List<TimelineLevel>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/timeline_puzzle.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (json['levels'] as List).map((l) => TimelineLevel.fromJson(Map<String, dynamic>.from(l as Map))).toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    return _cache!;
  }
}
