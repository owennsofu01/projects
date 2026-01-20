import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product-model.dart';
import '../models/sales-model.dart';

class SaleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> recordSale({
    required String userId,
    required ProductModel product,
    required int quantity,
  }) async {
    final saleRef = _db
        .collection('users')
        .doc(userId)
        .collection('sales')
        .doc();

    final productRef = _db
        .collection('users')
        .doc(userId)
        .collection('products')
        .doc(product.id);

    final double totalAmount = product.sellingPrice * quantity;
    final double costAmount = product.costPrice * quantity;
    final double profit = totalAmount - costAmount;

    await _db.runTransaction((transaction) async {
      final productSnap = await transaction.get(productRef);

      final int currentStock = productSnap['stock'];

      if (currentStock < quantity) {
        throw Exception('Insufficient stock');
      }

      transaction.update(productRef, {
        'stock': currentStock - quantity,
        'updatedAt': Timestamp.now(),
      });

      transaction.set(saleRef, {
        'productId': product.id,
        'productName': product.name,
        'quantity': quantity,
        'sellingPrice': product.sellingPrice,
        'totalAmount': totalAmount,
        'costAmount': costAmount,
        'profit': profit,
        'date': Timestamp.now(),
      });
    });
  }

  Stream<List<SaleModel>> getSales(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('sales')
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((e) => SaleModel.fromFirestore(e)).toList());
  }
}
