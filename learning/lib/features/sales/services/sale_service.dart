import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/cart_item.dart';
import '../models/sale_model.dart';

class SaleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Records every item in [items] as one checkout: each line becomes its
  /// own sale document (so per-product reporting is unchanged), all sharing
  /// one `receiptId`. Runs as a single transaction — if any product is
  /// short on stock, nothing is recorded.
  Future<void> checkout({
    required String userId,
    required List<CartItem> items,
  }) async {
    final userRef = _db.collection(FirestoreCollections.users).doc(userId);
    final salesRef = userRef.collection(FirestoreCollections.sales);
    final productsRef = userRef.collection(FirestoreCollections.products);
    final receiptId = salesRef.doc().id;

    // Firestore transactions can only re-read specific documents, not run
    // queries — so FIFO order is determined by these queries up front, and
    // each candidate batch is individually re-read inside the transaction
    // below for a consistent snapshot of what's actually still left in it.
    // (Filtering remainingQuantity > 0 client-side rather than in the
    // query avoids needing a composite index for this.)
    final batchRefsByProduct =
        <String, List<DocumentReference<Map<String, dynamic>>>>{};
    for (final item in items) {
      final batchSnapshot = await productsRef
          .doc(item.product.id)
          .collection(FirestoreCollections.batches)
          .orderBy('purchasedAt')
          .get();
      batchRefsByProduct[item.product.id] = batchSnapshot.docs
          .where((doc) => (doc.data()['remainingQuantity'] as int) > 0)
          .map((doc) => doc.reference)
          .toList();
    }

    await _db.runTransaction((transaction) async {
      // Transactions require every read to happen before any write, so
      // read and cost all lines first, then apply the writes together.
      final lines = <_CostedLine>[];

      for (final item in items) {
        final productRef = productsRef.doc(item.product.id);
        final productSnap = await transaction.get(productRef);
        final int currentStock = productSnap['stock'];

        if (currentStock < item.quantity) {
          throw Exception(
            'Insufficient stock for ${item.product.name} '
            '(only $currentStock left)',
          );
        }

        // Allocate the sale across purchase batches oldest-first (FIFO), so
        // cost of goods sold reflects what those specific units actually
        // cost — not a single cost figure a later restock could've
        // overwritten.
        double costAmount = 0;
        int remaining = item.quantity;
        final batchUpdates = <DocumentReference<Map<String, dynamic>>, int>{};

        for (final batchRef in batchRefsByProduct[item.product.id]!) {
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

        lines.add(
          _CostedLine(
            item: item,
            productRef: productRef,
            newStock: currentStock - item.quantity,
            costAmount: costAmount,
            batchUpdates: batchUpdates,
          ),
        );
      }

      final now = Timestamp.now();
      for (final line in lines) {
        final product = line.item.product;
        final totalAmount = line.item.total;

        transaction.update(line.productRef, {
          'stock': line.newStock,
          'updatedAt': now,
        });

        for (final entry in line.batchUpdates.entries) {
          transaction.update(entry.key, {'remainingQuantity': entry.value});
        }

        transaction.set(salesRef.doc(), {
          'productId': product.id,
          'productName': product.name,
          'quantity': line.item.quantity,
          'sellingPrice': product.sellingPrice,
          'totalAmount': totalAmount,
          'costAmount': line.costAmount,
          'profit': totalAmount - line.costAmount,
          'date': now,
          'receiptId': receiptId,
        });
      }
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

/// One cart line after it's been costed inside the checkout transaction,
/// holding everything needed for the write phase.
class _CostedLine {
  const _CostedLine({
    required this.item,
    required this.productRef,
    required this.newStock,
    required this.costAmount,
    required this.batchUpdates,
  });

  final CartItem item;
  final DocumentReference<Map<String, dynamic>> productRef;
  final int newStock;
  final double costAmount;
  final Map<DocumentReference<Map<String, dynamic>>, int> batchUpdates;
}
