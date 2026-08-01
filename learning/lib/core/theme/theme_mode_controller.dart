import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/firestore_collections.dart';
import '../utils/app_snackbars.dart';

/// Persists the user's preferred [ThemeMode] on their Firestore user doc
/// (`themeMode`), mirroring [CurrencyController] so display preferences
/// stay consistent across devices like the rest of their account data.
class ThemeModeController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  ThemeModeController(this.userId);

  Rx<ThemeMode> themeMode = Rx<ThemeMode>(ThemeMode.system);
  RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final doc = await _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .get();

    final mode = _fromStored(doc.data()?['themeMode'] as String?);
    themeMode.value = mode;
    Get.changeThemeMode(mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == themeMode.value) return;

    try {
      isSaving.value = true;
      await _db.collection(FirestoreCollections.users).doc(userId).update({
        'themeMode': _toStored(mode),
      });
      themeMode.value = mode;
      Get.changeThemeMode(mode);
    } catch (e) {
      showErrorSnackbar('Could not update theme. Please try again.');
    } finally {
      isSaving.value = false;
    }
  }

  static String _toStored(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  static ThemeMode _fromStored(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
