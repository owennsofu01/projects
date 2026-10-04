import 'package:cloud_firestore/cloud_firestore.dart';

/// Public, leaderboard-facing view of a player at `players/{uid}`. Kept
/// separate from the private `users/{uid}` profile so other players can read
/// it without seeing settings or progress details.
class PlayerEntry {
  const PlayerEntry({
    required this.uid,
    required this.displayName,
    required this.totalScore,
    this.friendCode,
    this.dailyStreak = 0,
  });

  final String uid;
  final String displayName;
  final int totalScore;
  final String? friendCode;
  final int dailyStreak;

  factory PlayerEntry.fromJson(Map<String, dynamic> json) => PlayerEntry(
    uid: json['uid'] as String,
    displayName: json['displayName'] as String? ?? 'Player',
    totalScore: json['totalScore'] as int? ?? 0,
    friendCode: json['friendCode'] as String?,
    dailyStreak: json['dailyStreak'] as int? ?? 0,
  );
}

/// One player's attempt at a day's challenge, at `daily/{dayKey}/entries/{uid}`.
class DailyEntry {
  const DailyEntry({
    required this.uid,
    required this.displayName,
    required this.score,
    required this.correctCount,
    required this.totalCount,
  });

  final String uid;
  final String displayName;
  final int score;
  final int correctCount;
  final int totalCount;

  factory DailyEntry.fromJson(Map<String, dynamic> json) => DailyEntry(
    uid: json['uid'] as String,
    displayName: json['displayName'] as String? ?? 'Player',
    score: json['score'] as int? ?? 0,
    correctCount: json['correctCount'] as int? ?? 0,
    totalCount: json['totalCount'] as int? ?? 0,
  );
}

class ChallengeResult {
  const ChallengeResult({required this.displayName, required this.score, required this.correctCount});

  final String displayName;
  final int score;
  final int correctCount;

  factory ChallengeResult.fromJson(Map<String, dynamic> json) => ChallengeResult(
    displayName: json['displayName'] as String? ?? 'Player',
    score: json['score'] as int? ?? 0,
    correctCount: json['correctCount'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {'displayName': displayName, 'score': score, 'correctCount': correctCount};
}

/// A head-to-head round at `challenges/{code}`: everyone who joins with the
/// code plays the same seeded question set, and results are keyed by uid.
class FriendChallenge {
  const FriendChallenge({
    required this.code,
    required this.seed,
    required this.createdBy,
    required this.createdByName,
    required this.results,
    this.createdAt,
  });

  final String code;
  final int seed;
  final String createdBy;
  final String createdByName;
  final Map<String, ChallengeResult> results;
  final DateTime? createdAt;

  bool hasPlayed(String uid) => results.containsKey(uid);

  /// Results ordered best score first.
  List<MapEntry<String, ChallengeResult>> get standings =>
      results.entries.toList()..sort((a, b) => b.value.score.compareTo(a.value.score));

  factory FriendChallenge.fromJson(Map<String, dynamic> json) => FriendChallenge(
    code: json['code'] as String,
    seed: json['seed'] as int,
    createdBy: json['createdBy'] as String,
    createdByName: json['createdByName'] as String? ?? 'A friend',
    results: (json['results'] as Map? ?? {}).map(
      (uid, raw) => MapEntry(uid as String, ChallengeResult.fromJson(Map<String, dynamic>.from(raw as Map))),
    ),
    createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
  );
}

/// Why a Trivia round is being played, so its result screen knows where to
/// submit the score.
sealed class CompetitionContext {
  const CompetitionContext();

  /// Seed for the shared question set every participant gets.
  int get seed;
}

class DailyCompetition extends CompetitionContext {
  const DailyCompetition(this.dayKey);

  /// UTC date, `yyyy-MM-dd`, so every player worldwide shares one challenge.
  final String dayKey;

  @override
  int get seed => int.parse(dayKey.replaceAll('-', ''));
}

class FriendCompetition extends CompetitionContext {
  const FriendCompetition({required this.code, required this.seed});

  final String code;

  @override
  final int seed;
}
