import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/models/bible_translation.dart';
import '../../core/models/difficulty.dart';
import '../../core/theme/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickCustomMusic(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      final picked = result?.files.single;
      if (picked?.path == null) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final ext = picked!.name.contains('.') ? picked.name.split('.').last : 'audio';
      final destPath = '${docsDir.path}/custom_music.$ext';
      final oldPath = ref.read(settingsProvider).customMusicPath;

      await File(picked.path!).copy(destPath);
      if (oldPath != null && oldPath != destPath && File(oldPath).existsSync()) {
        File(oldPath).deleteSync();
      }

      ref
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(customMusicPath: destPath, customMusicName: picked.name));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Couldn't use that file — try a different audio file.")));
      }
    }
  }

  void _resetCustomMusic(WidgetRef ref) {
    final oldPath = ref.read(settingsProvider).customMusicPath;
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(clearCustomMusic: true));
    if (oldPath != null && File(oldPath).existsSync()) {
      File(oldPath).deleteSync();
    }
  }

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
                  .map(
                    (d) => ChoiceChip(
                      label: Text(d.label),
                      selected: settings.defaultDifficulty == d,
                      onSelected: (_) => notifier.update((s) => s.copyWith(defaultDifficulty: d)),
                    ),
                  )
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
            subtitle: const Text('Tap, correct/incorrect, and win effects'),
            value: settings.soundOn,
            onChanged: (v) => notifier.update((s) => s.copyWith(soundOn: v)),
          ),
          SwitchListTile(
            title: const Text('Music'),
            subtitle: const Text('Background music during gameplay'),
            value: settings.musicOn,
            onChanged: (v) => notifier.update((s) => s.copyWith(musicOn: v)),
          ),
          ListTile(
            leading: const Icon(Icons.library_music_outlined),
            title: const Text('Background Track'),
            subtitle: Text(settings.customMusicName ?? 'Default ambient track'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (settings.customMusicPath != null)
                  IconButton(
                    icon: const Icon(Icons.restore),
                    tooltip: 'Reset to default track',
                    onPressed: () => _resetCustomMusic(ref),
                  ),
                IconButton(
                  icon: const Icon(Icons.folder_open_outlined),
                  tooltip: 'Choose a song from your phone',
                  onPressed: () => _pickCustomMusic(context, ref),
                ),
              ],
            ),
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
