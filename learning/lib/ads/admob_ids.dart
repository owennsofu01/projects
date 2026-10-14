import 'package:flutter/foundation.dart';

class AdMobIds {
  // ========================
  // TEST AD UNITS
  // ========================
  static const String interstitialTest =
      'ca-app-pub-3940256099942544/1033173712';
  static const String bannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const String rewardedTest = 'ca-app-pub-3940256099942544/5224354917';

  // ========================
  // PRODUCTION — ANDROID
  // App ID: ca-app-pub-2167249885961554~2417324129 (AndroidManifest.xml)
  // ========================
  static const String androidRewarded = 'ca-app-pub-2167249885961554/9539032601';
  static const String androidInterstitial =
      'ca-app-pub-2167249885961554/9071399795';
  static const String androidBanner = 'ca-app-pub-2167249885961554/8504423580';

  // ========================
  // PRODUCTION — iOS
  // App ID: ca-app-pub-2167249885961554~2254268409 (ios/Runner/Info.plist)
  // ========================
  static const String iosRewarded = 'ca-app-pub-2167249885961554/1938693776';
  static const String iosInterstitial = 'ca-app-pub-2167249885961554/8312530433';
  static const String iosBanner = 'ca-app-pub-2167249885961554/5394723059';

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static String get rewarded => _isIOS ? iosRewarded : androidRewarded;
  static String get interstitial =>
      _isIOS ? iosInterstitial : androidInterstitial;
  static String get banner => _isIOS ? iosBanner : androidBanner;
}
