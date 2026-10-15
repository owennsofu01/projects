import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
// latest_all keeps alias zones (e.g. Africa/Lusaka) that phones report;
// latest drops them.
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The text of one day's summary notification.
typedef SummaryMessage = ({String title, String body});

/// Schedules the end-of-day summary on the device itself, so it works
/// offline and needs no server.
///
/// A scheduled notification's text is fixed when it's scheduled, so
/// today's is rescheduled with fresh totals whenever the day's sales or
/// expenses change. Days ahead get a generic message, which is replaced
/// with real totals as soon as anything is recorded on that day.
class DailySummaryNotifier {
  DailySummaryNotifier._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// How many days ahead to schedule; topped up on every launch and change.
  static const _daysAhead = 7;
  static const _firstId = 2000;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_summary',
      'Daily summary',
      channelDescription:
          "An end-of-day summary of the day's sales and profit.",
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const SummaryMessage noSalesMessage = (
    title: 'Daily summary',
    body: 'No sales recorded today yet — tap to add them.',
  );

  static Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (e) {
      debugPrint('DailySummaryNotifier: falling back to UTC ($e)');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked when the user turns the summary on, not at
        // launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Asks for notification permission (Android 13+, iOS). Returns false if
  /// denied.
  static Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ??
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
  }

  /// Replaces every scheduled summary: today's (if its time is still
  /// ahead) with [today], and the following days with [noSalesMessage].
  static Future<void> reschedule({
    required bool enabled,
    required int hour,
    required int minute,
    required SummaryMessage today,
  }) async {
    await init();
    for (var i = 0; i < _daysAhead; i++) {
      await _plugin.cancel(id: _firstId + i);
    }
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    for (final (i, date) in summaryDates(
      now: now,
      hour: hour,
      minute: minute,
    ).indexed) {
      final isToday = date.day == now.day && date.month == now.month;
      final message = isToday ? today : noSalesMessage;
      await _plugin.zonedSchedule(
        id: _firstId + i,
        scheduledDate: date,
        notificationDetails: _details,
        // Inexact is fine for a daily summary and needs no exact-alarm
        // permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: message.title,
        body: message.body,
      );
    }
  }

  /// The next [days] summary times from [now], starting today if [hour]:
  /// [minute] is still ahead.
  @visibleForTesting
  static List<tz.TZDateTime> summaryDates({
    required tz.TZDateTime now,
    required int hour,
    required int minute,
    int days = _daysAhead,
  }) {
    var first = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));
    return [
      for (var i = 0; i < days; i++)
        tz.TZDateTime(
          first.location,
          first.year,
          first.month,
          first.day + i,
          hour,
          minute,
        ),
    ];
  }
}
