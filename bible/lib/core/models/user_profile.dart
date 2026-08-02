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
    this.triviaUnlockedLevel = 1,
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

  /// Highest Bible Trivia level the user may play. Starts at 1; clearing a
  /// level with a passing score unlocks the next one.
  final int triviaUnlockedLevel;

  UserProfile copyWith({
    String? displayName,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPlayedDate,
    List<BadgeModel>? badges,
    Map<String, bool>? completedBooks,
    Map<String, int>? gamesCompletedByMode,
    int? triviaUnlockedLevel,
  }) =>
      UserProfile(
        uid: uid,
        displayName: displayName ?? this.displayName,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
        badges: badges ?? this.badges,
        completedBooks: completedBooks ?? this.completedBooks,
        gamesCompletedByMode: gamesCompletedByMode ?? this.gamesCompletedByMode,
        triviaUnlockedLevel: triviaUnlockedLevel ?? this.triviaUnlockedLevel,
      );

  factory UserProfile.guest(String uid) => UserProfile(uid: uid, displayName: 'Guest');

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String?,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastPlayedDate: json['lastPlayedDate'] == null
            ? null
            : DateTime.parse(json['lastPlayedDate'] as String),
        badges: (json['badges'] as List<dynamic>? ?? [])
            .map((b) => BadgeModel.fromJson(Map<String, dynamic>.from(b as Map)))
            .toList(),
        completedBooks: Map<String, bool>.from(json['completedBooks'] as Map? ?? {}),
        gamesCompletedByMode:
            Map<String, int>.from(json['gamesCompletedByMode'] as Map? ?? {}),
        triviaUnlockedLevel: json['triviaUnlockedLevel'] as int? ?? 1,
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
        'triviaUnlockedLevel': triviaUnlockedLevel,
      };
}
