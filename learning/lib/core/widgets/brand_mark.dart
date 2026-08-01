import 'package:flutter/material.dart';

/// The app's icon + name, shared between the splash screen and the auth
/// screens so the visual identity stays consistent across that transition.
///
/// The icon art (assets/icon/app_icon.png) is a flattened raster with an
/// off-white background baked in, so it's presented on a matching card
/// rather than dropped directly onto the (possibly dark) scaffold — that
/// keeps it looking intentional instead of like a stray white rectangle.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});

  /// Use a smaller footprint when embedded above a form (auth screens)
  /// rather than centered alone on the splash screen.
  final bool compact;

  static const _cardColor = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    final size = compact ? 56.0 : 72.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.14),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.16),
            child: Image.asset(
              'assets/icon/app_icon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: compact ? 12 : 20),
        Text(
          'ProfitPulse',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
