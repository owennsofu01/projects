import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/sync/sync_status_controller.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../models/daily_summary_settings.dart';
import '../services/daily_summary_notifier.dart';

/// Owns the daily summary setting and keeps the scheduled notifications in
/// step with today's sales and expenses while the app is running.
class DailySummaryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DashboardService _dashboard = DashboardService();
  final String userId;

  DailySummaryController(this.userId);

  final Rx<DailySummarySettings> settings = DailySummarySettings.defaults.obs;
  final RxBool isSaving = false.obs;

  StreamSubscription<SalesSummary>? _salesSub;
  StreamSubscription<double>? _expensesSub;
  SalesSummary _todaySales = SalesSummary.zero;
  double _todayExpenses = 0;
  Timer? _debounce;
  Timer? _midnight;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _db.collection(FirestoreCollections.users).doc(userId);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    _stopWatching();
    super.onClose();
  }

  Future<void> _load() async {
    final doc = await _userRef.get();
    settings.value = DailySummarySettings.fromMap(
      doc.data()?['dailySummary'] as Map<String, dynamic>?,
    );
    if (settings.value.enabled) {
      _watchToday();
    } else {
      // Clears anything still scheduled on this phone, e.g. after the
      // summary was turned off on another device.
      await DailySummaryNotifier.reschedule(
        enabled: false,
        hour: settings.value.hour,
        minute: settings.value.minute,
        today: DailySummaryNotifier.noSalesMessage,
      );
    }
  }

  /// Turns the summary on or off. Turning it on asks for notification
  /// permission first; returns false if that was denied.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled && !await DailySummaryNotifier.requestPermission()) {
      showErrorSnackbar(
        'Notifications are turned off for ProfitPulse. Allow them in your '
        'phone settings to get the daily summary.',
      );
      return false;
    }
    return _save(settings.value.copyWith(enabled: enabled));
  }

  Future<bool> setTime(int hour, int minute) =>
      _save(settings.value.copyWith(hour: hour, minute: minute));

  Future<bool> _save(DailySummarySettings value) async {
    try {
      isSaving.value = true;
      await Get.find<SyncStatusController>().commit(
        _userRef.set({'dailySummary': value.toMap()}, SetOptions(merge: true)),
      );
      settings.value = value;
      if (value.enabled) {
        _watchToday();
      } else {
        _stopWatching();
        await DailySummaryNotifier.reschedule(
          enabled: false,
          hour: value.hour,
          minute: value.minute,
          today: DailySummaryNotifier.noSalesMessage,
        );
      }
      return true;
    } catch (e) {
      showErrorSnackbar('Could not save the daily summary setting.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// (Re)subscribes to today's totals, and again just after midnight so a
  /// running app moves on to the new day.
  void _watchToday() {
    _stopWatching();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    _todaySales = SalesSummary.zero;
    _todayExpenses = 0;
    _salesSub = _dashboard.salesSummarySince(userId, startOfDay).listen((s) {
      _todaySales = s;
      _rescheduleSoon();
    });
    _expensesSub = _dashboard.expenseTotalSince(userId, startOfDay).listen((e) {
      _todayExpenses = e;
      _rescheduleSoon();
    });

    final nextMidnight = startOfDay.add(const Duration(days: 1, seconds: 5));
    _midnight = Timer(nextMidnight.difference(now), _watchToday);
    _rescheduleSoon();
  }

  void _stopWatching() {
    _salesSub?.cancel();
    _expensesSub?.cancel();
    _debounce?.cancel();
    _midnight?.cancel();
  }

  /// Debounced, since a checkout updates several documents at once.
  void _rescheduleSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final s = settings.value;
      DailySummaryNotifier.reschedule(
        enabled: s.enabled,
        hour: s.hour,
        minute: s.minute,
        today: _todayMessage(),
      );
    });
  }

  SummaryMessage _todayMessage() {
    final sales = _todaySales.totalAmount;
    final profit = _todaySales.totalProfit;
    if (sales <= 0 && _todayExpenses <= 0) {
      return DailySummaryNotifier.noSalesMessage;
    }
    return (
      title: 'Today: ${AppFormatter.currency(sales)} in sales',
      body:
          'Profit ${AppFormatter.currency(profit)} · '
          'Expenses ${AppFormatter.currency(_todayExpenses)} · '
          'Net ${AppFormatter.currency(profit - _todayExpenses)}',
    );
  }
}
