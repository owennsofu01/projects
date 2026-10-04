import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/progress/progress_providers.dart';
import '../data/compete_repository.dart';
import '../models/compete_models.dart';

final competeRepositoryProvider = Provider<CompeteRepository>((ref) => CompeteRepository());

/// The signed-in user's public player doc; null until they join the
/// leaderboard by choosing a display name.
final myPlayerProvider = StreamProvider<PlayerEntry?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(competeRepositoryProvider).watchPlayer(uid);
});

final globalLeaderboardProvider = StreamProvider.autoDispose<List<PlayerEntry>>(
  (ref) => ref.watch(competeRepositoryProvider).watchGlobalLeaderboard(),
);

/// Re-evaluated whenever something watching it rebuilds; the Compete screen
/// is short-lived enough that a UTC-midnight rollover mid-view is harmless.
final todayKeyProvider = Provider.autoDispose<String>((ref) => CompeteRepository.todayKey());

final dailyLeaderboardProvider = StreamProvider.autoDispose<List<DailyEntry>>(
  (ref) => ref.watch(competeRepositoryProvider).watchDailyLeaderboard(ref.watch(todayKeyProvider)),
);

final myDailyEntryProvider = StreamProvider.autoDispose<DailyEntry?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(competeRepositoryProvider).watchMyDailyEntry(ref.watch(todayKeyProvider), uid);
});

/// Friends plus the user themself, best score first.
final friendsLeaderboardProvider = StreamProvider.autoDispose<List<PlayerEntry>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  final repo = ref.watch(competeRepositoryProvider);
  return repo.watchFriendUids(uid).asyncMap((friendUids) => repo.fetchPlayers([uid, ...friendUids]));
});

final challengeProvider = StreamProvider.autoDispose.family<FriendChallenge?, String>(
  (ref, code) => ref.watch(competeRepositoryProvider).watchChallenge(code),
);

/// Keeps `players/{uid}.totalScore` in step with the local profile's
/// totalPoints after every recorded game, once the user has joined. Watched
/// by the app shell so it lives for the whole session.
final playerScoreSyncProvider = Provider<void>((ref) {
  ref.listen(userProfileProvider, (previous, next) {
    if (next == null || previous?.totalPoints == next.totalPoints) return;
    final player = ref.read(myPlayerProvider).value;
    if (player == null) return;
    ref
        .read(competeRepositoryProvider)
        .upsertPlayer(uid: next.uid, displayName: player.displayName, totalScore: next.totalPoints)
        .ignore(); // best-effort; Firestore queues it while offline
  });
});

class CompeteActions {
  CompeteActions(this._ref);

  final Ref _ref;

  CompeteRepository get _repo => _ref.read(competeRepositoryProvider);

  String _uid() {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) throw CompeteException('Still signing you in — try again in a moment.');
    return uid;
  }

  String displayName() => _ref.read(myPlayerProvider).value?.displayName ?? 'Player';

  /// Creates (or renames) the public player entry.
  Future<void> join(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty || name.length > 20) throw CompeteException('Pick a name between 1 and 20 characters.');
    final uid = _uid();
    _ref.read(userProfileProvider.notifier).setDisplayName(name);
    final total = _ref.read(userProfileProvider)?.totalPoints ?? 0;
    await _repo.upsertPlayer(uid: uid, displayName: name, totalScore: total);
  }

  Future<PlayerEntry> addFriend(String code) => _repo.addFriendByCode(uid: _uid(), rawCode: code);

  Future<FriendChallenge> createChallenge() => _repo.createChallenge(uid: _uid(), displayName: displayName());

  Future<FriendChallenge> findChallenge(String code) => _repo.fetchChallenge(code);

  Future<void> submit(CompetitionContext context, {required int score, required int correct, required int total}) {
    final uid = _uid();
    return switch (context) {
      DailyCompetition(:final dayKey) => _repo.submitDaily(
        dayKey: dayKey,
        uid: uid,
        displayName: displayName(),
        score: score,
        correctCount: correct,
        totalCount: total,
      ),
      FriendCompetition(:final code) => _repo.submitChallengeResult(
        code: code,
        uid: uid,
        result: ChallengeResult(displayName: displayName(), score: score, correctCount: correct),
      ),
    };
  }
}

final competeActionsProvider = Provider<CompeteActions>((ref) => CompeteActions(ref));
