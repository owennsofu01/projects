/// Named, quickly-selectable date ranges for a report, plus a fully custom
/// option backed by explicit [ReportRange.start]/[ReportRange.end] values.
enum ReportPreset { today, thisWeek, thisMonth, custom }

class ReportRange {
  final ReportPreset preset;
  final DateTime start;

  /// Exclusive upper bound — end of the selected day, so a same-day range
  /// still includes that day's records.
  final DateTime end;

  const ReportRange({required this.preset, required this.start, required this.end});

  factory ReportRange.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return ReportRange(
      preset: ReportPreset.today,
      start: start,
      end: start.add(const Duration(days: 1)),
    );
  }

  factory ReportRange.thisWeek() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final start = todayStart.subtract(Duration(days: now.weekday - 1));
    return ReportRange(
      preset: ReportPreset.thisWeek,
      start: start,
      end: todayStart.add(const Duration(days: 1)),
    );
  }

  factory ReportRange.thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final todayStart = DateTime(now.year, now.month, now.day);
    return ReportRange(
      preset: ReportPreset.thisMonth,
      start: start,
      end: todayStart.add(const Duration(days: 1)),
    );
  }

  factory ReportRange.custom(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return ReportRange(
      preset: ReportPreset.custom,
      start: startDay,
      end: endDay.add(const Duration(days: 1)),
    );
  }

  String get label {
    switch (preset) {
      case ReportPreset.today:
        return 'Today';
      case ReportPreset.thisWeek:
        return 'This Week';
      case ReportPreset.thisMonth:
        return 'This Month';
      case ReportPreset.custom:
        return 'Custom';
    }
  }
}
