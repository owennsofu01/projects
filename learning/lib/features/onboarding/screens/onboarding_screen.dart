import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/motion.dart';
import '../onboarding_storage.dart';

class _Page {
  const _Page({
    required this.lead,
    required this.highlight,
    required this.body,
    required this.mainIcon,
    required this.sideIcon,
    required this.edgeIcon,
  });

  final String lead;
  final String highlight;
  final String body;
  final IconData mainIcon;
  final IconData sideIcon;
  final IconData edgeIcon;
}

const _pages = [
  _Page(
    lead: 'Sell and see your ',
    highlight: 'profit instantly',
    body:
        'Record a sale in seconds and know exactly what you made on it — '
        'after costs, not before.',
    mainIcon: Icons.point_of_sale_rounded,
    sideIcon: Icons.receipt_long_rounded,
    edgeIcon: Icons.trending_up_rounded,
  ),
  _Page(
    lead: 'Know your stock ',
    highlight: 'before it runs out',
    body:
        'Smart alerts tell you what to restock, what to promote and what is '
        'sitting on the shelf.',
    mainIcon: Icons.inventory_2_rounded,
    sideIcon: Icons.qr_code_scanner_rounded,
    edgeIcon: Icons.notifications_active_rounded,
  ),
  _Page(
    lead: 'Reports that ',
    highlight: 'grow your business',
    body:
        'Clear profit & loss, top sellers and spending — for any day, week '
        'or month.',
    mainIcon: Icons.bar_chart_rounded,
    sideIcon: Icons.pie_chart_rounded,
    edgeIcon: Icons.insights_rounded,
  ),
];

/// Three intro pages shown once, before the first sign-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Fixed brand colors: these pages look the same in light and dark mode.
  static const _background = AppColors.brandTeal;
  static const _accent = Color(0xFFB4EBAE); // light tint of the logo green

  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(String route) async {
    await OnboardingStorage.markSeen();
    Get.offAllNamed(route);
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: _isLast
                              ? null
                              : () => _finish(AppRoutes.login),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Skip'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => _PageView(
                        page: _pages[i],
                        accent: _accent,
                        background: _background,
                      ),
                    ),
                  ),
                  _Dots(count: _pages.length, index: _index),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _background,
                          shape: const StadiumBorder(),
                          textStyle: textTheme.titleMedium,
                        ),
                        onPressed: _isLast
                            ? () => _finish(AppRoutes.register)
                            : _next,
                        child: Text(_isLast ? 'Get started' : 'Next'),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: AnimatedOpacity(
                      opacity: _isLast ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: TextButton(
                        onPressed: _isLast
                            ? () => _finish(AppRoutes.login)
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('I already have an account'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({
    required this.page,
    required this.accent,
    required this.background,
  });

  final _Page page;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: _Illustration(page: page, background: background),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              FadeSlideIn(
                child: Text.rich(
                  TextSpan(
                    text: page.lead,
                    children: [
                      TextSpan(
                        text: page.highlight,
                        style: TextStyle(color: accent),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  page.body,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// White circles holding icons, gently floating over a soft wave.
class _Illustration extends StatefulWidget {
  const _Illustration({required this.page, required this.background});

  final _Page page;
  final Color background;

  @override
  State<_Illustration> createState() => _IllustrationState();
}

class _IllustrationState extends State<_Illustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teal = widget.background;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final main = math.min(w * 0.58, h * 0.62);
        final side = main * 0.5;
        final edge = main * 0.62;

        return AnimatedBuilder(
          animation: _float,
          builder: (context, _) {
            // Each bubble bobs on its own phase so they don't move in sync.
            double bob(double phase) =>
                math.sin((_float.value + phase) * 2 * math.pi) * 6;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(child: CustomPaint(painter: _WavePainter())),
                // Side bubble, top-left.
                Positioned(
                  left: w * 0.12,
                  top: h * 0.08 + bob(0),
                  child: _Bubble(
                    size: side,
                    icon: widget.page.sideIcon,
                    color: teal,
                    shape: _BubbleShape.rounded,
                  ),
                ),
                // Edge bubble, cut off by the right edge.
                Positioned(
                  right: -edge * 0.3,
                  top: h * 0.02 + bob(0.33),
                  child: _Bubble(
                    size: edge,
                    icon: widget.page.edgeIcon,
                    color: teal,
                  ),
                ),
                // Main bubble.
                Positioned(
                  left: (w - main) / 2,
                  bottom: h * 0.04 + bob(0.66),
                  child: FadeSlideIn(
                    child: _Bubble(
                      size: main,
                      icon: widget.page.mainIcon,
                      color: teal,
                      ring: true,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

enum _BubbleShape { circle, rounded }

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.size,
    required this.icon,
    required this.color,
    this.shape = _BubbleShape.circle,
    this.ring = false,
  });

  final double size;
  final IconData icon;
  final Color color;
  final _BubbleShape shape;

  /// Adds a soft outer ring, for the main bubble.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape == _BubbleShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: shape == _BubbleShape.rounded
            ? BorderRadius.circular(size * 0.34)
            : null,
      ),
      child: Icon(icon, size: size * 0.42, color: color),
    );

    if (!ring) return bubble;
    return Container(
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.14),
      ),
      child: bubble,
    );
  }
}

/// A broad, faint wave behind the bubbles for depth.
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(-size.width * 0.1, size.height * 0.7)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.35,
        size.width * 0.45,
        size.height * 0.95,
        size.width * 0.75,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.2,
        size.width * 1.1,
        size.height * 0.3,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: i == index ? 1 : 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
