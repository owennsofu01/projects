import 'package:cloud_firestore/cloud_firestore.dart';

/// A monthly spending limit for one expense category.
class BudgetModel {
  final String category;
  final double monthlyLimit;

  const BudgetModel({required this.category, required this.monthlyLimit});

  /// Share of the limit at which a category counts as "nearly used up".
  static const nearThreshold = 0.8;

  /// Expense categories are typed freely, so "Rent", "rent " and "RENT"
  /// all match the same budget. Blank falls under "Other", as on the
  /// dashboard's expense breakdown.
  static String keyFor(String category) {
    final trimmed = category.trim().toLowerCase();
    return trimmed.isEmpty ? 'other' : trimmed;
  }

  /// The doc id, so each category has at most one budget.
  String get key => keyFor(category);

  factory BudgetModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return BudgetModel(
      category: data['category'] as String,
      monthlyLimit: (data['monthlyLimit'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'category': category,
    'monthlyLimit': monthlyLimit,
    'updatedAt': Timestamp.now(),
  };
}

enum BudgetLevel { ok, near, over }

/// A budget joined with what's been spent against it this month.
class BudgetStatus {
  final BudgetModel budget;
  final double spent;

  const BudgetStatus({required this.budget, required this.spent});

  double get remaining => budget.monthlyLimit - spent;

  /// Spent as a share of the limit; above 1 when over.
  double get usage =>
      budget.monthlyLimit <= 0 ? 0 : spent / budget.monthlyLimit;

  BudgetLevel get level => levelFor(usage);

  static BudgetLevel levelFor(double usage) {
    if (usage > 1) return BudgetLevel.over;
    if (usage >= BudgetModel.nearThreshold) return BudgetLevel.near;
    return BudgetLevel.ok;
  }

  /// Joins [budgets] with [spentByKey] (totals keyed by
  /// [BudgetModel.keyFor]), most used first.
  static List<BudgetStatus> build(
    List<BudgetModel> budgets,
    Map<String, double> spentByKey,
  ) {
    return [
      for (final budget in budgets)
        BudgetStatus(budget: budget, spent: spentByKey[budget.key] ?? 0),
    ]..sort((a, b) => b.usage.compareTo(a.usage));
  }
}

/// What adding an expense of [amount] does to [status]'s budget: the
/// level it moves into, or null if it stays where it was (so a category
/// that is already over isn't re-flagged on every expense).
BudgetLevel? budgetLevelCrossed(BudgetStatus status, double amount) {
  final before = status.level;
  final after = BudgetStatus(
    budget: status.budget,
    spent: status.spent + amount,
  ).level;
  return after.index > before.index ? after : null;
}
