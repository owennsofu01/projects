import 'package:flutter/material.dart';

import '../models/map_location.dart';

class BibleMapColors {
  const BibleMapColors({required this.sea, required this.land, required this.coast, required this.river});

  final Color sea;
  final Color land;
  final Color coast;
  final Color river;

  static BibleMapColors of(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const BibleMapColors(
          sea: Color(0xFF1C3442),
          land: Color(0xFF4A4334),
          coast: Color(0xFF7A6E55),
          river: Color(0xFF3F6E86),
        )
      : const BibleMapColors(
          sea: Color(0xFFBCD7E4),
          land: Color(0xFFEDE3C8),
          coast: Color(0xFFB5A27A),
          river: Color(0xFF6FA3BF),
        );
}

/// Draws [geography] cropped to [region]: sea, land, lakes, then rivers.
class BibleMapPainter extends CustomPainter {
  BibleMapPainter({required this.region, required this.geography, required this.colors});

  final MapRegion region;
  final MapGeography geography;
  final BibleMapColors colors;

  Size? _cachedSize;
  late Path _land;
  late Path _lakes;
  late Path _rivers;

  bool _touchesRegion(List<Offset> points) {
    // Small margin so coastlines just outside the frame still close cleanly.
    const margin = 1.0;
    for (final p in points) {
      if (p.dx >= region.west - margin &&
          p.dx <= region.east + margin &&
          p.dy >= region.south - margin &&
          p.dy <= region.north + margin) {
        return true;
      }
    }
    return false;
  }

  Path _path(List<List<Offset>> lines, Size size, {required bool close}) {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final line in lines) {
      if (line.length < 2 || !_touchesRegion(line)) continue;
      for (var i = 0; i < line.length; i++) {
        final f = region.project(line[i].dy, line[i].dx);
        final x = f.dx * size.width;
        final y = f.dy * size.height;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      if (close) path.close();
    }
    return path;
  }

  void _build(Size size) {
    if (_cachedSize == size) return;
    _cachedSize = size;
    _land = _path(geography.land, size, close: true);
    _lakes = _path(geography.lakes, size, close: true);
    _rivers = _path(geography.rivers, size, close: false);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _build(size);
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.sea);
    canvas.drawPath(_land, Paint()..color = colors.land);
    canvas.drawPath(
      _land,
      Paint()
        ..color = colors.coast
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.drawPath(_lakes, Paint()..color = colors.sea);
    canvas.drawPath(
      _rivers,
      Paint()
        ..color = colors.river
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(BibleMapPainter old) =>
      old.region != region || old.geography != geography || old.colors.sea != colors.sea;
}
