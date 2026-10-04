class BibleVerse {
  const BibleVerse({required this.number, required this.text});

  final int number;
  final String text;

  factory BibleVerse.fromJson(Map<String, dynamic> json) =>
      BibleVerse(number: json['number'] as int, text: json['text'] as String);

  Map<String, dynamic> toJson() => {'number': number, 'text': text};
}
