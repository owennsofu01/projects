import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/budget_model.dart';

class BudgetService {
  BudgetService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _db.collection(FirestoreCollections.users).doc(userId);

  CollectionReference<Map<String, dynamic>> _budgetsRef(String userId) =>
      _userRef(userId).collection(FirestoreCollections.budgets);

  Stream<List<BudgetModel>> getBudgets(String userId) {
    return _budgetsRef(userId)
        .orderBy('category')
        .snapshots()
        .map((s) => s.docs.map(BudgetModel.fromFirestore).toList());
  }

  /// Creates or replaces the budget for [budget]'s category.
  Future<void> setBudget(String userId, BudgetModel budget) {
    return _budgetsRef(userId).doc(budget.key).set(budget.toFirestore());
  }

  Future<void> deleteBudget(String userId, String category) {
    return _budgetsRef(userId).doc(BudgetModel.keyFor(category)).delete();
  }

  /// Expense totals since [from], keyed by [BudgetModel.keyFor].
  Stream<Map<String, double>> spentByCategorySince(
    String userId,
    DateTime from,
  ) {
    return _userRef(userId)
        .collection(FirestoreCollections.expenses)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map((snapshot) {
          final totals = <String, double>{};
          for (final doc in snapshot.docs) {
            final key = BudgetModel.keyFor(doc['category'] as String? ?? '');
            totals[key] =
                (totals[key] ?? 0) + (doc['amount'] as num).toDouble();
          }
          return totals;
        });
  }

  /// Every category name used on an expense so far, for suggestions.
  Future<List<String>> expenseCategories(String userId) async {
    final snapshot = await _userRef(
      userId,
    ).collection(FirestoreCollections.expenses).get();
    final byKey = <String, String>{};
    for (final doc in snapshot.docs) {
      final name = (doc['category'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      byKey.putIfAbsent(BudgetModel.keyFor(name), () => name);
    }
    return byKey.values.toList()..sort();
  }
}
