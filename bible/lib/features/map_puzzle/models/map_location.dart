/// Schema stub for the Bible Map Puzzle mode — not yet wired to gameplay.
/// See assets/content/map_puzzle.json for sample data in this shape.
class MapLocation {
  const MapLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.xPercent,
    required this.yPercent,
  });

  final String id;
  final String name;
  final String description;

  /// Position as a fraction (0.0-1.0) of the map image's width/height, so
  /// the same content works regardless of the rendered map size.
  final double xPercent;
  final double yPercent;

  factory MapLocation.fromJson(Map<String, dynamic> json) => MapLocation(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        xPercent: (json['xPercent'] as num).toDouble(),
        yPercent: (json['yPercent'] as num).toDouble(),
      );
}
