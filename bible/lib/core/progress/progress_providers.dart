import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_providers.dart';
import '../models/badge_model.dart';
import '../models/game_result.dart';
import '../models/user_profile.dart';
import '../sync/sync_service.dart';
import 'level_rules.dart';
import 'progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) => ProgressRepository());

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    progressRepository: ref.watch(progressRepositoryProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
    getUid: () => ref.read(currentUidProvider),
  )..start();
  ref.onDispose(service.dispose);
  return service;
});

/// The last badges awarded by [recordGameResult], so a screen can show a
/// one-off celebration then clear it.
final lastEarnedBadgesProvider = StateProvider<List<BadgeModel>>((ref) => []);

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier(this._ref) : super(null);

  final Ref _ref;

  void loadForUid(String uid) {
    state = _ref.read(progressRepositoryProvider).loadProfile(uid);
  }

  void recordGameResult(GameResult result) {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    final outcome = _ref.read(progressRepositoryProvider).recordGameResult(uid, result);
    state = outcome.profile;
    if (outcome.newBadges.isNotEmpty) {
      _ref.read(lastEarnedBadgesProvider.notifier).state = outcome.newBadges;
    }
    // Best-effort push; safe to call while offline (SyncService swallows failures).
    _ref.read(syncServiceProvider).syncNow();
  }

  void setDisplayName(String displayName) {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    final repo = _ref.read(progressRepositoryProvider);
    final updated = repo.loadProfile(uid).copyWith(displayName: displayName);
    repo.saveProfile(updated);
    state = updated;
    _ref.read(syncServiceProvider).syncNow();
  }

  /// Records a finished level round under the shared star rules. Returns
  /// null only if no user is signed in yet.
  LevelOutcome? recordLevel({
    required String gameModeId,
    required int level,
    required int correct,
    required int total,
  }) {
    return recordLevelStars(
      gameModeId: gameModeId,
      level: level,
      stars: LevelRules.starsFor(correct: correct, total: total),
    );
  }

  /// For modes that can't be failed (puzzles that only end once solved), so
  /// stars grade *how well* it was solved rather than accuracy.
  LevelOutcome? recordLevelStars({required String gameModeId, required int level, required int stars}) {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return null;
    final repo = _ref.read(progressRepositoryProvider);
    final outcome = repo.recordLevel(uid, gameModeId: gameModeId, level: level, stars: stars);
    state = repo.loadProfile(uid);
    _ref.read(syncServiceProvider).syncNow();
    return outcome;
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  final notifier = UserProfileNotifier(ref);
  final uid = ref.watch(currentUidProvider);
  if (uid != null) notifier.loadForUid(uid);
  return notifier;
});
