/// A badge/certificate the user can earn (e.g. "7-Day Streak", "Timeline Master").
class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.earnedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime earnedAt;

  factory BadgeModel.fromJson(Map<String, dynamic> json) => BadgeModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        earnedAt: DateTime.parse(json['earnedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'earnedAt': earnedAt.toIso8601String(),
      };
}

/// Static catalog of every badge the app can award, keyed by id.
/// Evaluated against [UserProfile] state after each game result.
class BadgeCatalog {
  static const streak7 = (
    id: 'streak_7',
    title: '7-Day Streak',
    description: 'Played Bible GameHive 7 days in a row.',
  );
  static const streak30 = (
    id: 'streak_30',
    title: '30-Day Streak',
    description: 'Played Bible GameHive 30 days in a row.',
  );
  static const triviaNovice = (
    id: 'trivia_novice',
    title: 'Trivia Novice',
    description: 'Completed 10 Bible Trivia rounds.',
  );
  static const verseMaster = (
    id: 'verse_master',
    title: 'Verse Master',
    description: 'Completed 10 Verse Completion rounds.',
  );
  static const wordSeeker = (
    id: 'word_seeker',
    title: 'Word Seeker',
    description: 'Completed 10 Word Search puzzles.',
  );

  static const all = [streak7, streak30, triviaNovice, verseMaster, wordSeeker];
}
