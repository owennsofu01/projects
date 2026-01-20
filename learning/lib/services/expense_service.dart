import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expenses-model.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addExpense(String userId, ExpenseModel expense) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .add(expense.toFirestore());
  }

  Stream<List<ExpenseModel>> getExpenses(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((e) => ExpenseModel.fromFirestore(e)).toList());
  }
}
