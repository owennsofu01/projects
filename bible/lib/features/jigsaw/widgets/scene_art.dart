import 'dart:math';

import 'package:flutter/material.dart';

/// Hand-drawn (code-drawn) Bible scenes for the jigsaw, so pieces show a real
/// picture without bundling artwork. Every scene paints into any [Size] using
/// fractions of the width and height.
enum SceneArt {
  creation,
  noahsArk,
  redSea,
  davidAndGoliath,
  jonah,
  danielLions,
  nativity,
  calmingStorm,
  feedingFiveThousand,
  emptyTomb;

  static SceneArt fromJson(String value) => values.firstWhere((s) => s.name == value);

  void paint(Canvas canvas, Size size) {
    final p = _Painter(canvas, size);
    switch (this) {
      case SceneArt.creation:
        p.creation();
      case SceneArt.noahsArk:
        p.noahsArk();
      case SceneArt.redSea:
        p.redSea();
      case SceneArt.davidAndGoliath:
        p.davidAndGoliath();
      case SceneArt.jonah:
        p.jonah();
      case SceneArt.danielLions:
        p.danielLions();
      case SceneArt.nativity:
        p.nativity();
      case SceneArt.calmingStorm:
        p.calmingStorm();
      case SceneArt.feedingFiveThousand:
        p.feedingFiveThousand();
      case SceneArt.emptyTomb:
        p.emptyTomb();
    }
  }
}

/// Paints the whole scene, or — with [rows]/[cols]/[piece] — just one piece
/// of it, scaled so the pieces line up into the full picture.
class SceneArtPainter extends CustomPainter {
  const SceneArtPainter(this.art, {this.rows = 1, this.cols = 1, this.piece = 0});

  final SceneArt art;
  final int rows;
  final int cols;
  final int piece;

  @override
  void paint(Canvas canvas, Size size) {
    final row = piece ~/ cols;
    final col = piece % cols;
    canvas.clipRect(Offset.zero & size);
    canvas.translate(-col * size.width, -row * size.height);
    art.paint(canvas, Size(size.width * cols, size.height * rows));
  }

  @override
  bool shouldRepaint(SceneArtPainter old) =>
      old.art != art || old.rows != rows || old.cols != cols || old.piece != piece;
}

class _Painter {
  _Painter(this.canvas, this.size);

  final Canvas canvas;
  final Size size;

  double get w => size.width;
  double get h => size.height;
  Offset at(double x, double y) => Offset(x * w, y * h);
  Rect box(double l, double t, double r, double b) => Rect.fromLTRB(l * w, t * h, r * w, b * h);
  Paint fill(Color c) => Paint()..color = c;

