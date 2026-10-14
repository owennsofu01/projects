import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Not awaited: ad SDK startup shouldn't delay the first frame.
  MobileAds.instance.initialize();

  // Inject AuthController once, for the lifetime of the app
  Get.put(AuthController(), permanent: true);

  runApp(const App());
}
