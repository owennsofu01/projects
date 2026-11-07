import 'package:flutter/material.dart';

/// Semantic colors shared across the app, kept distinct from [ColorScheme]
/// so financial meaning (income vs. expense vs. profit) stays consistent
/// regardless of light/dark theme.
class AppColors {
  AppColors._();

  /// Colors taken from the app logo (assets/icon/app_icon.png).
  static const brandGreen = Color(0xFF3FA535);
  static const brandCyan = Color(0xFF1EB0D8);
  static const brandTeal = Color(0xFF0F7BA1);
  static const brandCharcoal = Color(0xFF4A4E54);

  /// Primary brand color — the logo's deep teal. Used for CTAs, selection
  /// and focus states.
  static const brand = brandTeal;

  /// Lighter teal for primary accents on dark surfaces (keeps contrast).
  static const brandOnDark = Color(0xFF4FC3E8);

  static const income = brandGreen;
  static const expense = Color(0xFFD64545);
  static const profit = brandTeal;
  static const warning = Color(0xFFE59E1B);

  // Neutrals, tinted slightly toward the logo charcoal so greys feel cohesive.
  static const ink = Color(0xFF1C1F23);
  static const inkMuted = Color(0xFF5F656D);
  static const line = Color(0xFFE4E7EB);
  static const canvas = Color(0xFFF7F8FA);
  static const paper = Color(0xFFFFFFFF);

  static const inkDark = Color(0xFFE8EAED);
  static const inkMutedDark = Color(0xFF9AA1A9);
  static const lineDark = Color(0xFF2C3036);
  static const canvasDark = Color(0xFF111316);
  static const paperDark = Color(0xFF181B1F);
}
