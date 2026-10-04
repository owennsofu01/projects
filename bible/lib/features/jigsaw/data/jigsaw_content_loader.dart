import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/jigsaw_scene.dart';

class JigsawContentLoader {
  JigsawContentLoader._();

  static List<JigsawScene>? _cache;

  static Future<List<JigsawScene>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/content/jigsaw.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list.map((item) => JigsawScene.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    return _cache!;
  }
}
