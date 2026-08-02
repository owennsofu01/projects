import '../../../core/models/difficulty.dart';

class TriviaQuestion {
  const TriviaQuestion({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.difficulty,
    required this.level,
    required this.question,
    required this.options,
    required this.answer,
    required this.reference,
    required this.translation,
  });

  final String id;
  final String category;
  final String subcategory;
  final Difficulty difficulty;
  final int level;
  final String question;
  final List<String> options;
  final String answer;
  final String reference;
  final String translation;

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) => TriviaQuestion(
        id: json['id'] as String,
        category: json['category'] as String,
        subcategory: json['subcategory'] as String,
        difficulty: Difficulty.fromJson(json['difficulty'] as String),
        level: json['level'] as int? ?? 1,
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List),
        answer: json['answer'] as String,
        reference: json['reference'] as String,
        translation: json['translation'] as String,
      );
}
