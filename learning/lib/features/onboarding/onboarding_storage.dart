import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this device whether onboarding has been shown, so it only
/// appears before the very first login.
class OnboardingStorage {
  OnboardingStorage._();

  static const _key = 'onboarding_seen';

  static Future<bool> isSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      // If storage fails, skip onboarding rather than block sign-in.
      return true;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // Not critical: worst case onboarding shows once more.
    }
  }
}
