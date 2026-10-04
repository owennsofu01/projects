import 'badge_model.dart';

/// Aggregate progress state for the signed-in (or guest) user.
/// Persisted local-first in Hive, mirrored to Firestore at `users/{uid}`.
class UserProfile {
  const UserProfile({
    required this.uid,
    this.displayName,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPlayedDate,
    this.badges = const [],
    this.completedBooks = const {},
    this.gamesCompletedByMode = const {},
    this.levelStars = const {},
    this.totalPoints = 0,
  });

  final String uid;
  final String? displayName;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPlayedDate;
  final List<BadgeModel> badges;

  /// Book name -> true once the user has completed book-scoped content for it.
  final Map<String, bool> completedBooks;

  /// Game mode id -> number of rounds completed. Drives "Continue"/badge logic.
  final Map<String, int> gamesCompletedByMode;

  /// Game mode id -> level -> best stars earned (1-3; absent = never
  /// passed). Shared by every leveled mode; see [LevelRules].
  final Map<String, Map<int, int>> levelStars;

  int starsFor(String gameModeId, int level) => levelStars[gameModeId]?[level] ?? 0;

  int totalStars(String gameModeId) => (levelStars[gameModeId] ?? const {}).values.fold(0, (a, b) => a + b);

  /// Highest playable level: one past the highest level passed, so level 1
  /// is always open.
  int unlockedLevel(String gameModeId) {
    final passed = (levelStars[gameModeId] ?? const {}).entries.where((e) => e.value > 0).map((e) => e.key);
    return passed.isEmpty ? 1 : passed.reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Sum of every recorded round's score across all game modes; drives the
  /// global leaderboard.
  final int totalPoints;

  UserProfile copyWith({
    String? displayName,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPlayedDate,
    List<BadgeModel>? badges,
    Map<String, bool>? completedBooks,
    Map<String, int>? gamesCompletedByMode,
    Map<String, Map<int, int>>? levelStars,
    int? totalPoints,
  }) => UserProfile(
    uid: uid,
    displayName: displayName ?? this.displayName,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
    badges: badges ?? this.badges,
    completedBooks: completedBooks ?? this.completedBooks,
    gamesCompletedByMode: gamesCompletedByMode ?? this.gamesCompletedByMode,
    levelStars: levelStars ?? this.levelStars,
    totalPoints: totalPoints ?? this.totalPoints,
  );

  factory UserProfile.guest(String uid) => UserProfile(uid: uid, displayName: 'Guest');

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'] as String,
    displayName: json['displayName'] as String?,
    currentStreak: json['currentStreak'] as int? ?? 0,
    longestStreak: json['longestStreak'] as int? ?? 0,
    lastPlayedDate: json['lastPlayedDate'] == null ? null : DateTime.parse(json['lastPlayedDate'] as String),
    badges: (json['badges'] as List<dynamic>? ?? [])
        .map((b) => BadgeModel.fromJson(Map<String, dynamic>.from(b as Map)))
        .toList(),
    completedBooks: Map<String, bool>.from(json['completedBooks'] as Map? ?? {}),
    gamesCompletedByMode: Map<String, int>.from(json['gamesCompletedByMode'] as Map? ?? {}),
    levelStars: _levelStarsFromJson(json),
    totalPoints: json['totalPoints'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastPlayedDate': lastPlayedDate?.toIso8601String(),
    'badges': badges.map((b) => b.toJson()).toList(),
    'completedBooks': completedBooks,
    'gamesCompletedByMode': gamesCompletedByMode,
    // JSON (and Firestore) map keys must be strings.
    'levelStars': levelStars.map(
      (mode, levels) => MapEntry(mode, levels.map((level, stars) => MapEntry('$level', stars))),
    ),
    'totalPoints': totalPoints,
  };

  /// Reads `levelStars`, and migrates profiles saved before stars existed:
  /// each old `<mode>UnlockedLevel` = N means levels 1..N-1 were passed, so
  /// they start at one star and nobody loses unlocked levels.
  static Map<String, Map<int, int>> _levelStarsFromJson(Map<String, dynamic> json) {
    final stars = <String, Map<int, int>>{
      for (final entry in (json['levelStars'] as Map? ?? {}).entries)
        entry.key as String: {
          for (final level in (entry.value as Map).entries) int.parse(level.key as String): level.value as int,
        },
    };
    const legacyFields = {
      'trivia': 'triviaUnlockedLevel',
      'guess_who': 'guessWhoUnlockedLevel',
      'hangman': 'hangmanUnlockedLevel',
    };
    legacyFields.forEach((mode, field) {
      final unlocked = json[field] as int?;
      if (unlocked == null || unlocked <= 1) return;
      final levels = stars.putIfAbsent(mode, () => {});
      for (var level = 1; level < unlocked; level++) {
        levels.putIfAbsent(level, () => 1);
      }
    });
    return stars;
  }
}
