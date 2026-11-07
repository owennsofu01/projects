import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotchedNavItem {
  const NotchedNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;

  /// Not shown, but used for tooltips and screen readers.
  final String label;
}

/// A floating, icon-only bottom bar with a raised circular button sitting in
/// a curved notch at its center. The active tab is marked by its color and a
/// small dot underneath.
///
/// [items] must have an odd length; the middle item becomes the raised button.
class NotchedNavBar extends StatelessWidget {
  const NotchedNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NotchedNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _barHeight = 64.0;
  static const _buttonSize = 56.0;

  /// How far the raised button rises above the bar.
  static const _rise = 24.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    assert(items.length.isOdd, 'NotchedNavBar needs an odd item count');
    final center = items.length ~/ 2;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: _barHeight + _rise,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: _rise,
                child: CustomPaint(
                  painter: _NotchedBarPainter(
                    color: colorScheme.surfaceContainerLow,
                    border: colorScheme.outlineVariant,
                    notchRadius: _buttonSize / 2 + 8,
                    notchCenterY: _buttonSize / 2 - _rise,
                  ),
                ),
              ),
              Positioned.fill(
                top: _rise,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: i == center
                            ? _Dot(visible: selectedIndex == i, top: 44)
                            : _NavIcon(
                                item: items[i],
                                selected: selectedIndex == i,
                                onTap: () => _select(i),
                              ),
                      ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: _CenterButton(
                  item: items[center],
                  size: _buttonSize,
                  onTap: () => _select(center),
                  selected: selectedIndex == center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(int index) {
    if (index == selectedIndex) return;
    HapticFeedback.selectionClick();
    onSelected(index);
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NotchedNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    key: ValueKey(selected),
                    size: 26,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              _Dot(visible: selected, top: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.item,
    required this.size,
    required this.onTap,
    required this.selected,
  });

  final NotchedNavItem item;
  final double size;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: colorScheme.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: size,
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                color: colorScheme.onPrimary,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.visible, required this.top});

  final bool visible;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: AnimatedScale(
          scale: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a rounded bar with a smooth, curved notch cut into the top center.
class _NotchedBarPainter extends CustomPainter {
  _NotchedBarPainter({
    required this.color,
    required this.border,
    required this.notchRadius,
    required this.notchCenterY,
  });

  final Color color;
  final Color border;
  final double notchRadius;

  /// Notch circle center, relative to the bar's top edge (negative = above).
  final double notchCenterY;

  static const _corner = 24.0;
  static const _shoulder = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final r = notchRadius;

    // Where the notch meets the circle: a point on the circle a little below
    // its widest part, so the shoulders blend in smoothly.
    const angle = math.pi / 6;
    final dx = r * math.cos(angle);
    final dy = notchCenterY + r * math.sin(angle);

    final path = Path()
      ..moveTo(0, _corner)
      ..quadraticBezierTo(0, 0, _corner, 0)
      ..lineTo(cx - r - _shoulder, 0)
      ..quadraticBezierTo(cx - r + 2, 0, cx - dx, dy)
      ..arcToPoint(
        Offset(cx + dx, dy),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..quadraticBezierTo(cx + r - 2, 0, cx + r + _shoulder, 0)
      ..lineTo(w - _corner, 0)
      ..quadraticBezierTo(w, 0, w, _corner)
      ..lineTo(w, h - _corner)
      ..quadraticBezierTo(w, h, w - _corner, h)
      ..lineTo(_corner, h)
      ..quadraticBezierTo(0, h, 0, h - _corner)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 6, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) =>
      old.color != color ||
      old.border != border ||
      old.notchRadius != notchRadius ||
      old.notchCenterY != notchCenterY;
}
