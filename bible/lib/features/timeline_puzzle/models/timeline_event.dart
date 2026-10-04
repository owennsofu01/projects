class TimelineEvent {
  const TimelineEvent({required this.id, required this.event, required this.reference, required this.order});

  final String id;
  final String event;
  final String reference;

  /// Correct chronological position (1-indexed) within its level.
  final int order;

  factory TimelineEvent.fromJson(Map<String, dynamic> json, {required int order}) => TimelineEvent(
    id: json['id'] as String,
    event: json['event'] as String,
    reference: json['reference'] as String,
    order: order,
  );
}

class TimelineLevel {
  const TimelineLevel({required this.level, required this.title, required this.events});

  final int level;
  final String title;

  /// In correct chronological order.
  final List<TimelineEvent> events;

  factory TimelineLevel.fromJson(Map<String, dynamic> json) {
    final raw = json['events'] as List;
    return TimelineLevel(
      level: json['level'] as int,
      title: json['title'] as String,
      events: [
        for (var i = 0; i < raw.length; i++)
          TimelineEvent.fromJson(Map<String, dynamic>.from(raw[i] as Map), order: i + 1),
      ],
    );
  }
}
