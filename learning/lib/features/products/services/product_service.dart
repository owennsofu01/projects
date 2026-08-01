import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/product_model.dart';
import '../models/stock_batch_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<ProductModel> productsRef(String userId) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.products)
        .withConverter<ProductModel>(
          fromFirestore: (snap, _) => ProductModel.fromFirestore(snap),
          toFirestore: (product, _) => product.toFirestore(),
        );
  }

  CollectionReference<Map<String, dynamic>> _batchesRef(
    String userId,
    String productId,
  ) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.products)
        .doc(productId)
        .collection(FirestoreCollections.batches);
  }

  /// Creates the product and, if it starts with stock on hand, its first
  /// purchase batch — atomically, so the two docs never drift apart.
  Future<void> addProduct(String userId, ProductModel product) {
    final productRef = productsRef(userId).doc();
    final writeBatch = _db.batch();

    writeBatch.set(productRef, product);

    if (product.stock > 0) {
      final initialBatchRef = _batchesRef(userId, productRef.id).doc();
      writeBatch.set(initialBatchRef, {
        'quantity': product.stock,
        'remainingQuantity': product.stock,
        'costPrice': product.costPrice,
        'purchasedAt': Timestamp.fromDate(product.createdAt),
      });
    }

    return writeBatch.commit();
  }

  Future<void> updateProduct(String userId, ProductModel product) {
    return productsRef(userId).doc(product.id).update(product.toFirestore());
  }

  /// Adds [quantity] to stock as a new purchase batch at [costPrice] —
  /// preserving this batch's own cost rather than overwriting whatever the
  /// previous restock cost. `product.costPrice` is also updated as a
  /// convenience "latest known cost" for display, but the batch record is
  /// the source of truth used to cost sales (see [SaleService]).
  Future<void> restockProduct(
    String userId,
    String productId,
    int quantity,
    double costPrice,
  ) {
    final productRef = productsRef(userId).doc(productId);
    final batchRef = _batchesRef(userId, productId).doc();
    final now = Timestamp.fromDate(DateTime.now());

    final writeBatch = _db.batch();
    writeBatch.update(productRef, {
      'stock': FieldValue.increment(quantity),
      'costPrice': costPrice,
      'updatedAt': now,
    });
    writeBatch.set(batchRef, {
      'quantity': quantity,
      'remainingQuantity': quantity,
      'costPrice': costPrice,
      'purchasedAt': now,
    });

    return writeBatch.commit();
  }

  Future<void> deleteProduct(String userId, String productId) {
    return productsRef(userId).doc(productId).delete();
  }

  Stream<List<ProductModel>> getProducts(String userId) {
    return productsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  /// Purchase history for a product, newest first.
  Stream<List<StockBatchModel>> getBatches(String userId, String productId) {
    return _batchesRef(userId, productId)
        .orderBy('purchasedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(StockBatchModel.fromFirestore).toList(),
        );
  }
}
