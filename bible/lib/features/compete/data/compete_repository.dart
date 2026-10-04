import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/compete_models.dart';

/// Thrown for problems the UI should show as-is (bad code, already played…).
class CompeteException implements Exception {
  CompeteException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Firestore access for leaderboards, friends, the daily challenge and
/// friend challenges. Shapes match firestore.rules:
/// `players/{uid}`, `players/{uid}/friends/{friendUid}`, `friendCodes/{code}`,
/// `daily/{dayKey}/entries/{uid}`, `challenges/{code}`.
class CompeteRepository {
  CompeteRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _random = Random.secure();

  /// No 0/O/1/I so codes survive being read aloud or typed from a screenshot.
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const codeLength = 6;

  /// Today's challenge key in UTC, so the whole world plays the same set.
  static String todayKey([DateTime? now]) {
    final utc = (now ?? DateTime.now()).toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';
  }

  static String normalizeCode(String input) => input.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  String _newCode() => List.generate(codeLength, (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)]).join();

  DocumentReference<Map<String, dynamic>> _player(String uid) => _db.collection('players').doc(uid);

  // ---------------------------------------------------------------- players

  Stream<PlayerEntry?> watchPlayer(String uid) =>
      _player(uid).snapshots().map((s) => s.exists ? PlayerEntry.fromJson(s.data()!) : null);

  /// Creates or updates the public player doc. Allocates a friend code the
  /// first time. [totalScore] only ever grows (enforced by rules too).
  Future<void> upsertPlayer({required String uid, required String displayName, required int totalScore}) async {
    final snapshot = await _player(uid).get();
    if (snapshot.exists) {
      final existing = PlayerEntry.fromJson(snapshot.data()!);
      await _player(uid).update({
        'displayName': displayName,
        'totalScore': max(totalScore, existing.totalScore),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final friendCode = await _claimFriendCode(uid);
    await _player(uid).set({
      'uid': uid,
      'displayName': displayName,
      'totalScore': totalScore,
      'friendCode': friendCode,
      'dailyStreak': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _claimFriendCode(String uid) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _newCode();
      final ref = _db.collection('friendCodes').doc(code);
      final claimed = await _db.runTransaction((tx) async {
        if ((await tx.get(ref)).exists) return false;
        tx.set(ref, {'uid': uid});
        return true;
      });
      if (claimed) return code;
    }
    throw CompeteException('Could not create a friend code. Please try again.');
  }

  Stream<List<PlayerEntry>> watchGlobalLeaderboard({int limit = 50}) => _db
      .collection('players')
      .orderBy('totalScore', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) => PlayerEntry.fromJson(d.data())).toList());

  // ---------------------------------------------------------------- friends

  Stream<List<String>> watchFriendUids(String uid) =>
      _player(uid).collection('friends').snapshots().map((s) => s.docs.map((d) => d.id).toList());

  /// Player docs for [uids], best score first. Firestore caps `whereIn` at
  /// 30 values, so larger friend lists are fetched in chunks.
  Future<List<PlayerEntry>> fetchPlayers(List<String> uids) async {
    final players = <PlayerEntry>[];
    for (var i = 0; i < uids.length; i += 30) {
      final chunk = uids.sublist(i, min(i + 30, uids.length));
      final snap = await _db.collection('players').where(FieldPath.documentId, whereIn: chunk).get();
      players.addAll(snap.docs.map((d) => PlayerEntry.fromJson(d.data())));
    }
    return players..sort((a, b) => b.totalScore.compareTo(a.totalScore));
  }

  /// Adds the owner of [rawCode] as a friend, both ways, and returns them.
  Future<PlayerEntry> addFriendByCode({required String uid, required String rawCode}) async {
    final code = normalizeCode(rawCode);
    if (code.length != codeLength) throw CompeteException('Friend codes are $codeLength characters.');

    final codeDoc = await _db.collection('friendCodes').doc(code).get();
    if (!codeDoc.exists) throw CompeteException('No player has the code $code.');
    final friendUid = codeDoc.data()!['uid'] as String;
    if (friendUid == uid) throw CompeteException("That's your own code — share it with a friend instead.");

    final friendSnap = await _player(friendUid).get();
    if (!friendSnap.exists) throw CompeteException('No player has the code $code.');

    final batch = _db.batch()
      ..set(_player(uid).collection('friends').doc(friendUid), {'addedAt': FieldValue.serverTimestamp()})
      ..set(_player(friendUid).collection('friends').doc(uid), {'addedAt': FieldValue.serverTimestamp()});
    await batch.commit();
    return PlayerEntry.fromJson(friendSnap.data()!);
  }

  // ------------------------------------------------------------------ daily

  Stream<List<DailyEntry>> watchDailyLeaderboard(String dayKey, {int limit = 50}) => _db
      .collection('daily')
      .doc(dayKey)
      .collection('entries')
      .orderBy('score', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) => DailyEntry.fromJson(d.data())).toList());

