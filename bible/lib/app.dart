import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/settings_providers.dart';

class BibleGameHiveApp extends ConsumerWidget {
  const BibleGameHiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

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
