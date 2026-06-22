import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';

/// Aggregate sales totals over a date range, computed from a single
/// Firestore listener rather than querying the same collection twice.
class SalesSummary {
  final double totalAmount;
  final double totalProfit;

  const SalesSummary({required this.totalAmount, required this.totalProfit});

  static const zero = SalesSummary(totalAmount: 0, totalProfit: 0);
}

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<SalesSummary> salesSummarySince(String userId, DateTime from) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.sales)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map((snapshot) {
          double totalAmount = 0;
          double totalProfit = 0;
          for (final doc in snapshot.docs) {
            totalAmount += (doc['totalAmount'] as num).toDouble();
            totalProfit += (doc['profit'] as num).toDouble();
          }
          return SalesSummary(
            totalAmount: totalAmount,
            totalProfit: totalProfit,
          );
        });
  }

  Stream<double> expenseTotalSince(String userId, DateTime from) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.expenses)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<double>(
            0,
            (total, doc) => total + (doc['amount'] as num).toDouble(),
          ),
        );
  }
}
