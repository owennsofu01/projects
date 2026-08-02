import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Daily "Verse of the Day" reminders and streak-at-risk nudges. Actual
/// scheduling of the daily push happens server-side (Cloud Scheduler / a
/// Cloud Function targeting the `daily_verse` topic) — this service only
/// handles the client side: permission, token, and topic subscription.
class MessagingService {
  MessagingService({FirebaseMessaging? messaging}) : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  static const dailyVerseTopic = 'daily_verse';
  static const streakRiskTopic = 'streak_at_risk';

  Future<void> init({required bool notificationsEnabled}) async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    if (notificationsEnabled) {
      await subscribeToReminders();
    } else {
      await unsubscribeFromReminders();
    }
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message: ${message.notification?.title}');
    });
  }

  Future<void> subscribeToReminders() async {
    await _messaging.subscribeToTopic(dailyVerseTopic);
    await _messaging.subscribeToTopic(streakRiskTopic);
  }

  Future<void> unsubscribeFromReminders() async {
    await _messaging.unsubscribeFromTopic(dailyVerseTopic);
    await _messaging.unsubscribeFromTopic(streakRiskTopic);
  }

  Future<String?> getToken() => _messaging.getToken();
}
