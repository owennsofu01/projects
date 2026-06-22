import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Consistent, themed feedback for any async action across the app —
/// every write operation should resolve through one of these two so success
/// and failure always look the same regardless of which screen triggered it.
void showSuccessSnackbar(String message) {
  Get.snackbar(
    'Success',
    message,
    backgroundColor: AppColors.income,
    colorText: Colors.white,
    icon: const Icon(Icons.check_circle, color: Colors.white),
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(12),
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
