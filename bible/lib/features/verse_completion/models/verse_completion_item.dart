import '../../../core/models/difficulty.dart';

/// [template] contains a single `____` placeholder standing in for [answer].
class VerseCompletionItem {
  const VerseCompletionItem({
    required this.id,
    required this.difficulty,
    required this.reference,
    required this.translation,
    required this.template,
    required this.answer,
    required this.wordBank,
  });

  final String id;
  final Difficulty difficulty;
  final String reference;
  final String translation;
  final String template;
  final String answer;

  /// Distractor + correct words for kids-mode tap-to-fill. Ignored in adult
  /// free-text mode.
  final List<String> wordBank;

  String get textBeforeBlank => template.split('____').first;
  String get textAfterBlank => template.contains('____') ? template.split('____').last : '';

  factory VerseCompletionItem.fromJson(Map<String, dynamic> json) => VerseCompletionItem(
        id: json['id'] as String,
        difficulty: Difficulty.fromJson(json['difficulty'] as String),
        reference: json['reference'] as String,
        translation: json['translation'] as String,
        template: json['template'] as String,
        answer: json['answer'] as String,
        wordBank: List<String>.from(json['wordBank'] as List),
      );
}
