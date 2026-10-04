import 'dart:math' as math;
import 'dart:ui';

/// A lat/lon bounding box drawn as a flat (equirectangular) map, with
/// longitude squeezed by cos(mid-latitude) so shapes aren't stretched sideways.
class MapRegion {
  const MapRegion({required this.west, required this.east, required this.south, required this.north});

  final double west;
  final double east;
  final double south;
  final double north;

  double get _lonScale => math.cos((south + north) / 2 * math.pi / 180);

  /// Width / height of the drawn map.
  double get aspectRatio => (east - west) * _lonScale / (north - south);

  /// Position as a fraction (0-1) of the map's width and height.
  Offset project(double lat, double lon) => Offset((lon - west) / (east - west), (north - lat) / (north - south));

  factory MapRegion.fromJson(Map<String, dynamic> json) => MapRegion(
    west: (json['west'] as num).toDouble(),
    east: (json['east'] as num).toDouble(),
    south: (json['south'] as num).toDouble(),
    north: (json['north'] as num).toDouble(),
  );
}

class MapLocation {
  const MapLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.reference,
    required this.lat,
    required this.lon,
  });

  final String id;
  final String name;
  final String description;
  final String reference;
  final double lat;
  final double lon;

  factory MapLocation.fromJson(Map<String, dynamic> json) => MapLocation(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    reference: json['reference'] as String,
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
  );
}

class MapLevel {
  const MapLevel({required this.level, required this.title, required this.region, required this.locations});

  final int level;
  final String title;
  final MapRegion region;
  final List<MapLocation> locations;

  factory MapLevel.fromJson(Map<String, dynamic> json) => MapLevel(
    level: json['level'] as int,
    title: json['title'] as String,
    region: MapRegion.fromJson(Map<String, dynamic>.from(json['region'] as Map)),
    locations: (json['locations'] as List)
        .map((l) => MapLocation.fromJson(Map<String, dynamic>.from(l as Map)))
        .toList(),
  );
}

/// Coastlines, lakes and rivers (Natural Earth, public domain), as
/// [lon, lat] point lists. Shared by every level; each level only draws the
/// part inside its [MapRegion].
class MapGeography {
  const MapGeography({required this.land, required this.lakes, required this.rivers});

  /// Polygon rings (outer boundaries and holes alike; drawn even-odd).
  final List<List<Offset>> land;
  final List<List<Offset>> lakes;

  /// Open polylines.
  final List<List<Offset>> rivers;

  static List<List<Offset>> _lines(Object? raw) => [
    for (final line in raw as List)
      [for (final p in line as List) Offset(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble())],
  ];

  factory MapGeography.fromJson(Map<String, dynamic> json) =>
      MapGeography(land: _lines(json['land']), lakes: _lines(json['lakes']), rivers: _lines(json['rivers']));
}
