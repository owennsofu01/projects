import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/currency/currency_controller.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/utils/legal_links.dart';
import '../../profile/screens/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final CurrencyController currencyController = Get.find<CurrencyController>();
  final ThemeModeController themeController = Get.find<ThemeModeController>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            subtitle: const Text('Edit your name and manage your account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const ProfileScreen()),
          ),
          const Divider(height: 24),
          _SectionLabel('APPEARANCE', color: colorScheme.primary),
          Obx(
            () => RadioGroup<ThemeMode>(
              groupValue: themeController.themeMode.value,
              onChanged: (value) {
                if (value != null) themeController.setThemeMode(value);
              },
              child: Column(
                children: const [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    title: Text('System default'),
                    secondary: Icon(Icons.brightness_auto_outlined),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    title: Text('Light'),
                    secondary: Icon(Icons.light_mode_outlined),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    title: Text('Dark'),
                    secondary: Icon(Icons.dark_mode_outlined),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          _SectionLabel('CURRENCY', color: colorScheme.primary),
          Obx(
            () => RadioGroup<AppCurrency>(
              groupValue: currencyController.currency.value,
              onChanged: (value) {
                if (value != null) currencyController.setCurrency(value);
              },
              child: Column(
                children: [
                  for (final currency in kSupportedCurrencies)
                    RadioListTile<AppCurrency>(
                      value: currency,
                      enabled: !currencyController.isSaving.value,
                      title: Text('${currency.name} (${currency.code})'),
                      secondary: Text(
                        currency.symbol,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          _SectionLabel('ABOUT', color: colorScheme.primary),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: openPrivacyPolicy,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
