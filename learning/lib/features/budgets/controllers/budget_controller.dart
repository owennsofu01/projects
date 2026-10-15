import 'dart:async';

import 'package:get/get.dart';

import '../../../core/sync/sync_status_controller.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';

/// Monthly spending limits per expense category, and how much of each
/// has been used this calendar month.
class BudgetController extends GetxController {
  final BudgetService _service = BudgetService();
  final SyncStatusController _sync = Get.find<SyncStatusController>();
  final String userId;

  BudgetController(this.userId);

  final RxList<BudgetModel> budgets = <BudgetModel>[].obs;
  final RxMap<String, double> spentThisMonth = <String, double>{}.obs;
  final RxBool isSaving = false.obs;

  StreamSubscription<Map<String, double>>? _spentSub;
  Timer? _monthTimer;

  List<BudgetStatus> get statuses =>
      BudgetStatus.build(budgets, spentThisMonth);

  /// Budgets at or past [BudgetModel.nearThreshold] of their limit.
  List<BudgetStatus> get needingAttention =>
      statuses.where((s) => s.level != BudgetLevel.ok).toList();

  BudgetModel? budgetFor(String category) {
    final key = BudgetModel.keyFor(category);
    return budgets.firstWhereOrNull((b) => b.key == key);
  }

  @override
  void onInit() {
    budgets.bindStream(_service.getBudgets(userId));
    _watchCurrentMonth();
    super.onInit();
  }

  @override
  void onClose() {
    _spentSub?.cancel();
    _monthTimer?.cancel();
    super.onClose();
  }

  /// Totals reset on the 1st, so re-query when the month turns over
  /// while the app is open.
  void _watchCurrentMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    _spentSub?.cancel();
    _spentSub = _service
        .spentByCategorySince(userId, monthStart)
        .listen(spentThisMonth.assignAll);

    _monthTimer?.cancel();
    _monthTimer = Timer(
      DateTime(now.year, now.month + 1).difference(now),
      _watchCurrentMonth,
    );
  }

  Future<List<String>> expenseCategories() =>
      _service.expenseCategories(userId);

  Future<bool> saveBudget(BudgetModel budget) async {
    try {
      isSaving.value = true;
      await _sync.commit(_service.setBudget(userId, budget));
      return true;
    } catch (e) {
      showErrorSnackbar('Could not save budget. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteBudget(String category) async {
    try {
      await _sync.commit(_service.deleteBudget(userId, category));
      return true;
    } catch (e) {
      showErrorSnackbar('Could not delete budget. Please try again.');
      return false;
    }
  }

  /// Warns if an expense of [amount] took its category's budget to
  /// [BudgetModel.nearThreshold] or over the limit. [spentBefore] is
  /// [spentThisMonth] captured before saving, since the saved expense
  /// shows up in the live totals almost immediately. Returns whether it
  /// warned.
  bool warnIfExpenseCrossesBudget(
    String category,
    double amount, {
    required Map<String, double> spentBefore,
  }) {
    final budget = budgetFor(category);
    if (budget == null) return false;

    final status = BudgetStatus(
      budget: budget,
      spent: spentBefore[budget.key] ?? 0,
    );
    final crossed = budgetLevelCrossed(status, amount);
    if (crossed == null) return false;

    final spent = status.spent + amount;
    final limit = AppFormatter.currency(budget.monthlyLimit);
    switch (crossed) {
      case BudgetLevel.over:
        showWarningSnackbar(
          '${budget.category} budget exceeded',
          '${AppFormatter.currency(spent - budget.monthlyLimit)} over the '
              '$limit monthly limit.',
        );
      case BudgetLevel.near:
        showWarningSnackbar(
          '${budget.category} budget nearly used',
          '${(spent / budget.monthlyLimit * 100).round()}% of $limit used '
              'this month.',
        );
      case BudgetLevel.ok:
        return false;
    }
    return true;
  }
}
