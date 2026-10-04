import 'package:bible_gamehive/core/constants/bible_books.dart';
import 'package:bible_gamehive/features/bible_reader/models/verse_range.dart';
import 'package:bible_gamehive/features/map_puzzle/data/map_puzzle_content_loader.dart';
import 'package:bible_gamehive/features/map_puzzle/models/map_location.dart';
import 'package:bible_gamehive/features/map_puzzle/providers/map_puzzle_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('10 levels of 10 places, each inside its map, with unique ids and valid references', () async {
    final levels = await MapPuzzleContentLoader.loadLevels();
    expect(levels.map((l) => l.level), List.generate(10, (i) => i + 1));
    final ids = <String>{};
    for (final level in levels) {
      expect(level.locations, hasLength(10), reason: 'level ${level.level}');
      for (final loc in level.locations) {
        expect(ids.add(loc.id), isTrue, reason: 'duplicate id ${loc.id}');
        final pos = level.region.project(loc.lat, loc.lon);
        expect(pos.dx, inExclusiveRange(0.02, 0.98), reason: '${loc.name} is off the edge of level ${level.level}');
        expect(pos.dy, inExclusiveRange(0.02, 0.98), reason: '${loc.name} is off the edge of level ${level.level}');
        final range = VerseRange.tryParse(loc.reference);
        expect(range, isNotNull, reason: '${loc.name}: "${loc.reference}"');
        expect(BibleBooks.all.map((b) => b.name), contains(range!.book), reason: '${loc.name}: unknown book');
      }
    }
  });

  test('map geography loads', () async {
    final geo = await MapPuzzleContentLoader.loadGeography();
    expect(geo.land, isNotEmpty);
    expect(geo.lakes, isNotEmpty);
    expect(geo.rivers, isNotEmpty);
  });

  group('MapPuzzleRules.isHit', () {
    const region = MapRegion(west: 34, east: 36, south: 31, north: 33);
    const north = MapLocation(id: 'n', name: 'North', description: '', reference: '', lat: 32.6, lon: 35);
    const south = MapLocation(id: 's', name: 'South', description: '', reference: '', lat: 32.4, lon: 35);
    const level = MapLevel(level: 1, title: '', region: region, locations: [north, south]);
    Offset at(MapLocation l) => region.project(l.lat, l.lon);

    test('a tap right on the target hits', () {
      expect(MapPuzzleRules.isHit(tap: at(north), target: north, level: level), isTrue);
    });

    test('a tap nearer a neighbouring place misses, even if close to the target', () {
      final nearSouth = Offset.lerp(at(north), at(south), 0.6)!;
      expect(MapPuzzleRules.isHit(tap: nearSouth, target: north, level: level), isFalse);
      expect(MapPuzzleRules.isHit(tap: nearSouth, target: south, level: level), isTrue);
    });

    test('a tap far away misses even when the target is the nearest place', () {
      expect(MapPuzzleRules.isHit(tap: const Offset(0.5, 0.15), target: north, level: level), isTrue);
      expect(MapPuzzleRules.isHit(tap: const Offset(0.98, 0.02), target: north, level: level), isFalse);
    });
  });
}
