import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firestore_service.dart';
import '../progress/progress_repository.dart';

/// Watches connectivity and pushes anything recorded offline (game results,
/// profile updates) up to Firestore as soon as the device is back online.
/// Never blocks gameplay — every write already landed locally via
/// [ProgressRepository] before this ever runs.
class SyncService {
  SyncService({
    required this.progressRepository,
    required this.firestoreService,
    required this.getUid,
  });

  final ProgressRepository progressRepository;
  final FirestoreService firestoreService;
  final String? Function() getUid;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void start() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncNow();
      }
    });
  }

  void dispose() => _subscription?.cancel();

  Future<void> syncNow() async {
    final uid = getUid();
    if (uid == null) return;

    try {
      final profile = progressRepository.loadProfile(uid);
      await firestoreService.pushProfile(profile);

      for (final result in progressRepository.unsyncedResults()) {
        await firestoreService.pushGameResult(uid, result);
        progressRepository.markResultSynced(result.id);
      }
    } catch (e, st) {
      // Sync is best-effort and retried on the next connectivity change or
      // app resume — surface for debugging only, never interrupt the user.
      debugPrint('Sync failed, will retry later: $e\n$st');
    }
  }
}
