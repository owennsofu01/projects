import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/audio/sound_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/settings_providers.dart';

class BibleGameHiveApp extends ConsumerStatefulWidget {
  const BibleGameHiveApp({super.key});

  @override
  ConsumerState<BibleGameHiveApp> createState() => _BibleGameHiveAppState();
}

class _BibleGameHiveAppState extends ConsumerState<BibleGameHiveApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        final settings = ref.read(settingsProvider);
        SoundService.configure(
          soundOn: settings.soundOn,
          musicOn: settings.musicOn,
          customMusicPath: settings.customMusicPath,
        );
      },
      onInactive: () => SoundService.pauseMusic(),
      onPause: () => SoundService.pauseMusic(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    SoundService.configure(
      soundOn: settings.soundOn,
      musicOn: settings.musicOn,
      customMusicPath: settings.customMusicPath,
    );

    return MaterialApp.router(
      title: 'Bible GameHive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(fontScale: settings.fontScale, highContrast: settings.highContrast),
      darkTheme: AppTheme.dark(fontScale: settings.fontScale, highContrast: settings.highContrast),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