  void sky(List<Color> colors) => canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Offset.zero & size),
  );

  void circle(double x, double y, double r, Color c) => canvas.drawCircle(at(x, y), r * w, fill(c));

  void poly(List<(double, double)> pts, Color c) {
    final path = Path()..moveTo(pts.first.$1 * w, pts.first.$2 * h);
    for (final (x, y) in pts.skip(1)) {
      path.lineTo(x * w, y * h);
    }
    canvas.drawPath(path..close(), fill(c));
  }

  /// A hill: a filled curve rising to [peak] between [x0] and [x1], down to the bottom edge.
  void hill(double x0, double x1, double base, double peak, Color c) {
    final path = Path()
      ..moveTo(x0 * w, h)
      ..lineTo(x0 * w, base * h)
      ..quadraticBezierTo((x0 + x1) / 2 * w, (2 * peak - base) * h, x1 * w, base * h)
      ..lineTo(x1 * w, h)
      ..close();
    canvas.drawPath(path, fill(c));
  }

  void waves(double top, Color c, {int count = 6, double amp = 0.03}) {
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, top * h);
    for (var i = 0; i < count; i++) {
      final x0 = i / count, x1 = (i + 1) / count;
      path.quadraticBezierTo((x0 + x1) / 2 * w, (top - amp * 2) * h, x1 * w, top * h);
    }
    path
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, fill(c));
  }

  void star(double x, double y, double r, Color c, {int points = 5}) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = (i.isEven ? r : r * 0.45) * w;
      final angle = -pi / 2 + i * pi / points;
      final o = at(x, y) + Offset(cos(angle) * radius, sin(angle) * radius);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path..close(), fill(c));
  }

  /// A simple robed figure standing on (x, y) with height [ht] (fractions of h).
  void person(double x, double y, double ht, Color robe, {Color skin = const Color(0xFFE0B48A)}) {
    final top = y - ht;
    poly([
      (x - ht * 0.18, y),
      (x + ht * 0.18, y),
      (x + ht * 0.08, top + ht * 0.3),
      (x - ht * 0.08, top + ht * 0.3),
    ], robe);
    canvas.drawCircle(Offset(x * w, (top + ht * 0.17) * h), ht * 0.13 * h, fill(skin));
  }

  void creation() {
    sky(const [Color(0xFF0B1A40), Color(0xFF2E4A8C), Color(0xFFF2A65A)]);
    for (final (x, y, r) in [
      (0.1, 0.1, 0.02),
      (0.3, 0.06, 0.015),
      (0.55, 0.12, 0.02),
      (0.8, 0.05, 0.018),
      (0.92, 0.18, 0.012),
    ]) {
      star(x, y, r, const Color(0xFFFFF5C0));
    }
    circle(0.78, 0.28, 0.07, const Color(0xFFF0F0F0)); // moon
    circle(0.22, 0.5, 0.11, const Color(0xFFFFD34E)); // sun
    waves(0.66, const Color(0xFF2B7BB9), count: 5);
    hill(0.35, 1.05, 0.78, 0.6, const Color(0xFF4CAF50));
    hill(-0.05, 0.5, 0.86, 0.72, const Color(0xFF388E3C));
    // the tree of life
    canvas.drawRect(box(0.66, 0.6, 0.7, 0.75), fill(const Color(0xFF6D4C41)));
    circle(0.68, 0.56, 0.08, const Color(0xFF2E7D32));
    circle(0.65, 0.55, 0.02, const Color(0xFFE53935));
    circle(0.72, 0.58, 0.02, const Color(0xFFE53935));
  }

  void noahsArk() {
    sky(const [Color(0xFF7EC8E3), Color(0xFFCDEFFD)]);
    final bands = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.indigo, Colors.purple];
    for (var i = 0; i < bands.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: at(0.5, 0.62), radius: (0.48 - i * 0.03) * w),
        pi,
        pi,
        false,
        Paint()
          ..color = bands[i].withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.03 * w,
      );
    }
    poly([(0.15, 0.6), (0.85, 0.6), (0.75, 0.78), (0.25, 0.78)], const Color(0xFF8D5524)); // hull
    canvas.drawRect(box(0.32, 0.46, 0.68, 0.6), fill(const Color(0xFFC68642)));
    poly([(0.28, 0.46), (0.72, 0.46), (0.5, 0.36)], const Color(0xFF6D3B1A)); // roof
    canvas.drawRect(box(0.47, 0.51, 0.53, 0.6), fill(const Color(0xFF4E2A10))); // door
    waves(0.74, const Color(0xFF1E6FA8));
    // the dove
    canvas.drawOval(box(0.12, 0.2, 0.2, 0.25), fill(Colors.white));
    poly([(0.15, 0.21), (0.19, 0.12), (0.2, 0.22)], Colors.white);
    circle(0.11, 0.21, 0.012, Colors.green);
  }

  void redSea() {
    sky(const [Color(0xFFFFB74D), Color(0xFFFFE0B2)]);
    poly([(0.0, 0.25), (0.38, 0.35), (0.42, 1.0), (0.0, 1.0)], const Color(0xFF1565C0)); // left wall
    poly([(1.0, 0.25), (0.62, 0.35), (0.58, 1.0), (1.0, 1.0)], const Color(0xFF1976D2)); // right wall
    poly([(0.0, 0.25), (0.38, 0.35), (0.3, 0.4), (0.0, 0.3)], const Color(0xFF90CAF9)); // foam
    poly([(1.0, 0.25), (0.62, 0.35), (0.7, 0.4), (1.0, 0.3)], const Color(0xFF90CAF9));
    poly([(0.42, 1.0), (0.46, 0.38), (0.54, 0.38), (0.58, 1.0)], const Color(0xFFD7B377)); // dry path
    for (var i = 0; i < 5; i++) {
      final y = 0.55 + i * 0.1, x = 0.5 + (i.isEven ? -0.02 : 0.02);
      person(x, y, 0.06 + i * 0.015, [Colors.brown, Colors.teal, Colors.deepPurple][i % 3]);
    }
    canvas.drawRect(box(0.47, 0.08, 0.49, 0.3), fill(const Color(0xFF5D4037))); // Moses' rod raised
  }

  void davidAndGoliath() {
    sky(const [Color(0xFF64B5F6), Color(0xFFE3F2FD)]);
    hill(-0.1, 0.6, 0.75, 0.55, const Color(0xFF9CCC65));
    hill(0.4, 1.1, 0.72, 0.5, const Color(0xFF7CB342));
    canvas.drawRect(box(0, 0.8, 1, 1), fill(const Color(0xFFC5A46D))); // valley floor
    // Goliath, huge and armoured
    person(0.72, 0.92, 0.6, const Color(0xFF607D8B));
    circle(0.72, 0.42, 0.07, const Color(0xFF9E9E9E)); // helmet
    canvas.drawRect(box(0.86, 0.25, 0.875, 0.92), fill(const Color(0xFF5D4037))); // spear
    poly([(0.85, 0.25), (0.885, 0.25), (0.8675, 0.18)], const Color(0xFFB0BEC5));
    // David with his sling
    person(0.22, 0.92, 0.22, const Color(0xFF8D6E63));
    canvas.drawLine(
      at(0.24, 0.76),
      at(0.33, 0.62),
      Paint()
        ..color = Colors.brown
        ..strokeWidth = 0.008 * w,
    );
    circle(0.5, 0.45, 0.015, const Color(0xFF757575)); // the stone in flight
  }

  void jonah() {
    sky(const [Color(0xFF546E7A), Color(0xFF90A4AE)]);
    waves(0.35, const Color(0xFF1A5276), count: 5, amp: 0.02);
    // the ship above
    poly([(0.55, 0.3), (0.9, 0.3), (0.85, 0.37), (0.6, 0.37)], const Color(0xFF6D4C41));
    canvas.drawRect(box(0.72, 0.12, 0.735, 0.3), fill(const Color(0xFF4E342E)));
    poly([(0.735, 0.13), (0.735, 0.28), (0.84, 0.28)], const Color(0xFFF5F5DC));
    // the great fish
    canvas.drawOval(box(0.08, 0.5, 0.72, 0.82), fill(const Color(0xFF37474F)));
    poly([(0.7, 0.66), (0.92, 0.5), (0.88, 0.66), (0.92, 0.82)], const Color(0xFF37474F));
    canvas.drawOval(box(0.12, 0.66, 0.6, 0.8), fill(const Color(0xFF78909C))); // belly
    circle(0.2, 0.6, 0.02, Colors.white);
    circle(0.2, 0.6, 0.01, Colors.black);
    person(0.32, 0.78, 0.12, const Color(0xFFFFB300)); // Jonah inside
    for (final (x, y) in [(0.8, 0.9), (0.15, 0.45), (0.5, 0.92)]) {
      circle(x, y, 0.012, const Color(0x88FFFFFF)); // bubbles
    }
  }

  void danielLions() {
    sky(const [Color(0xFF3E2723), Color(0xFF6D4C41)]);
    canvas.drawRect(box(0, 0.7, 1, 1), fill(const Color(0xFF8D6E63))); // den floor
    canvas.drawCircle(at(0.5, 0.05), 0.14 * w, fill(const Color(0xFFFFE082))); // light from above
    poly([(0.42, 0.05), (0.58, 0.05), (0.75, 0.7), (0.25, 0.7)], const Color(0x33FFF8E1));
    person(0.5, 0.78, 0.3, const Color(0xFF1E88E5));
    void lion(double x, double y, double s) {
      canvas.drawOval(box(x - s, y - s * 0.4, x + s, y + s * 0.3), fill(const Color(0xFFD4A04C))); // body
      circle(x - s * 0.9, y - s * 0.35, s * 0.35, const Color(0xFF9C6B25)); // mane
      circle(x - s * 0.9, y - s * 0.35, s * 0.2, const Color(0xFFE0B060)); // face
    }

    lion(0.22, 0.86, 0.14);
    lion(0.85, 0.88, 0.12);
    lion(0.2, 0.62, 0.09);
    // the angel's wings above Daniel
    poly([(0.5, 0.32), (0.2, 0.18), (0.38, 0.4)], const Color(0xCCFFFFFF));
    poly([(0.5, 0.32), (0.8, 0.18), (0.62, 0.4)], const Color(0xCCFFFFFF));
  }

  void nativity() {
    sky(const [Color(0xFF0D1B3E), Color(0xFF283E79)]);
    star(0.5, 0.12, 0.08, const Color(0xFFFFF59D), points: 8);
    canvas.drawLine(
      at(0.5, 0.18),
      at(0.5, 0.38),
      Paint()
        ..color = const Color(0x66FFF59D)
        ..strokeWidth = 0.01 * w,
    );
    hill(-0.1, 1.1, 0.85, 0.75, const Color(0xFF33691E));
    // the stable
    poly([(0.15, 0.45), (0.85, 0.45), (0.5, 0.3)], const Color(0xFF5D4037));
    canvas.drawRect(box(0.2, 0.45, 0.8, 0.85), fill(const Color(0xFF8D6E63)));
    canvas.drawRect(box(0.25, 0.5, 0.75, 0.85), fill(const Color(0xFF3E2723)));
    // the manger and the baby
    poly([(0.4, 0.72), (0.6, 0.72), (0.56, 0.82), (0.44, 0.82)], const Color(0xFFD7A86E));
    canvas.drawOval(box(0.44, 0.67, 0.56, 0.74), fill(Colors.white));
    circle(0.47, 0.69, 0.018, const Color(0xFFE0B48A));
    person(0.33, 0.84, 0.25, const Color(0xFF1565C0)); // Mary
    person(0.67, 0.84, 0.28, const Color(0xFF795548)); // Joseph
  }

  void calmingStorm() {
    sky(const [Color(0xFF263238), Color(0xFF455A64)]);
    poly([
      (0.7, 0.0),
      (0.62, 0.18),
      (0.68, 0.18),
      (0.58, 0.35),
      (0.72, 0.15),
      (0.66, 0.15),
      (0.76, 0.0),
    ], const Color(0xFFFFEB3B));
    for (final (x, y) in [(0.15, 0.12), (0.4, 0.08), (0.9, 0.12)]) {
      canvas.drawOval(box(x - 0.15, y - 0.05, x + 0.15, y + 0.06), fill(const Color(0xFF37474F)));
    }
    waves(0.62, const Color(0xFF0D47A1), count: 4, amp: 0.06);
    // the boat, tipping
    poly([(0.2, 0.55), (0.8, 0.5), (0.72, 0.66), (0.28, 0.68)], const Color(0xFF6D4C41));
    canvas.drawLine(
      at(0.5, 0.52),
      at(0.46, 0.2),
      Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = 0.012 * w,
    );
    poly([(0.46, 0.22), (0.49, 0.48), (0.66, 0.45)], const Color(0xFFEEEEEE));
    person(0.33, 0.56, 0.14, Colors.white); // Jesus, standing
    person(0.62, 0.55, 0.1, const Color(0xFF8D6E63));
    waves(0.8, const Color(0xFF1565C0), count: 5, amp: 0.04);
  }

  void feedingFiveThousand() {
    sky(const [Color(0xFF81D4FA), Color(0xFFE1F5FE)]);
    hill(-0.2, 1.2, 0.6, 0.35, const Color(0xFF8BC34A));
    canvas.drawRect(box(0, 0.6, 1, 1), fill(const Color(0xFF7CB342)));
    for (var i = 0; i < 14; i++) {
      final x = 0.05 + (i % 7) * 0.14, y = 0.5 + (i ~/ 7) * 0.08;
      circle(x, y, 0.018, [Colors.red, Colors.blue, Colors.orange, Colors.purple][i % 4].withValues(alpha: 0.7));
    }
    person(0.5, 0.82, 0.25, Colors.white);
    // five loaves and two fishes on a basket
    canvas.drawOval(box(0.18, 0.84, 0.82, 0.98), fill(const Color(0xFFA1887F)));
    for (var i = 0; i < 5; i++) {
      canvas.drawOval(box(0.22 + i * 0.07, 0.85, 0.28 + i * 0.07, 0.9), fill(const Color(0xFFD4A04C)));
    }
    for (final x in [0.6, 0.7]) {
      canvas.drawOval(box(x, 0.86, x + 0.08, 0.89), fill(const Color(0xFF90A4AE)));
      poly([(x + 0.08, 0.875), (x + 0.1, 0.86), (x + 0.1, 0.89)], const Color(0xFF90A4AE));
    }
  }

  void emptyTomb() {
    sky(const [Color(0xFFFF8A65), Color(0xFFFFD180), Color(0xFFFFF3E0)]);
    circle(0.8, 0.4, 0.12, const Color(0xFFFFF176)); // sunrise
    hill(-0.1, 0.9, 0.8, 0.25, const Color(0xFF8D6E63)); // the rock hillside
    canvas.drawOval(box(0.25, 0.42, 0.55, 0.85), fill(const Color(0xFF212121))); // open tomb
    circle(0.68, 0.72, 0.12, const Color(0xFF9E9E9E)); // the stone, rolled away
    circle(0.68, 0.72, 0.09, const Color(0xFFBDBDBD));
    canvas.drawRect(box(0, 0.85, 1, 1), fill(const Color(0xFF689F38)));
    for (final x in [0.1, 0.9]) {
      // lilies
      canvas.drawLine(
        at(x, 0.95),
        at(x, 0.85),
        Paint()
          ..color = Colors.green
          ..strokeWidth = 0.008 * w,
      );
      star(x, 0.84, 0.025, Colors.white, points: 6);
    }
    // three crosses on the distant hill
    for (final x in [0.76, 0.84, 0.92]) {
      canvas.drawRect(box(x - 0.005, 0.12, x + 0.005, 0.24), fill(const Color(0xFF5D4037)));
      canvas.drawRect(box(x - 0.02, 0.15, x + 0.02, 0.16), fill(const Color(0xFF5D4037)));
    }
  }
}
