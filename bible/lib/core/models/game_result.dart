import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// One completed round of any game mode. Written local-first, then synced to
/// Firestore under `users/{uid}/gameResults/{id}` once connectivity allows.
class GameResult {
  GameResult({
    String? id,
    required this.gameModeId,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.difficulty,
    this.book,
    this.category,
    DateTime? completedAt,
    this.synced = false,
  })  : id = id ?? _uuid.v4(),
        completedAt = completedAt ?? DateTime.now();

  final String id;
  final String gameModeId;
  final int score;
  final int correctCount;
  final int totalCount;
  final String difficulty;
  final String? book;
  final String? category;
  final DateTime completedAt;
  final bool synced;

  GameResult copyWith({bool? synced}) => GameResult(
        id: id,
        gameModeId: gameModeId,
        score: score,
        correctCount: correctCount,
        totalCount: totalCount,
        difficulty: difficulty,
        book: book,
        category: category,
        completedAt: completedAt,
        synced: synced ?? this.synced,
      );

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
        id: json['id'] as String,
        gameModeId: json['gameModeId'] as String,
        score: json['score'] as int,
        correctCount: json['correctCount'] as int,
        totalCount: json['totalCount'] as int,
        difficulty: json['difficulty'] as String,
        book: json['book'] as String?,
        category: json['category'] as String?,
        completedAt: DateTime.parse(json['completedAt'] as String),
        synced: json['synced'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameModeId': gameModeId,
        'score': score,
        'correctCount': correctCount,
        'totalCount': totalCount,
        'difficulty': difficulty,
        'book': book,
        'category': category,
        'completedAt': completedAt.toIso8601String(),
        'synced': synced,
      };
}
