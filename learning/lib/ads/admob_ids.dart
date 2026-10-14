import 'package:flutter/foundation.dart';

class AdMobIds {
  // ========================
  // TEST AD UNITS (Google's public demo units, used in debug builds)
  // ========================
  static const String androidInterstitialTest =
      'ca-app-pub-3940256099942544/1033173712';
  static const String androidBannerTest =
      'ca-app-pub-3940256099942544/6300978111';
  static const String androidRewardedTest =
      'ca-app-pub-3940256099942544/5224354917';
  static const String iosInterstitialTest =
      'ca-app-pub-3940256099942544/4411468910';
  static const String iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const String iosRewardedTest =
      'ca-app-pub-3940256099942544/1712485313';

  // ========================
  // PRODUCTION — ANDROID
  // App ID: ca-app-pub-2167249885961554~2417324129 (AndroidManifest.xml)
  // ========================
  static const String androidRewarded =
      'ca-app-pub-2167249885961554/9539032601';
  static const String androidInterstitial =
      'ca-app-pub-2167249885961554/9071399795';
  static const String androidBanner = 'ca-app-pub-2167249885961554/8504423580';

  // ========================
  // PRODUCTION — iOS
  // App ID: ca-app-pub-2167249885961554~2254268409 (ios/Runner/Info.plist)
  // ========================
  static const String iosRewarded = 'ca-app-pub-2167249885961554/1938693776';
  static const String iosInterstitial =
      'ca-app-pub-2167249885961554/8312530433';
  static const String iosBanner = 'ca-app-pub-2167249885961554/5394723059';

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  // Debug builds always get test ads — tapping live ads on your own
  // device violates AdMob policy and can get the account suspended.
  static String get rewarded => kDebugMode
      ? (_isIOS ? iosRewardedTest : androidRewardedTest)
      : (_isIOS ? iosRewarded : androidRewarded);
  static String get interstitial => kDebugMode
      ? (_isIOS ? iosInterstitialTest : androidInterstitialTest)
      : (_isIOS ? iosInterstitial : androidInterstitial);
  static String get banner => kDebugMode
      ? (_isIOS ? iosBannerTest : androidBannerTest)
      : (_isIOS ? iosBanner : androidBanner);
}
