/// Schema stub for the Parable Matching mode — not yet wired to gameplay.
/// See assets/content/parable_matching.json for sample data in this shape.
class ParableMatchItem {
  const ParableMatchItem({
    required this.id,
    required this.parable,
    required this.reference,
    required this.lesson,
  });

  final String id;
  final String parable;
  final String reference;
  final String lesson;

  factory ParableMatchItem.fromJson(Map<String, dynamic> json) => ParableMatchItem(
        id: json['id'] as String,
        parable: json['parable'] as String,
        reference: json['reference'] as String,
        lesson: json['lesson'] as String,
      );
}
