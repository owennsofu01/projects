class Parable {
  const Parable({
    required this.id,
    required this.parable,
    required this.reference,
    required this.lesson,
    required this.detail,
  });

  final String id;
  final String parable;
  final String reference;
  final String lesson;

  /// A memorable moment from the story, for "detail" levels.
  final String detail;

  factory Parable.fromJson(Map<String, dynamic> json) => Parable(
    id: json['id'] as String,
    parable: json['parable'] as String,
    reference: json['reference'] as String,
    lesson: json['lesson'] as String,
    detail: json['detail'] as String,
  );
}

/// What each parable is matched against in a level.
enum ParableMatchType {
  lesson('lesson', 'Tap a parable, then the lesson it teaches.'),
  detail('detail', 'Tap a parable, then the moment from its story.'),
  reference('reference', 'Tap a parable, then where it is found in Scripture.');

  const ParableMatchType(this.id, this.instructions);

  final String id;
  final String instructions;

  String answerFor(Parable p) => switch (this) {
    lesson => p.lesson,
    detail => p.detail,
    reference => p.reference,
  };

  static ParableMatchType fromJson(String value) => values.firstWhere((t) => t.id == value);
}

class ParableLevel {
  const ParableLevel({required this.level, required this.title, required this.match, required this.parableIds});

  final int level;
  final String title;
  final ParableMatchType match;
  final List<String> parableIds;

  factory ParableLevel.fromJson(Map<String, dynamic> json) => ParableLevel(
    level: json['level'] as int,
    title: json['title'] as String,
    match: ParableMatchType.fromJson(json['match'] as String),
    parableIds: List<String>.from(json['parableIds'] as List),
  );
}

class ParableContent {
  const ParableContent({required this.parables, required this.levels});

  final List<Parable> parables;
  final List<ParableLevel> levels;

  Map<String, Parable> get byId => {for (final p in parables) p.id: p};
}
