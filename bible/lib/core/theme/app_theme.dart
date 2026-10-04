import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({double fontScale = 1.0, bool highContrast = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.softBlue,
      brightness: Brightness.light,
      surface: highContrast ? Colors.white : AppColors.cream,
      primary: highContrast ? AppColors.ink : AppColors.softBlue,
      secondary: AppColors.gold,
    );
    return _base(scheme, fontScale: fontScale);
  }

  static ThemeData dark({double fontScale = 1.0, bool highContrast = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.softBlue,
      brightness: Brightness.dark,
      surface: highContrast ? Colors.black : AppColors.creamDark,
      secondary: AppColors.gold,
    );
    return _base(scheme, fontScale: fontScale);
  }

  static ThemeData _base(ColorScheme scheme, {required double fontScale}) {
    // Merge in englishLike so every style has a concrete fontSize;
    // apply(fontSizeFactor:) asserts on styles with a null fontSize.
    final typography = Typography.material2021();
    final baseTextTheme = (scheme.brightness == Brightness.dark ? typography.white : typography.black).merge(
      typography.englishLike,
    );
    final textTheme = GoogleFonts.nunitoSansTextTheme(
      baseTextTheme,
    ).apply(fontSizeFactor: fontScale, bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final headingFont = GoogleFonts.lora();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(fontFamily: headingFont.fontFamily),
        headlineMedium: textTheme.headlineMedium?.copyWith(fontFamily: headingFont.fontFamily),
        titleLarge: textTheme.titleLarge?.copyWith(fontFamily: headingFont.fontFamily),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondary.withValues(alpha: 0.25),
      ),
    );
  }
}
