import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Tracks whether the device is online and whether any local Firestore
/// writes are still waiting to reach the server, and lets every save go
/// through [commit] so it behaves well offline.
///
/// Firestore applies writes to its on-device cache immediately and syncs
/// them when the connection returns, but the Future a write returns only
/// completes once the *server* acknowledges it — so awaiting it offline
/// leaves a save button spinning until the user is back online.
class SyncStatusController extends GetxController {
  final RxBool isOnline = true.obs;
  final RxBool hasPendingWrites = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  int _pendingWatch = 0;

  @override
  void onInit() {
    super.onInit();
    final connectivity = Connectivity();
    connectivity.checkConnectivity().then(_onConnectivity);
    _connectivitySub = connectivity.onConnectivityChanged.listen(
      _onConnectivity,
    );
    // Writes queued in an earlier session are persisted and still pending.
    watchPendingWrites();
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }

  void _onConnectivity(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == isOnline.value) return;
    isOnline.value = online;
    if (online) watchPendingWrites();
  }

  /// Runs a Firestore [write]. Online, waits for the server so errors
  /// surface as usual. Offline, returns once Firestore has queued it
  /// locally; it syncs on its own when the connection returns.
  Future<void> commit(Future<void> write) async {
    if (isOnline.value) {
      await write;
    } else {
      unawaited(
        write.catchError(
          (Object e) => debugPrint('Queued offline write failed: $e'),
        ),
      );
    }
    watchPendingWrites();
  }

  /// Marks writes as pending until Firestore reports every one has been
  /// acknowledged by the server. Call after queuing writes that didn't go
  /// through [commit] (e.g. an offline batch).
  void watchPendingWrites() {
    final watch = ++_pendingWatch;
    var settled = false;

    FirebaseFirestore.instance.waitForPendingWrites().then(
      (_) {
        settled = true;
        if (watch == _pendingWatch) hasPendingWrites.value = false;
      },
      // E.g. the user signed out; nothing left to report.
      onError: (Object _) => settled = true,
    );

    // Only flag "pending" if the writes don't settle almost immediately,
    // so a normal online save doesn't flash a syncing indicator.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!settled && watch == _pendingWatch) hasPendingWrites.value = true;
    });
  }
}
