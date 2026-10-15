/// Whether and when to send the end-of-day summary notification. Stored as
/// a `dailySummary` map on the user's Firestore doc.
class DailySummarySettings {
  final bool enabled;
  final int hour;
  final int minute;

  const DailySummarySettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
  });

  static const defaults = DailySummarySettings();

  factory DailySummarySettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return defaults;
    return DailySummarySettings(
      enabled: data['enabled'] as bool? ?? false,
      hour: (data['hour'] as num?)?.toInt() ?? 20,
      minute: (data['minute'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
  };

  DailySummarySettings copyWith({bool? enabled, int? hour, int? minute}) {
    return DailySummarySettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}
