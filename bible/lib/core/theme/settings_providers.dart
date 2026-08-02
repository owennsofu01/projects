import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../storage/local_cache_service.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(_load());

  static const _key = 'app_settings';

  static AppSettings _load() {
    final raw = LocalCacheService.settingsBox.get(_key);
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  void _persist() => LocalCacheService.settingsBox.put(_key, state.toJson());

  void update(AppSettings Function(AppSettings) updater) {
    state = updater(state);
    _persist();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);
