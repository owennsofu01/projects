import 'package:flutter/material.dart';

/// Semantic colors shared across the app, kept distinct from [ColorScheme]
/// so financial meaning (income vs. expense vs. profit) stays consistent
/// regardless of light/dark theme.
class AppColors {
  AppColors._();

  static const seed = Color(0xFF2563EB);
  static const income = Color(0xFF16A34A);
  static const expense = Color(0xFFDC2626);
  static const profit = Color(0xFF2563EB);
}
