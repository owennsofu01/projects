enum Difficulty {
  kids,
  teen,
  adult,
  scholar;

  static Difficulty fromJson(String value) =>
      Difficulty.values.firstWhere((d) => d.name == value, orElse: () => Difficulty.adult);

  String get label => switch (this) {
    Difficulty.kids => 'Kids',
    Difficulty.teen => 'Teen',
    Difficulty.adult => 'Adult',
    Difficulty.scholar => 'Scholar',
  };
}

/// [items] easiest first, keeping their original order within a difficulty —
/// how the puzzle modes turn their content files into level order.
List<T> sortedByDifficulty<T>(List<T> items, Difficulty Function(T) difficultyOf) {
  final indexed = items.indexed.toList()
    ..sort((a, b) {
      final byDifficulty = difficultyOf(a.$2).index.compareTo(difficultyOf(b.$2).index);
      return byDifficulty != 0 ? byDifficulty : a.$1.compareTo(b.$1);
    });
  return [for (final (_, item) in indexed) item];
}
