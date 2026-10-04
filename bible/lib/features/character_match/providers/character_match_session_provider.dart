import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../data/character_match_content_loader.dart';
import '../models/character_match_card.dart';
import '../models/character_match_pair.dart';

enum CharacterMatchStatus { loading, playing, finished }

class CharacterMatchState {
  const CharacterMatchState({
    this.status = CharacterMatchStatus.loading,
    this.level,
    this.characters = const [],
    this.cards = const [],
    this.flipped = const [],
    this.matchedCharacterIds = const {},
    this.moves = 0,
    this.busy = false,
  });

  final CharacterMatchStatus status;
  final CharacterMatchLevel? level;
  final List<CharacterMatchPair> characters;
  final List<CharacterMatchCard> cards;
  final List<int> flipped;
  final Set<String> matchedCharacterIds;
  final int moves;
  final bool busy;

  int get totalPairs => characters.length;

  /// Flips that turned over a non-matching pair.
  int get misses => moves - matchedCharacterIds.length;

  /// Some misses are unavoidable in a memory game, so up to one per pair
  /// still earns 3 stars, up to two per pair earns 2. The round only ends
  /// once every pair is found, so finishing always earns a star.
  int get stars => misses <= totalPairs ? 3 : (misses <= totalPairs * 2 ? 2 : 1);

  int get score => (totalPairs * 10 - misses * 2).clamp(totalPairs * 2, totalPairs * 10);

  CharacterMatchState copyWith({
    CharacterMatchStatus? status,
    CharacterMatchLevel? level,
    List<CharacterMatchPair>? characters,
    List<CharacterMatchCard>? cards,
    List<int>? flipped,
    Set<String>? matchedCharacterIds,
    int? moves,
    bool? busy,
  }) => CharacterMatchState(
    status: status ?? this.status,
    level: level ?? this.level,
    characters: characters ?? this.characters,
    cards: cards ?? this.cards,
    flipped: flipped ?? this.flipped,
    matchedCharacterIds: matchedCharacterIds ?? this.matchedCharacterIds,
    moves: moves ?? this.moves,
    busy: busy ?? this.busy,
  );
}

class CharacterMatchSessionNotifier extends StateNotifier<CharacterMatchState> {
  CharacterMatchSessionNotifier(this.levelNumber) : super(const CharacterMatchState()) {
    _init();
  }

  final int levelNumber;
  bool _disposed = false;

  Future<void> _init() async {
    final levels = await CharacterMatchContentLoader.load();
    final level = levels.where((l) => l.level == levelNumber).firstOrNull;
    final characters = level?.characters ?? const <CharacterMatchPair>[];
    state = state.copyWith(
      status: CharacterMatchStatus.playing,
      level: level,
      characters: characters,
      cards: CharacterMatchCard.buildDeck(characters),
    );
  }

  void flipCard(int index) {
    if (state.busy) return;
    if (state.flipped.contains(index)) return;
    if (index < 0 || index >= state.cards.length) return;
    if (state.matchedCharacterIds.contains(state.cards[index].characterId)) return;
    if (state.flipped.length >= 2) return;

    final flipped = [...state.flipped, index];
    state = state.copyWith(flipped: flipped);
    if (flipped.length < 2) return;

    final first = state.cards[flipped[0]];
    final second = state.cards[flipped[1]];

    if (first.characterId == second.characterId) {
      final matched = {...state.matchedCharacterIds, first.characterId};
      SoundService.play(SfxSound.correct);
      state = state.copyWith(matchedCharacterIds: matched, flipped: const [], moves: state.moves + 1);
      if (matched.length == state.totalPairs) {
        SoundService.play(SfxSound.complete);
        state = state.copyWith(status: CharacterMatchStatus.finished);
      }
    } else {
      SoundService.play(SfxSound.wrong);
      state = state.copyWith(busy: true, moves: state.moves + 1);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (_disposed) return;
        state = state.copyWith(flipped: const [], busy: false);
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final characterMatchSessionProvider = StateNotifierProvider.autoDispose
    .family<CharacterMatchSessionNotifier, CharacterMatchState, int>(
      (ref, level) => CharacterMatchSessionNotifier(level),
    );
