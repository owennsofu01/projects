import 'package:flutter_test/flutter_test.dart';
import 'package:profitpulse/features/daily_summary/services/daily_summary_notifier.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  tz.Location lusaka() => tz.getLocation('Africa/Lusaka');

  test('starts today when the summary time is still ahead', () {
    final now = tz.TZDateTime(lusaka(), 2026, 10, 14, 9, 30);
    final dates = DailySummaryNotifier.summaryDates(
      now: now,
      hour: 20,
      minute: 0,
    );

    expect(dates, hasLength(7));
    expect(dates.first, tz.TZDateTime(lusaka(), 2026, 10, 14, 20));
    expect(dates.last, tz.TZDateTime(lusaka(), 2026, 10, 20, 20));
  });

  test('starts tomorrow once the summary time has passed', () {
    final now = tz.TZDateTime(lusaka(), 2026, 10, 14, 20, 0);
    final dates = DailySummaryNotifier.summaryDates(
      now: now,
      hour: 20,
      minute: 0,
    );

    expect(dates.first, tz.TZDateTime(lusaka(), 2026, 10, 15, 20));
  });

  test('rolls over month ends', () {
    final now = tz.TZDateTime(lusaka(), 2026, 10, 30, 21);
    final dates = DailySummaryNotifier.summaryDates(
      now: now,
      hour: 20,
      minute: 0,
      days: 3,
    );

    expect(dates, [
      tz.TZDateTime(lusaka(), 2026, 10, 31, 20),
      tz.TZDateTime(lusaka(), 2026, 11, 1, 20),
      tz.TZDateTime(lusaka(), 2026, 11, 2, 20),
    ]);
  });
}