  Stream<DailyEntry?> watchMyDailyEntry(String dayKey, String uid) => _db
      .collection('daily')
      .doc(dayKey)
      .collection('entries')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? DailyEntry.fromJson(s.data()!) : null);

  /// Records the one allowed attempt for [dayKey] and advances the player's
  /// daily streak (consecutive UTC days with an entry).
  Future<void> submitDaily({
    required String dayKey,
    required String uid,
    required String displayName,
    required int score,
    required int correctCount,
    required int totalCount,
  }) async {
    final entryRef = _db.collection('daily').doc(dayKey).collection('entries').doc(uid);
    final yesterday = todayKey(DateTime.parse('${dayKey}T12:00:00Z').subtract(const Duration(days: 1)));
    final playedYesterday = (await _db.collection('daily').doc(yesterday).collection('entries').doc(uid).get()).exists;

    await _db.runTransaction((tx) async {
      if ((await tx.get(entryRef)).exists) {
        throw CompeteException("You've already played today's challenge.");
      }
      final playerSnap = await tx.get(_player(uid));
      final currentStreak = playerSnap.exists ? (playerSnap.data()!['dailyStreak'] as int? ?? 0) : 0;
      tx.set(entryRef, {
        'uid': uid,
        'displayName': displayName,
        'score': score,
        'correctCount': correctCount,
        'totalCount': totalCount,
        'completedAt': FieldValue.serverTimestamp(),
      });
      if (playerSnap.exists) {
        tx.update(_player(uid), {'dailyStreak': playedYesterday ? currentStreak + 1 : 1});
      }
    });
  }

  // ------------------------------------------------------------- challenges

  Future<FriendChallenge> createChallenge({required String uid, required String displayName}) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _newCode();
      final ref = _db.collection('challenges').doc(code);
      final data = {
        'code': code,
        'seed': _random.nextInt(1 << 31),
        'createdBy': uid,
        'createdByName': displayName,
        'results': <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
      };
      final created = await _db.runTransaction((tx) async {
        if ((await tx.get(ref)).exists) return false;
        tx.set(ref, data);
        return true;
      });
      if (created) {
        return FriendChallenge(
          code: code,
          seed: data['seed'] as int,
          createdBy: uid,
          createdByName: displayName,
          results: const {},
        );
      }
    }
    throw CompeteException('Could not create a challenge. Please try again.');
  }

  Future<FriendChallenge> fetchChallenge(String rawCode) async {
    final code = normalizeCode(rawCode);
    if (code.length != codeLength) throw CompeteException('Challenge codes are $codeLength characters.');
    final snap = await _db.collection('challenges').doc(code).get();
    if (!snap.exists) throw CompeteException('No challenge found for $code.');
    return FriendChallenge.fromJson(snap.data()!);
  }

  Stream<FriendChallenge?> watchChallenge(String code) => _db
      .collection('challenges')
      .doc(code)
      .snapshots()
      .map((s) => s.exists ? FriendChallenge.fromJson(s.data()!) : null);

  Future<void> submitChallengeResult({required String code, required String uid, required ChallengeResult result}) =>
      _db.collection('challenges').doc(code).update({'results.$uid': result.toJson()});
}
