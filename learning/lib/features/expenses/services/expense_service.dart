import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addExpense(String userId, ExpenseModel expense) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.expenses)
        .add(expense.toFirestore());
  }

  Stream<List<ExpenseModel>> getExpenses(String userId) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.expenses)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((e) => ExpenseModel.fromFirestore(e)).toList());
  }
}
