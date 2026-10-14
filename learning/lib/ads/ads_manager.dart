import 'dart:async';
import 'admob_ids.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// =================================================================
/// BASE CLASS – Common utilities for all ad controllers
/// =================================================================
abstract class BaseAdController extends GetxController {
  void retry(Function loadFunc, {int seconds = 10}) {
    Future.delayed(Duration(seconds: seconds), () => loadFunc());
  }

  void logError(Object error, [String source = "Ad"]) {
    debugPrint("❌ $source Error: $error");
  }
}

/// =================================================================
/// INTERSTITIAL AD CONTROLLER
/// =================================================================
class InterstitialAdController extends BaseAdController {
  InterstitialAd? _interstitialAd;
  bool _isLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _loadAd();
  }

  void _loadAd() {
    InterstitialAd.load(
      adUnitId: AdMobIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoaded = true;
          debugPrint("✅ Interstitial Loaded");
        },
        onAdFailedToLoad: (error) {
          _isLoaded = false;
          logError(error, "Interstitial");
          retry(_loadAd);
        },
      ),
    );
  }

  void show() {
    if (!_isLoaded || _interstitialAd == null) {
      debugPrint("⚠️ Interstitial Not Ready");
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isLoaded = false;
        _loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        logError(error, "Interstitial");
        ad.dispose();
        _isLoaded = false;
        _loadAd();
      },
    );

    _interstitialAd!.show();
  }

  @override
  void onClose() {
    _interstitialAd?.dispose();
    super.onClose();
  }
}

/// =================================================================
/// TIMED BANNER AD – Appears after delay + auto hides
/// =================================================================
class TimedBannerAd extends StatefulWidget {
  const TimedBannerAd({super.key});

  @override
  State<TimedBannerAd> createState() => _TimedBannerAdState();
}

class _TimedBannerAdState extends State<TimedBannerAd> {
  BannerAd? _bannerAd;
  bool _visible = false;
  Timer? _initialDelay, _repeatTimer, _hideTimer;

  @override
  void initState() {
    super.initState();

    // Show first banner after 40 seconds
    _initialDelay = Timer(const Duration(seconds: 40), () {
      _loadBanner();

      // Repeat banner every 10 minutes
      _repeatTimer = Timer.periodic(
        const Duration(minutes: 10),
        (_) => _loadBanner(),
      );
    });
  }

  void _loadBanner() {
    _bannerAd?.dispose();
    setState(() => _visible = false);

    _bannerAd = BannerAd(
      adUnitId: AdMobIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() => _visible = true);

          // Hide banner after 30 seconds
          _hideTimer?.cancel();
          _hideTimer = Timer(
            const Duration(seconds: 30),
            () => setState(() => _visible = false),
          );
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("❌ Banner Error: $error");
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _initialDelay?.cancel();
    _repeatTimer?.cancel();
    _hideTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _visible && _bannerAd != null
        ? Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          )
        : const SizedBox.shrink();
  }
}

/// =================================================================
/// REWARDED AD CONTROLLER
/// =================================================================
class AdsController extends BaseAdController {
  RewardedAd? _rewardedAd;
  final isReady = false.obs;
  final areAdsEnabled = true.obs;

  Timer? _autoShowTimer;

  @override
  void onInit() {
    super.onInit();
    _loadAd();

    // Auto-show reward every 4 minutes
    _autoShowTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) {
        if (areAdsEnabled.value) {
          isReady.value ? show() : _loadAd();
        }
      },
    );
  }

  void _loadAd() {
    RewardedAd.load(
      adUnitId: AdMobIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isReady.value = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              isReady.value = false;
              _loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              logError(error, "Rewarded");
              ad.dispose();
              isReady.value = false;
              _loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          isReady.value = false;
          logError(error, "Rewarded");
          retry(_loadAd);
        },
      ),
    );
  }

  void show() {
    if (!isReady.value || _rewardedAd == null) {
      debugPrint("⚠️ Rewarded Ad Not Ready");
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint("🎁 Reward Earned: ${reward.amount} ${reward.type}");
      },
    );
  }

  @override
  void onClose() {
    _autoShowTimer?.cancel();
    _rewardedAd?.dispose();
    super.onClose();
  }
}
