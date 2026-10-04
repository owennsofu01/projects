import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/router/route_paths.dart';
import '../providers/compete_providers.dart';

/// Live standings for one friend challenge. Updates as soon as the friend
/// submits, so the creator can leave this open and watch.
class ChallengeResultScreen extends ConsumerWidget {
  const ChallengeResultScreen({super.key, required this.code});

  final String code;

  Future<void> _share(Rect? origin) {
    return SharePlus.instance.share(
      ShareParams(
        subject: 'Bible GameHive challenge',
        text:
            "I challenge you on Bible GameHive! Open the Compete tab, tap \"Enter challenge code\" and use $code "
            'to play the same 10 questions. Think you can beat my score?',
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(currentUidProvider);
    final challengeAsync = ref.watch(challengeProvider(code));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.go(RoutePaths.compete)),
      ),
      body: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load challenge: $e')),
        data: (challenge) {
          if (challenge == null) return const Center(child: Text('This challenge no longer exists.'));
          final standings = challenge.standings;
          final waiting = standings.length < 2;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Challenge code', style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    challenge.code,
                    style: theme.textTheme.displaySmall?.copyWith(letterSpacing: 6, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    tooltip: 'Copy code',
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: challenge.code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (buttonContext) => FilledButton.icon(
                  onPressed: () {
                    final box = buttonContext.findRenderObject() as RenderBox?;
                    _share(box == null ? null : box.localToGlobal(Offset.zero) & box.size);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Send to a friend'),
                ),
              ),
              const SizedBox(height: 32),
              Text('Standings', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final (i, entry) in standings.indexed)
                Card(
                  color: entry.key == uid ? theme.colorScheme.secondaryContainer : null,
                  child: ListTile(
                    leading: Text(i == 0 && !waiting ? '🏆' : '#${i + 1}', style: const TextStyle(fontSize: 22)),
                    title: Text(entry.key == uid ? '${entry.value.displayName} (you)' : entry.value.displayName),
                    subtitle: Text('${entry.value.correctCount} correct'),
                    trailing: Text('${entry.value.score}', style: theme.textTheme.titleLarge),
                  ),
                ),
              if (waiting) ...[
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Waiting for your friend to play…'),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
