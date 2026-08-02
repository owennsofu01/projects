enum Difficulty {
  kids,
  teen,
  adult,
  scholar;

  static Difficulty fromJson(String value) => Difficulty.values.firstWhere(
        (d) => d.name == value,
        orElse: () => Difficulty.adult,
      );

  String get label => switch (this) {
        Difficulty.kids => 'Kids',
        Difficulty.teen => 'Teen',
        Difficulty.adult => 'Adult',
        Difficulty.scholar => 'Scholar',
      };
}
