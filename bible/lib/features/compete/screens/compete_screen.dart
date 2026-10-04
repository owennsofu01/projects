import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/progress/progress_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../trivia/screens/trivia_play_screen.dart';
import '../data/compete_repository.dart';
import '../models/compete_models.dart';
import '../providers/compete_providers.dart';
import '../widgets/daily_challenge_card.dart';

enum _Board { global, today, friends }

class CompeteScreen extends ConsumerStatefulWidget {
  const CompeteScreen({super.key});

  @override
  ConsumerState<CompeteScreen> createState() => _CompeteScreenState();
}

class _CompeteScreenState extends ConsumerState<CompeteScreen> {
  _Board _board = _Board.global;

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_competeErrorMessage(e))));
  }

  Future<void> _addFriend() async {
    final code = await _askForCode(title: 'Add a friend', hint: "Enter your friend's code");
    if (code == null) return;
    try {
      final friend = await ref.read(competeActionsProvider).addFriend(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${friend.displayName} is now your friend!')));
      setState(() => _board = _Board.friends);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _invite(PlayerEntry me, Rect? origin) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Play Bible GameHive with me',
        text:
            'Play Bible GameHive with me! Open the Compete tab, tap "Add friend" and enter my code: '
            '${me.friendCode}',
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> _startChallenge() async {
    try {
      final challenge = await ref.read(competeActionsProvider).createChallenge();
      if (!mounted) return;
      context.push(
        RoutePaths.triviaPlay,
        extra: TriviaPlayArgs.competition(FriendCompetition(code: challenge.code, seed: challenge.seed)),
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _joinChallenge() async {
    final code = await _askForCode(title: 'Join a challenge', hint: 'Enter the challenge code');
    if (code == null) return;
    try {
      final challenge = await ref.read(competeActionsProvider).findChallenge(code);
      if (!mounted) return;
      final uid = ref.read(currentUidProvider);
      if (uid != null && challenge.hasPlayed(uid)) {
        context.push(RoutePaths.challengeResult, extra: challenge.code);
      } else {
        context.push(
          RoutePaths.triviaPlay,
          extra: TriviaPlayArgs.competition(FriendCompetition(code: challenge.code, seed: challenge.seed)),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<String?> _askForCode({required String title, required String hint}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: CompeteRepository.codeLength,
          decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(myPlayerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Compete')),
      body: playerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(icon: Icons.cloud_off, text: 'Leaderboards need an internet connection.\n$e'),
        data: (me) => me == null
            ? const _JoinCard()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const DailyChallengeCard(),
                  const SizedBox(height: 16),
                  _FriendsCard(
                    me: me,
                    onInvite: (origin) => _invite(me, origin),
                    onAddFriend: _addFriend,
                    onChallenge: _startChallenge,
                    onJoinChallenge: _joinChallenge,
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<_Board>(
                    segments: const [
                      ButtonSegment(value: _Board.global, label: Text('Global'), icon: Icon(Icons.public)),
                      ButtonSegment(value: _Board.today, label: Text('Today'), icon: Icon(Icons.today)),
                      ButtonSegment(value: _Board.friends, label: Text('Friends'), icon: Icon(Icons.group)),
                    ],
                    selected: {_board},
                    onSelectionChanged: (s) => setState(() => _board = s.first),
                  ),
                  const SizedBox(height: 12),
                  switch (_board) {
                    _Board.global => _PlayerBoard(provider: globalLeaderboardProvider, myUid: me.uid),
                    _Board.friends => _PlayerBoard(
                      provider: friendsLeaderboardProvider,
                      myUid: me.uid,
                      emptyText: 'Add friends with their code to see them here.',
                    ),
                    _Board.today => _DailyBoard(myUid: me.uid),
                  },
                ],
              ),
      ),
    );
  }
}

class _JoinCard extends ConsumerStatefulWidget {
  const _JoinCard();

  @override
  ConsumerState<_JoinCard> createState() => _JoinCardState();
}

class _JoinCardState extends ConsumerState<_JoinCard> {
  late final TextEditingController _controller;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userProfileProvider)?.displayName;
    _controller = TextEditingController(text: current == null || current == 'Guest' ? '' : current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(competeActionsProvider).join(_controller.text);
    } catch (e) {
      if (mounted) setState(() => _error = _competeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.emoji_events_outlined, size: 64, color: theme.colorScheme.secondary),
        const SizedBox(height: 16),
        Text('Join the leaderboard', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Pick a name other players will see. You can then play the daily challenge, '
          'add friends, and challenge them head-to-head.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Display name',
            border: const OutlineInputBorder(),
            errorText: _error,
            errorMaxLines: 3,
          ),
          onSubmitted: (_) => _join(),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy ? null : _join,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Join'),
        ),
      ],
    );
  }
}

class _FriendsCard extends StatelessWidget {
  const _FriendsCard({
    required this.me,
    required this.onInvite,
    required this.onAddFriend,
    required this.onChallenge,
    required this.onJoinChallenge,
  });

  final PlayerEntry me;
  final void Function(Rect? origin) onInvite;
  final VoidCallback onAddFriend;
  final VoidCallback onChallenge;
  final VoidCallback onJoinChallenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Friends', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Your code: ', style: theme.textTheme.bodyLarge),
                SelectableText(
                  me.friendCode ?? '…',
                  style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: me.friendCode == null
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: me.friendCode!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
                        },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Builder(
                  builder: (buttonContext) => FilledButton.tonalIcon(
                    onPressed: me.friendCode == null
                        ? null
                        : () {
                            final box = buttonContext.findRenderObject() as RenderBox?;
                            onInvite(box == null ? null : box.localToGlobal(Offset.zero) & box.size);
                          },
                    icon: const Icon(Icons.share),
                    label: const Text('Invite a friend'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onAddFriend,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Add friend'),
                ),
              ],
            ),
            const Divider(height: 32),
            Text('Head-to-head', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Play a round, then send your friend the challenge code. They get the exact same questions.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onChallenge,
                  icon: const Icon(Icons.sports_kabaddi),
                  label: const Text('Challenge a friend'),
                ),
                OutlinedButton.icon(
                  onPressed: onJoinChallenge,
                  icon: const Icon(Icons.login),
                  label: const Text('Enter challenge code'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerBoard extends ConsumerWidget {
  const _PlayerBoard({required this.provider, required this.myUid, this.emptyText = 'No players yet.'});

  final ProviderListenable<AsyncValue<List<PlayerEntry>>> provider;
  final String myUid;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(provider)
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _Message(icon: Icons.cloud_off, text: 'Could not load the leaderboard.\n$e'),
          data: (players) => Column(
            children: [
              for (final (i, p) in players.indexed)
                _RankRow(rank: i + 1, name: p.displayName, score: p.totalScore, isMe: p.uid == myUid),
              if (players.every((p) => p.uid == myUid)) _Message(icon: Icons.group_outlined, text: emptyText),
            ],
          ),
        );
  }
}

class _DailyBoard extends ConsumerWidget {
  const _DailyBoard({required this.myUid});

  final String myUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(dailyLeaderboardProvider)
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _Message(icon: Icons.cloud_off, text: 'Could not load today\'s scores.\n$e'),
          data: (entries) => entries.isEmpty
              ? const _Message(icon: Icons.today, text: "Nobody has played today's challenge yet. Be the first!")
              : Column(
                  children: [
                    for (final (i, e) in entries.indexed)
                      _RankRow(
                        rank: i + 1,
                        name: e.displayName,
                        score: e.score,
                        detail: '${e.correctCount}/${e.totalCount}',
                        isMe: e.uid == myUid,
                      ),
                  ],
                ),
        );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.name, required this.score, required this.isMe, this.detail});

  final int rank;
  final String name;
  final int score;
  final bool isMe;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
    return Card(
      elevation: 0,
      color: isMe
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: SizedBox(
          width: 36,
          child: Center(
            child: Text(
              medal ?? '#$rank',
              style: medal != null ? const TextStyle(fontSize: 22) : theme.textTheme.titleSmall,
            ),
          ),
        ),
        title: Text(isMe ? '$name (you)' : name, style: TextStyle(fontWeight: isMe ? FontWeight.bold : null)),
        subtitle: detail == null ? null : Text('$detail correct'),
        trailing: Text('$score', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

String _competeErrorMessage(Object e) {
  if (e is FirebaseException && (e.code == 'unavailable' || e.code == 'deadline-exceeded')) {
    return "Can't reach the server. Check your connection and try again.";
  }
  if (e is FirebaseException) return e.message ?? e.code;
  return e.toString();
}
