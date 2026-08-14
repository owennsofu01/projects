import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../expenses/models/expense_model.dart';
import '../../sales/models/sale_model.dart';

/// A one-time (non-streaming) snapshot of sales and expenses for a date
/// range — reports are a point-in-time pull rather than a live view, so an
/// export always matches exactly what was on screen when it was generated.
class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<SaleModel>> getSales(
    String userId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.sales)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map(SaleModel.fromFirestore).toList();
  }

  Future<List<ExpenseModel>> getExpenses(
    String userId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.expenses)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map(ExpenseModel.fromFirestore).toList();
  }
}
