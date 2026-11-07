import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/currency/currency_controller.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/utils/legal_links.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../daily_summary/controllers/daily_summary_controller.dart';
import '../../data_transfer/controllers/data_transfer_controller.dart';
import '../../data_transfer/screens/import_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../receipts/screens/business_profile_screen.dart';
import '../widgets/settings_group.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthController auth = Get.find<AuthController>();
  final CurrencyController currencyController = Get.find<CurrencyController>();
  final ThemeModeController themeController = Get.find<ThemeModeController>();
  final DailySummaryController summaryController =
      Get.find<DailySummaryController>();
  final DataTransferController dataController =
      Get.find<DataTransferController>();

  late Future<UserModel?> _profile = auth.fetchProfile();

  @override
  Widget build(BuildContext context) {
    var step = 0;
    Widget section(Widget child) => FadeSlideIn(
      delay: Duration(milliseconds: 50 * step++),
      child: Padding(padding: const EdgeInsets.only(bottom: 20), child: child),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              section(_profileCard()),
              section(
                SettingsGroup(
                  label: 'Business',
                  children: [
                    SettingsTile(
                      icon: Icons.storefront_outlined,
                      title: 'Business details',
                      subtitle: 'Shop name, phone and receipt message',
                      onTap: () => Get.to(() => BusinessProfileScreen()),
                    ),
                  ],
                ),
              ),
              section(
                SettingsGroup(
                  label: 'Preferences',
                  children: [_themeTile(), _currencyTile()],
                ),
              ),
              section(
                SettingsGroup(
                  label: 'Notifications',
                  children: [_summaryTiles()],
                ),
              ),
              section(
                SettingsGroup(
                  label: 'Data',
                  children: [
                    SettingsTile(
                      icon: Icons.upload_file_outlined,
                      title: 'Import from Excel',
                      subtitle: 'Add products, services and expenses',
                      onTap: () => Get.to(() => ImportScreen()),
                    ),
                    Obx(() {
                      final busy = dataController.isBusy.value;
                      return SettingsTile(
                        icon: Icons.backup_outlined,
                        title: 'Back up all data',
                        subtitle: 'Save or send an Excel copy of everything',
                        trailing: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.ios_share, size: 18),
                        onTap: busy ? null : dataController.shareBackup,
                      );
                    }),
                  ],
                ),
              ),
              section(
                SettingsGroup(
                  label: 'About',
                  children: [
                    const SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy policy',
                      trailing: Icon(Icons.open_in_new, size: 18),
                      onTap: openPrivacyPolicy,
                    ),
                  ],
                ),
              ),
              section(
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: Icons.logout,
                      title: 'Log out',
                      destructive: true,
                      trailing: const SizedBox.shrink(),
                      onTap: _confirmLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Get.to(() => const ProfileScreen());
          // The name may have been edited.
          if (mounted) setState(() => _profile = auth.fetchProfile());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<UserModel?>(
            future: _profile,
            builder: (context, snap) {
              final user = snap.data;
              final name = (user?.name.trim().isNotEmpty ?? false)
                  ? user!.name.trim()
                  : 'Your profile';
              return Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      name[0].toUpperCase(),
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'Name, password and account',
                          style: textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _themeTile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SettingsIcon(Icons.palette_outlined),
              const SizedBox(width: 14),
              Text('Appearance', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined, size: 18),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined, size: 18),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined, size: 18),
                    label: Text('Dark'),
                  ),
                ],
                selected: {themeController.themeMode.value},
                onSelectionChanged: (s) =>
                    themeController.setThemeMode(s.first),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyTile() {
    return Obx(() {
      final current = currencyController.currency.value;
      final saving = currencyController.isSaving.value;
      return SettingsTile(
        icon: Icons.payments_outlined,
        title: 'Currency',
        value: '${current.code} · ${current.symbol}',
        trailing: saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: saving ? null : _pickCurrency,
      );
    });
  }

  Future<void> _pickCurrency() async {
    final picked = await showModalBottomSheet<AppCurrency>(
      context: context,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        final current = currencyController.currency.value;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text('Display currency', style: textTheme.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  'Amounts are converted at live rates. Your records are '
                  'not changed.',
                  style: textTheme.bodySmall,
                ),
              ),
              for (final c in kSupportedCurrencies)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: SizedBox(
                    width: 32,
                    child: Text(
                      c.symbol,
                      style: textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  title: Text(c.name),
                  subtitle: Text(c.code),
                  trailing: c == current
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(c),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) currencyController.setCurrency(picked);
  }

  Widget _summaryTiles() {
    return Obx(() {
      final settings = summaryController.settings.value;
      final saving = summaryController.isSaving.value;
      final time = TimeOfDay(hour: settings.hour, minute: settings.minute);

      return Column(
        children: [
          SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Daily summary',
            subtitle: "Today's sales, profit and expenses",
            trailing: Switch(
              value: settings.enabled,
              onChanged: saving ? null : summaryController.setEnabled,
            ),
            onTap: saving
                ? null
                : () => summaryController.setEnabled(!settings.enabled),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: settings.enabled
                ? Column(
                    children: [
                      const Divider(indent: 64),
                      SettingsTile(
                        icon: Icons.schedule,
                        title: 'Send at',
                        value: time.format(context),
                        onTap: saving ? null : () => _pickTime(time),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      );
    });
  }

  Future<void> _pickTime(TimeOfDay initial) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      summaryController.setTime(picked.hour, picked.minute);
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You can sign back in any time.',
      confirmLabel: 'Log out',
    );
    if (ok) auth.logout();
  }
}
