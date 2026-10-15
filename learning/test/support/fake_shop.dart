import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:profitpulse/core/constants/firestore_collections.dart';
import 'package:profitpulse/features/customers/models/customer_model.dart';
import 'package:profitpulse/features/products/models/product_model.dart';

const userId = 'user-1';

/// Seeds an in-memory Firestore with the docs the services read, laid out
/// exactly as the app stores them.
class FakeShop {
  final FakeFirebaseFirestore db = FakeFirebaseFirestore();

  DocumentReference<Map<String, dynamic>> get userRef =>
      db.collection(FirestoreCollections.users).doc(userId);

  DocumentReference<Map<String, dynamic>> productRef(String id) =>
      userRef.collection(FirestoreCollections.products).doc(id);

  CollectionReference<Map<String, dynamic>> batchesRef(String productId) =>
      productRef(productId).collection(FirestoreCollections.batches);

  DocumentReference<Map<String, dynamic>> customerRef(String id) =>
      userRef.collection(FirestoreCollections.customers).doc(id);

  CollectionReference<Map<String, dynamic>> get salesRef =>
      userRef.collection(FirestoreCollections.sales);

  CollectionReference<Map<String, dynamic>> get expensesRef =>
      userRef.collection(FirestoreCollections.expenses);

  /// Adds a product whose stock is the sum of [batches], given oldest
  /// first as (quantity left, unit cost). [extraStock] adds units no batch
  /// covers, like products created before batch tracking.
  Future<ProductModel> addProduct(
    String id, {
    required double sellingPrice,
    required double costPrice,
    List<(int, double)> batches = const [],
    int extraStock = 0,
  }) async {
    final stock = batches.fold(0, (total, b) => total + b.$1) + extraStock;
    final now = DateTime(2026, 1, 1);
    final product = ProductModel(
      id: id,
      name: 'Product $id',
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      stock: stock,
      createdAt: now,
      updatedAt: now,
    );
    await productRef(id).set(product.toFirestore());

    for (var i = 0; i < batches.length; i++) {
      final (quantity, cost) = batches[i];
      await batchesRef(id).doc('b$i').set({
        'quantity': quantity,
        'remainingQuantity': quantity,
        'costPrice': cost,
        'purchasedAt': Timestamp.fromDate(now.add(Duration(days: i))),
      });
    }
    return product;
  }

  Future<CustomerModel> addCustomer(String id, {double balance = 0}) async {
    final now = DateTime(2026, 1, 1);
    final customer = CustomerModel(
      id: id,
      name: 'Customer $id',
      phone: '',
      balance: balance,
      createdAt: now,
      updatedAt: now,
    );
    await customerRef(id).set(customer.toFirestore());
    return customer;
  }

  Future<void> addSale({
    required String productId,
    required int quantity,
    required double totalAmount,
    required double profit,
    required DateTime date,
  }) {
    return salesRef.add({
      'productId': productId,
      'productName': 'Product $productId',
      'quantity': quantity,
      'sellingPrice': totalAmount / quantity,
      'totalAmount': totalAmount,
      'costAmount': totalAmount - profit,
      'profit': profit,
      'date': Timestamp.fromDate(date),
      'receiptId': 'r-$productId-${date.millisecondsSinceEpoch}',
    });
  }

  Future<void> addExpense({required double amount, required DateTime date}) {
    return expensesRef.add({
      'title': 'Expense',
      'amount': amount,
      'category': 'Rent',
      'date': Timestamp.fromDate(date),
    });
  }

  Future<int> stockOf(String productId) async =>
      (await productRef(productId).get())['stock'] as int;

  Future<List<int>> batchRemaining(String productId) async {
    final snap = await batchesRef(productId).orderBy('purchasedAt').get();
    return [for (final d in snap.docs) d['remainingQuantity'] as int];
  }

  Future<double> balanceOf(String customerId) async =>
      ((await customerRef(customerId).get())['balance'] as num).toDouble();
}
