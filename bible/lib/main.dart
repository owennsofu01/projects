import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/auth_service.dart';
import 'core/firebase/crashlytics_service.dart';
import 'core/firebase/messaging_service.dart';
import 'core/storage/local_cache_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalCacheService.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CrashlyticsService.init();

  // Every user starts as an anonymous guest so they can play immediately;
  // signing up later links the chosen provider onto this same account.
  await AuthService().signInAnonymouslyIfNeeded();

  try {
    await MessagingService().init(notificationsEnabled: true);
  } catch (_) {
    // Push permission can be denied or unavailable (e.g. simulators without
    // full APNs setup) — the app is fully playable without it.
  }

  runApp(const ProviderScope(child: BibleGameHiveApp()));
}
