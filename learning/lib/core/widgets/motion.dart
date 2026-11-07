import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/formatters.dart';

/// True when the user has asked the OS to reduce motion.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Fades and slides its child up into place once, after [delay]. Use
/// increasing delays on a list of blocks for a staggered entrance.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 16,
  });

  final Widget child;
  final Duration delay;

  /// How far below its final position the child starts, in pixels.
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.status != AnimationStatus.dismissed) return;
    if (reduceMotion(context)) {
      _controller.value = 1;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}

/// A currency amount that counts up to [value] on first show, and animates
/// smoothly between values when it changes.
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount(this.value, {super.key, this.style});

  final double value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion(context) ? value : 0, end: value),
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      // Obx: re-format when the display currency changes.
      builder: (context, v, _) =>
          Obx(() => Text(AppFormatter.currency(v), style: style)),
    );
  }
}

/// Animates a 0→1 progress value once when first built (and again whenever
/// [key] changes). Handy for "grow in" chart effects.
class GrowIn extends StatelessWidget {
  const GrowIn({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 700),
  });

  final Widget Function(BuildContext context, double t) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final skip = reduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: skip ? 1 : 0, end: 1),
      duration: skip ? Duration.zero : duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => builder(context, t),
    );
  }
}

/// Reveals its child left-to-right on first show, like a line being drawn.
class RevealFromLeft extends StatelessWidget {
  const RevealFromLeft({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GrowIn(
      duration: const Duration(milliseconds: 900),
      builder: (context, t) =>
          ClipRect(clipper: _WidthClipper(t), child: child),
    );
  }
}

class _WidthClipper extends CustomClipper<Rect> {
  _WidthClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      // A little extra height so line caps and the end dot aren't clipped.
      Rect.fromLTRB(-4, -8, (size.width + 8) * fraction, size.height + 8);

  @override
  bool shouldReclip(_WidthClipper old) => old.fraction != fraction;
}
