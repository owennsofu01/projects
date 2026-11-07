import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Minimal, flat theme built from the logo palette: teal primary, green
/// secondary, cyan tertiary, charcoal-tinted neutrals. Surfaces are separated
/// by hairline borders rather than shadows.
class AppTheme {
  AppTheme._();

  static const radius = 12.0;

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ColorScheme _scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.brandTeal,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    final paper = isDark ? AppColors.paperDark : AppColors.paper;
    final canvas = isDark ? AppColors.canvasDark : AppColors.canvas;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final muted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;

    return base.copyWith(
      primary: isDark ? AppColors.brandOnDark : AppColors.brandTeal,
      onPrimary: isDark ? AppColors.canvasDark : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF0D3A4C)
          : const Color(0xFFE3F2F8),
      onPrimaryContainer: isDark
          ? const Color(0xFFBFE6F5)
          : const Color(0xFF07425A),
      secondary: AppColors.brandGreen,
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF1C3A19)
          : const Color(0xFFE6F4E4),
      onSecondaryContainer: isDark
          ? const Color(0xFFC4E8BF)
          : const Color(0xFF1D5418),
      tertiary: AppColors.brandCyan,
      onTertiary: Colors.white,
      error: AppColors.expense,
      onError: Colors.white,
      surface: canvas,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLowest: paper,
      surfaceContainerLow: paper,
      surfaceContainer: paper,
      surfaceContainerHigh: isDark
          ? const Color(0xFF1E2126)
          : const Color(0xFFF1F3F5),
      surfaceContainerHighest: isDark
          ? const Color(0xFF25292E)
          : const Color(0xFFEBEEF1),
      outline: isDark ? const Color(0xFF454A51) : const Color(0xFFC9CED4),
      outlineVariant: line,
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final colorScheme = _scheme(brightness);
    final isDark = brightness == Brightness.dark;
    final border = BorderSide(color: colorScheme.outlineVariant);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    final baseTextTheme = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;

    // Inter throughout: neutral, highly legible, and reads as precise —
    // suited to a finance app. Headings get tighter tracking and weight.
    final inter = GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    TextStyle? heading(TextStyle? s, FontWeight w) =>
        s?.copyWith(fontWeight: w, letterSpacing: -0.3);
    final textTheme = inter.copyWith(
      headlineLarge: heading(inter.headlineLarge, FontWeight.w700),
      headlineMedium: heading(inter.headlineMedium, FontWeight.w700),
      headlineSmall: heading(inter.headlineSmall, FontWeight.w600),
      titleLarge: heading(inter.titleLarge, FontWeight.w600),
      titleMedium: inter.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: inter.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: inter.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: inter.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      bodySmall: inter.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
    );

    final buttonText = textTheme.labelLarge?.copyWith(fontSize: 15);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: shape.copyWith(side: border),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        shape: shape,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: inputBorder(colorScheme.outlineVariant),
        enabledBorder: inputBorder(colorScheme.outlineVariant),
        focusedBorder: inputBorder(colorScheme.primary, 1.5),
        errorBorder: inputBorder(colorScheme.error),
        focusedErrorBorder: inputBorder(colorScheme.error, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: buttonPadding,
          textStyle: buttonText,
          shape: shape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: buttonPadding,
          textStyle: buttonText,
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          padding: buttonPadding,
          textStyle: buttonText,
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: buttonText, shape: shape),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colorScheme.primaryContainer,
          selectedForegroundColor: colorScheme.onPrimaryContainer,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: shape,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.primaryContainer,
        side: border,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textTheme.labelLarge?.copyWith(fontSize: 13),
        showCheckmark: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: shape.copyWith(side: border),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
