import 'character_match_pair.dart';

class CharacterMatchCard {
  const CharacterMatchCard({
    required this.characterId,
    required this.isNameCard,
    required this.primaryText,
    this.secondaryText,
    this.reference,
  });

  final String characterId;
  final bool isNameCard;
  final String primaryText;
  final String? secondaryText;

  /// Bible reference for the moment on an action card, revealed once matched.
  final String? reference;

  static List<CharacterMatchCard> buildDeck(List<CharacterMatchPair> characters) {
    final cards = <CharacterMatchCard>[];
    for (final character in characters) {
      cards.add(CharacterMatchCard(characterId: character.id, isNameCard: true, primaryText: character.name));
      cards.add(
        CharacterMatchCard(
          characterId: character.id,
          isNameCard: false,
          primaryText: character.keyAct,
          secondaryText: character.description,
          reference: character.reference,
        ),
      );
    }
    cards.shuffle();
    return cards;
  }
}
