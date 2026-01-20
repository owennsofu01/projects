import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product-model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<ProductModel> productsRef(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('products')
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
