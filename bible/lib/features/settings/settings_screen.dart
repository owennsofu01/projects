import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/bible_translation.dart';
import '../../core/models/difficulty.dart';
import '../../core/theme/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionHeader('Bible Translation'),
          RadioGroup<BibleTranslation>(
            groupValue: settings.translation,
            onChanged: (v) {
              if (v != null && v.available) {
                notifier.update((s) => s.copyWith(translation: v));
              }
            },
            child: Column(
              children: [
                for (final t in BibleTranslation.values)
                  RadioListTile<BibleTranslation>(
                    value: t,
                    toggleable: false,
                    title: Text(t.fullName),
                    subtitle: t.available ? null : const Text('License pending — not yet available'),
                  ),
              ],
            ),
          ),
          const Divider(),
          const _SectionHeader('Default Difficulty'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: Difficulty.values
                  .map((d) => ChoiceChip(
                        label: Text(d.label),
                        selected: settings.defaultDifficulty == d,
                        onSelected: (_) => notifier.update((s) => s.copyWith(defaultDifficulty: d)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const _SectionHeader('Accessibility & Play'),
          SwitchListTile(
            title: const Text('Kid Mode'),
            subtitle: const Text('Simpler visuals, narrated prompts, no timers'),
            value: settings.kidMode,
            onChanged: (v) => notifier.update((s) => s.copyWith(kidMode: v)),
          ),
          SwitchListTile(
            title: const Text('Sound'),
            value: settings.soundOn,
            onChanged: (v) => notifier.update((s) => s.copyWith(soundOn: v)),
          ),
          SwitchListTile(
            title: const Text('High Contrast'),
            value: settings.highContrast,
            onChanged: (v) => notifier.update((s) => s.copyWith(highContrast: v)),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings.darkMode,
            onChanged: (v) => notifier.update((s) => s.copyWith(darkMode: v)),
          ),
          ListTile(
            title: const Text('Text Size'),
            subtitle: Slider(
              value: settings.fontScale,
              min: 0.85,
              max: 1.5,
              divisions: 13,
              label: settings.fontScale.toStringAsFixed(2),
              onChanged: (v) => notifier.update((s) => s.copyWith(fontScale: v)),
            ),
          ),
          const Divider(),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Daily Verse Reminder'),
            subtitle: const Text('Plus a nudge if your streak is at risk'),
            value: settings.dailyReminderEnabled,
            onChanged: (v) => notifier.update((s) => s.copyWith(dailyReminderEnabled: v)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}
