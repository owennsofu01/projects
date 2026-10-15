import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/currency/currency_controller.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/utils/legal_links.dart';
import '../../daily_summary/controllers/daily_summary_controller.dart';
import '../../data_transfer/controllers/data_transfer_controller.dart';
import '../../data_transfer/screens/import_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../receipts/screens/business_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final CurrencyController currencyController = Get.find<CurrencyController>();
  final ThemeModeController themeController = Get.find<ThemeModeController>();
  final DailySummaryController summaryController =
      Get.find<DailySummaryController>();
  final DataTransferController dataController =
      Get.find<DataTransferController>();

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
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Business details'),
            subtitle: const Text('Shop name, phone and message on receipts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => BusinessProfileScreen()),
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
          _SectionLabel('NOTIFICATIONS', color: colorScheme.primary),
          Obx(() {
            final settings = summaryController.settings.value;
            final saving = summaryController.isSaving.value;
            final time = TimeOfDay(
              hour: settings.hour,
              minute: settings.minute,
            );

            return Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Daily summary'),
                  subtitle: const Text(
                    "Today's sales, profit and expenses in one notification",
                  ),
                  value: settings.enabled,
                  onChanged: saving ? null : summaryController.setEnabled,
                ),
                if (settings.enabled)
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Send at'),
                    trailing: Text(
                      time.format(context),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: saving
                        ? null
                        : () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: time,
                            );
                            if (picked != null) {
                              summaryController.setTime(
                                picked.hour,
                                picked.minute,
                              );
                            }
                          },
                  ),
              ],
            );
          }),
          const Divider(height: 24),
          _SectionLabel('DATA', color: colorScheme.primary),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Import from Excel'),
            subtitle: const Text(
              'Add products and expenses from a spreadsheet',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => ImportScreen()),
          ),
          Obx(
            () => ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Back up all data'),
              subtitle: const Text(
                'Save or send an Excel copy of everything in your account',
              ),
              trailing: dataController.isBusy.value
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined, size: 20),
              onTap: dataController.isBusy.value
                  ? null
                  : dataController.shareBackup,
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
