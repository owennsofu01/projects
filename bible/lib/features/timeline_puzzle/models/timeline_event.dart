/// Schema stub for the Timeline Puzzle mode — not yet wired to gameplay.
/// See assets/content/timeline_puzzle.json for sample data in this shape.
class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.event,
    required this.era,
    required this.order,
  });

  final String id;
  final String event;
  final String era;

  /// Correct chronological position (1-indexed) within its puzzle set.
  final int order;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
        id: json['id'] as String,
        event: json['event'] as String,
        era: json['era'] as String,
        order: json['order'] as int,
      );
}
