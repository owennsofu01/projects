import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Consistent, themed feedback for any async action across the app —
/// every write operation should resolve through one of these two so success
/// and failure always look the same regardless of which screen triggered it.
/// [action], when given, adds a button (e.g. "RECEIPT") to the snackbar.
void showSuccessSnackbar(String message, {SnackbarAction? action}) {
  Get.snackbar(
    'Success',
    message,
    mainButton: _actionButton(action),
    // Longer when there's a button, so there's time to tap it.
    duration: Duration(seconds: action == null ? 3 : 6),
    backgroundColor: AppColors.income,
    colorText: Colors.white,
    icon: const Icon(Icons.check_circle, color: Colors.white),
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(12),
  );
}

void showWarningSnackbar(
  String title,
  String message, {
  SnackbarAction? action,
}) {
  Get.snackbar(
    title,
    message,
    mainButton: _actionButton(action),
    backgroundColor: Colors.orange.shade800,
    colorText: Colors.white,
    icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 5),
  );
}

void showErrorSnackbar(String message) {
  Get.snackbar(
    'Error',
    message,
    backgroundColor: AppColors.expense,
    colorText: Colors.white,
    icon: const Icon(Icons.error_outline, color: Colors.white),
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(12),
  );
}

/// A labelled button shown on the right of a snackbar.
class SnackbarAction {
  const SnackbarAction(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}

TextButton? _actionButton(SnackbarAction? action) {
  if (action == null) return null;
  return TextButton(
    onPressed: () {
      Get.closeCurrentSnackbar();
      action.onPressed();
    },
    child: Text(
      action.label,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    ),
  );
}
