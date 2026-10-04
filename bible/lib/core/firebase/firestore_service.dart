import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game_result.dart';
import '../models/user_profile.dart';

/// Firestore access, scoped to the shapes described in firestore.rules:
/// `users/{uid}`, `users/{uid}/gameResults/{id}`, `leaderboards/{mode}/entries/{uid}`.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.collection('users').doc(uid);

  Future<void> pushProfile(UserProfile profile) => _userDoc(profile.uid).set(profile.toJson());

  Future<UserProfile?> fetchProfile(String uid) async {
    final snapshot = await _userDoc(uid).get();
    if (!snapshot.exists) return null;
    return UserProfile.fromJson(snapshot.data()!);
  }

  Future<void> pushGameResult(String uid, GameResult result) =>
      _userDoc(uid).collection('gameResults').doc(result.id).set(result.copyWith(synced: true).toJson());

  Future<void> pushLeaderboardScore(String gameModeId, String uid, String displayName, int score) =>
      _db.collection('leaderboards').doc(gameModeId).collection('entries').doc(uid).set({
        'uid': uid,
        'displayName': displayName,
        'score': score,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Stream<List<Map<String, dynamic>>> watchLeaderboard(String gameModeId, {int limit = 50}) {
    return _db
        .collection('leaderboards')
        .doc(gameModeId)
        .collection('entries')
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
