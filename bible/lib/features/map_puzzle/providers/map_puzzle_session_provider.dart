import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../data/map_puzzle_content_loader.dart';
import '../models/map_location.dart';

enum MapPuzzleStatus { loading, playing, answered, finished }

/// Farthest a tap may land from the target and still count, as a fraction
/// of the map's longer side. Generous because the real deciding rule is
/// [MapPuzzleRules.isHit]'s "nearest place" check.
const _maxReach = 0.12;

class MapPuzzleRules {
  MapPuzzleRules._();

  /// A tap hits [target] when [target] is the closest of the level's places
  /// to it (so neighbouring towns never accept each other) and it is within
  /// reach. Positions are 0-1 map fractions; distances are measured with the
  /// map's real proportions.
  static bool isHit({required Offset tap, required MapLocation target, required MapLevel level}) {
    final aspect = level.region.aspectRatio;
    Offset scaled(Offset fraction) => Offset(fraction.dx * aspect, fraction.dy);
    double distanceTo(MapLocation l) => (scaled(level.region.project(l.lat, l.lon)) - scaled(tap)).distance;

    final nearest = level.locations.reduce((a, b) => distanceTo(a) <= distanceTo(b) ? a : b);
    final longerSide = aspect > 1 ? aspect : 1.0;
    return nearest.id == target.id && distanceTo(target) <= _maxReach * longerSide;
  }
}

class MapPuzzleState {
  const MapPuzzleState({
    this.status = MapPuzzleStatus.loading,
    this.level,
    this.geography,
    this.locations = const [],
    this.currentIndex = 0,
    this.lastTap,
    this.wasCorrect = false,
    this.score = 0,
    this.correctCount = 0,
  });

  final MapPuzzleStatus status;
  final MapLevel? level;
  final MapGeography? geography;
  final List<MapLocation> locations;
  final int currentIndex;

  /// Last tap as a 0-1 fraction of the map's width/height.
  final Offset? lastTap;
  final bool wasCorrect;
  final int score;
  final int correctCount;

  MapLocation? get currentLocation => currentIndex < locations.length ? locations[currentIndex] : null;
  int get totalCount => locations.length;
  bool get isLastLocation => currentIndex >= locations.length - 1;

  MapPuzzleState copyWith({
    MapPuzzleStatus? status,
    MapLevel? level,
    MapGeography? geography,
    List<MapLocation>? locations,
    int? currentIndex,
    Offset? lastTap,
    bool clearLastTap = false,
    bool? wasCorrect,
    int? score,
    int? correctCount,
  }) => MapPuzzleState(
    status: status ?? this.status,
    level: level ?? this.level,
    geography: geography ?? this.geography,
    locations: locations ?? this.locations,
    currentIndex: currentIndex ?? this.currentIndex,
    lastTap: clearLastTap ? null : (lastTap ?? this.lastTap),
    wasCorrect: wasCorrect ?? this.wasCorrect,
    score: score ?? this.score,
    correctCount: correctCount ?? this.correctCount,
  );
}

class MapPuzzleSessionNotifier extends StateNotifier<MapPuzzleState> {
  MapPuzzleSessionNotifier(this.levelNumber) : super(const MapPuzzleState()) {
    _init();
  }

  final int levelNumber;

  Future<void> _init() async {
    final (levels, geography) = await (
      MapPuzzleContentLoader.loadLevels(),
      MapPuzzleContentLoader.loadGeography(),
    ).wait;
    final level = levels.where((l) => l.level == levelNumber).firstOrNull;
    state = state.copyWith(
      status: MapPuzzleStatus.playing,
      level: level,
      geography: geography,
      locations: [...?level?.locations]..shuffle(),
    );
  }

  void submitTap(double xFraction, double yFraction) {
    if (state.status != MapPuzzleStatus.playing) return;
    final target = state.currentLocation;
    final level = state.level;
    if (target == null || level == null) return;

    final tap = Offset(xFraction, yFraction);
    final correct = MapPuzzleRules.isHit(tap: tap, target: target, level: level);
    SoundService.play(correct ? SfxSound.correct : SfxSound.wrong);

    state = state.copyWith(
      status: MapPuzzleStatus.answered,
      lastTap: tap,
      wasCorrect: correct,
      score: state.score + (correct ? 10 : 0),
      correctCount: state.correctCount + (correct ? 1 : 0),
    );
  }

  void nextLocation() {
    if (state.isLastLocation) {
      SoundService.play(SfxSound.complete);
      state = state.copyWith(status: MapPuzzleStatus.finished);
      return;
    }
    state = state.copyWith(
      status: MapPuzzleStatus.playing,
      currentIndex: state.currentIndex + 1,
      clearLastTap: true,
      wasCorrect: false,
    );
  }
}

final mapPuzzleSessionProvider = StateNotifierProvider.autoDispose
    .family<MapPuzzleSessionNotifier, MapPuzzleState, int>((ref, level) => MapPuzzleSessionNotifier(level));
