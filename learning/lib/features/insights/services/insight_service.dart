import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';

/// A product's summed sales activity over the lookback window.
class ProductSalesAggregate {
  final int quantity;
  final double revenue;
  final double profit;

  const ProductSalesAggregate({
    required this.quantity,
    required this.revenue,
    required this.profit,
  });

  static const zero = ProductSalesAggregate(quantity: 0, revenue: 0, profit: 0);

  ProductSalesAggregate add({
    required int quantity,
    required double revenue,
    required double profit,
  }) {
    return ProductSalesAggregate(
      quantity: this.quantity + quantity,
      revenue: this.revenue + revenue,
      profit: this.profit + profit,
    );
  }
}

class InsightService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _salesRef(String userId) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.sales);
  }

  Map<String, ProductSalesAggregate> _aggregateByProduct(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final byProduct = <String, ProductSalesAggregate>{};
    for (final doc in snapshot.docs) {
      final productId = doc['productId'] as String;
      final existing = byProduct[productId] ?? ProductSalesAggregate.zero;
      byProduct[productId] = existing.add(
        quantity: (doc['quantity'] as num).toInt(),
        revenue: (doc['totalAmount'] as num).toDouble(),
        profit: (doc['profit'] as num).toDouble(),
      );
    }
    return byProduct;
  }

  /// Sales summed per product over the trailing [days] days — the raw
  /// input the Stock Intelligence engine ranks products against.
  Stream<Map<String, ProductSalesAggregate>> salesByProductSince(
    String userId, {
    required int days,
  }) {
    final from = DateTime.now().subtract(Duration(days: days));

    return _salesRef(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map(_aggregateByProduct);
  }

  /// Sales summed per product with a date in [from, to) — the input for a
  /// single-month view of the product profitability table.
  Stream<Map<String, ProductSalesAggregate>> salesByProductBetween(
    String userId, {
    required DateTime from,
    required DateTime to,
  }) {
    return _salesRef(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .snapshots()
        .map(_aggregateByProduct);
  }

  /// Sales summed per product across all recorded history — the input for
  /// the all-time product profitability table.
  Stream<Map<String, ProductSalesAggregate>> salesByProductAllTime(
    String userId,
  ) {
    return _salesRef(userId).snapshots().map(_aggregateByProduct);
  }
}
