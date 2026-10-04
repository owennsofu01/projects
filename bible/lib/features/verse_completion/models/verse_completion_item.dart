/// [template] contains a single `____` placeholder standing in for [answer].
/// [tier] (1–6) groups verses by difficulty; see [VerseCompletionLevels].
class VerseCompletionItem {
  const VerseCompletionItem({
    required this.id,
    required this.tier,
    required this.reference,
    required this.translation,
    required this.template,
    required this.answer,
    required this.distractors,
  });

  final String id;
  final int tier;
  final String reference;
  final String translation;
  final String template;
  final String answer;

  /// Wrong choices; each round shows a random subset sized to the level.
  final List<String> distractors;

  String get textBeforeBlank => template.split('____').first;
  String get textAfterBlank => template.contains('____') ? template.split('____').last : '';

  factory VerseCompletionItem.fromJson(Map<String, dynamic> json) => VerseCompletionItem(
    id: json['id'] as String,
    tier: json['tier'] as int,
    reference: json['reference'] as String,
    translation: json['translation'] as String,
    template: json['template'] as String,
    answer: json['answer'] as String,
    distractors: List<String>.from(json['distractors'] as List),
  );
}
