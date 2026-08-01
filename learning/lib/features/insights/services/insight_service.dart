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

  /// Sales summed per product over the trailing [days] days — the raw
  /// input the Stock Intelligence engine ranks products against.
  Stream<Map<String, ProductSalesAggregate>> salesByProductSince(
    String userId, {
    required int days,
  }) {
    final from = DateTime.now().subtract(Duration(days: days));

    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.sales)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map((snapshot) {
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
        });
  }
}
