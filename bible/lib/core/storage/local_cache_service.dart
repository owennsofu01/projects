import 'package:hive_flutter/hive_flutter.dart';

/// Thin wrapper over Hive giving the rest of the app named, typed boxes
/// instead of raw box lookups scattered everywhere. Everything is stored as
/// plain JSON-compatible maps — no generated TypeAdapters — so game content
/// and progress records can be added without a codegen step.
class LocalCacheService {
  LocalCacheService._();

  static const settingsBoxName = 'settings';
  static const profileBoxName = 'profile';
  static const gameResultsBoxName = 'game_results';
  static const contentCacheBoxName = 'content_cache';

  static late Box<dynamic> settingsBox;
  static late Box<dynamic> profileBox;
  static late Box<dynamic> gameResultsBox;
  static late Box<dynamic> contentCacheBox;

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    settingsBox = await Hive.openBox(settingsBoxName);
    profileBox = await Hive.openBox(profileBoxName);
    gameResultsBox = await Hive.openBox(gameResultsBoxName);
    contentCacheBox = await Hive.openBox(contentCacheBoxName);
    _initialized = true;
  }
}
