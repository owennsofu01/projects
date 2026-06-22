import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/product_model.dart';

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

  Future<void> addProduct(String userId, ProductModel product) {
    return productsRef(userId).add(product);
  }

  Future<void> updateProduct(String userId, ProductModel product) {
    return productsRef(userId).doc(product.id).update(product.toFirestore());
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
}
