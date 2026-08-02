import '../models/badge_model.dart';
import '../models/game_result.dart';
import '../models/user_profile.dart';
import '../storage/local_cache_service.dart';

/// Local-first progress store. Every write lands in Hive immediately and is
/// safe to call fully offline; [SyncService] is responsible for pushing
/// anything still marked unsynced up to Firestore once connectivity returns.
class ProgressRepository {
  ProgressRepository();

  static const _profileKey = 'current_profile';

  UserProfile loadProfile(String uid) {
    final raw = LocalCacheService.profileBox.get(_profileKey);
    if (raw == null) {
      final fresh = UserProfile.guest(uid);
      saveProfile(fresh);
      return fresh;
    }
    final profile = UserProfile.fromJson(Map<String, dynamic>.from(raw as Map));
    if (profile.uid != uid) {
      // A different account signed in (e.g. guest -> linked account keeps the
      // same uid via linkWithCredential, but a fresh sign-in on a shared
      // device would not) — start that uid with a clean local profile.
      final fresh = UserProfile.guest(uid);
      saveProfile(fresh);
      return fresh;
    }
    return profile;
  }

  void saveProfile(UserProfile profile) {
    LocalCacheService.profileBox.put(_profileKey, profile.toJson());
  }

  List<GameResult> unsyncedResults() {
    return LocalCacheService.gameResultsBox.values
        .map((raw) => GameResult.fromJson(Map<String, dynamic>.from(raw as Map)))
        .where((r) => !r.synced)
        .toList();
  }

  void markResultSynced(String resultId) {
    final raw = LocalCacheService.gameResultsBox.get(resultId);
    if (raw == null) return;
    final result = GameResult.fromJson(Map<String, dynamic>.from(raw as Map));
    LocalCacheService.gameResultsBox.put(resultId, result.copyWith(synced: true).toJson());
  }

  /// Records a completed round: persists the result, recomputes the streak,
  /// bumps per-mode completion counts, marks the book complete if provided,
  /// and evaluates badge rules. Returns the updated profile and any newly
  /// earned badges so the UI can show a celebration.
  ({UserProfile profile, List<BadgeModel> newBadges}) recordGameResult(
    String uid,
    GameResult result,
  ) {
    LocalCacheService.gameResultsBox.put(result.id, result.toJson());

    var profile = loadProfile(uid);
    profile = _applyStreak(profile);

    final modeCounts = Map<String, int>.from(profile.gamesCompletedByMode);
    modeCounts[result.gameModeId] = (modeCounts[result.gameModeId] ?? 0) + 1;
    profile = profile.copyWith(gamesCompletedByMode: modeCounts);

    if (result.book != null) {
      final books = Map<String, bool>.from(profile.completedBooks);
      books[result.book!] = true;
      profile = profile.copyWith(completedBooks: books);
    }

    final newBadges = _evaluateBadges(profile);
    if (newBadges.isNotEmpty) {
      profile = profile.copyWith(badges: [...profile.badges, ...newBadges]);
    }

    saveProfile(profile);
    return (profile: profile, newBadges: newBadges);
  }

  /// Unlocks the level after [clearedLevel] if that's the current frontier
  /// (i.e. the user just passed the highest level they had access to).
  void unlockTriviaLevel(String uid, int clearedLevel) {
    final profile = loadProfile(uid);
    if (clearedLevel >= profile.triviaUnlockedLevel) {
      saveProfile(profile.copyWith(triviaUnlockedLevel: clearedLevel + 1));
    }
  }

  UserProfile _applyStreak(UserProfile profile) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = profile.lastPlayedDate;

    if (last == null) {
      return profile.copyWith(currentStreak: 1, longestStreak: 1, lastPlayedDate: today);
    }
    final lastDay = DateTime(last.year, last.month, last.day);
    final dayDiff = today.difference(lastDay).inDays;

    if (dayDiff == 0) return profile; // already played today, streak unchanged
    final newStreak = dayDiff == 1 ? profile.currentStreak + 1 : 1;
    return profile.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > profile.longestStreak ? newStreak : profile.longestStreak,
      lastPlayedDate: today,
    );
  }

  List<BadgeModel> _evaluateBadges(UserProfile profile) {
    final earned = profile.badges.map((b) => b.id).toSet();
    final now = DateTime.now();
    final newly = <BadgeModel>[];

    void award((String id, String title, String description) badge) {
      if (!earned.contains(badge.$1)) {
        newly.add(BadgeModel(id: badge.$1, title: badge.$2, description: badge.$3, earnedAt: now));
      }
    }

    if (profile.currentStreak >= 7) {
      award((BadgeCatalog.streak7.id, BadgeCatalog.streak7.title, BadgeCatalog.streak7.description));
    }
    if (profile.currentStreak >= 30) {
      award((BadgeCatalog.streak30.id, BadgeCatalog.streak30.title, BadgeCatalog.streak30.description));
    }
    if ((profile.gamesCompletedByMode['trivia'] ?? 0) >= 10) {
      award((BadgeCatalog.triviaNovice.id, BadgeCatalog.triviaNovice.title, BadgeCatalog.triviaNovice.description));
    }
    if ((profile.gamesCompletedByMode['verse_completion'] ?? 0) >= 10) {
      award((BadgeCatalog.verseMaster.id, BadgeCatalog.verseMaster.title, BadgeCatalog.verseMaster.description));
    }
    if ((profile.gamesCompletedByMode['word_search'] ?? 0) >= 10) {
      award((BadgeCatalog.wordSeeker.id, BadgeCatalog.wordSeeker.title, BadgeCatalog.wordSeeker.description));
    }
    return newly;
  }
}
