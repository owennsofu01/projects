import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../products/models/product_model.dart';
import '../models/sale_model.dart';

class SaleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> recordSale({
    required String userId,
    required ProductModel product,
    required int quantity,
  }) async {
    final userRef = _db.collection(FirestoreCollections.users).doc(userId);
    final saleRef = userRef.collection(FirestoreCollections.sales).doc();
    final productRef = userRef
        .collection(FirestoreCollections.products)
        .doc(product.id);
    final batchesRef = productRef.collection(FirestoreCollections.batches);

    final double totalAmount = product.sellingPrice * quantity;

    // Firestore transactions can only re-read specific documents, not run
    // queries — so FIFO order is determined by this query up front, and
    // each candidate batch is individually re-read inside the transaction
    // below for a consistent snapshot of what's actually still left in it.
    // (Filtering remainingQuantity > 0 client-side rather than in the
    // query avoids needing a composite index for this.)
    final batchSnapshot = await batchesRef.orderBy('purchasedAt').get();
    final batchRefs = batchSnapshot.docs
        .where((doc) => (doc.data()['remainingQuantity'] as int) > 0)
        .map((doc) => doc.reference)
        .toList();

    await _db.runTransaction((transaction) async {
      final productSnap = await transaction.get(productRef);
      final int currentStock = productSnap['stock'];

      if (currentStock < quantity) {
        throw Exception('Insufficient stock');
      }

      // Allocate the sale across purchase batches oldest-first (FIFO), so
      // cost of goods sold reflects what those specific units actually
      // cost — not a single cost figure a later restock could've
      // overwritten.
      double costAmount = 0;
      int remaining = quantity;
      final batchUpdates = <DocumentReference<Map<String, dynamic>>, int>{};

      for (final batchRef in batchRefs) {
        if (remaining <= 0) break;

        final batchSnap = await transaction.get(batchRef);
        if (!batchSnap.exists) continue;

        final batchRemaining = batchSnap['remainingQuantity'] as int;
        if (batchRemaining <= 0) continue;

        final take = batchRemaining < remaining ? batchRemaining : remaining;
        final batchCost = (batchSnap['costPrice'] as num).toDouble();

        costAmount += take * batchCost;
        remaining -= take;
        batchUpdates[batchRef] = batchRemaining - take;
      }

      if (remaining > 0) {
        // No batch covers the rest — e.g. a product created before batch
        // tracking existed. Fall back to its last known unit cost rather
        // than leaving those units uncosted.
        final fallbackCost = (productSnap['costPrice'] as num).toDouble();
        costAmount += remaining * fallbackCost;
      }

      final double profit = totalAmount - costAmount;

      transaction.update(productRef, {
        'stock': currentStock - quantity,
        'updatedAt': Timestamp.now(),
      });

      for (final entry in batchUpdates.entries) {
        transaction.update(entry.key, {'remainingQuantity': entry.value});
      }

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
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.sales)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((e) => SaleModel.fromFirestore(e)).toList());
  }
}
