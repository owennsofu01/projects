import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/map_location.dart';

class MapPuzzleContentLoader {
  MapPuzzleContentLoader._();

  static List<MapLevel>? _levels;
  static MapGeography? _geography;

  static Future<List<MapLevel>> loadLevels() async {
    if (_levels != null) return _levels!;
    final raw = await rootBundle.loadString('assets/content/map_puzzle.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _levels = (json['levels'] as List).map((l) => MapLevel.fromJson(Map<String, dynamic>.from(l as Map))).toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    return _levels!;
  }

  static Future<MapGeography> loadGeography() async {
    if (_geography != null) return _geography!;
    final raw = await rootBundle.loadString('assets/content/map_geography.json');
    _geography = MapGeography.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _geography!;
  }
}
