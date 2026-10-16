import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/import_rows.dart';

/// Saves rows read from a spreadsheet, skipping anything already in the
/// app so the same file (or a backup) can be imported more than once.
class ImportService {
  ImportService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Firestore allows 500 writes per batch; leave headroom.
  static const _writesPerBatch = 400;

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _db.collection(FirestoreCollections.users).doc(userId);

  /// Returns what will be saved and the pending write, which (like any
  /// Firestore write) only completes once the server has it.
  Future<({ImportResult result, Future<void> write})> import(
    String userId,
    ImportPreview preview,
  ) async {
    final userRef = _userRef(userId);
    final productsRef = userRef.collection(FirestoreCollections.products);
    final servicesRef = userRef.collection(FirestoreCollections.services);
    final expensesRef = userRef.collection(FirestoreCollections.expenses);

    // Products match by name, ignoring case.
    final existingNames = <String>{};
    if (preview.products.isNotEmpty) {
      final snapshot = await productsRef.get();
      for (final doc in snapshot.docs) {
        existingNames.add((doc['name'] as String).trim().toLowerCase());
      }
    }
    final newProducts = preview.products
        .where((p) => !existingNames.contains(p.name.toLowerCase()))
        .toList();

    // Services also match by name, ignoring case.
    final existingServices = <String>{};
    if (preview.services.isNotEmpty) {
      final snapshot = await servicesRef.get();
      for (final doc in snapshot.docs) {
        existingServices.add((doc['name'] as String).trim().toLowerCase());
      }
    }
    final newServices = preview.services
        .where((s) => !existingServices.contains(s.name.toLowerCase()))
        .toList();

    final existingExpenses = <String>{};
    if (preview.expenses.isNotEmpty) {
      final snapshot = await expensesRef.get();
      for (final doc in snapshot.docs) {
        existingExpenses.add(
          ImportedExpense(
            date: (doc['date'] as Timestamp).toDate(),
            title: (doc['title'] as String).trim(),
            category: (doc['category'] as String? ?? '').trim(),
            amount: (doc['amount'] as num).toDouble(),
          ).matchKey,
        );
      }
    }
    final newExpenses = preview.expenses
        .where((e) => existingExpenses.add(e.matchKey))
        .toList();

    final writer = _ChunkedWriter(_db);
    final now = Timestamp.now();

    for (final product in newProducts) {
      final productRef = productsRef.doc();
      writer.set(productRef, {
        'name': product.name,
        'costPrice': product.costPrice,
        'sellingPrice': product.sellingPrice,
        'stock': product.stock,
        'reorderLevel': product.reorderLevel,
        'barcode': product.barcode,
        'createdAt': now,
        'updatedAt': now,
      });
      // Opening stock gets a purchase batch, as when adding a product by
      // hand, so its sales are costed correctly.
      if (product.stock > 0) {
        writer.set(productRef.collection(FirestoreCollections.batches).doc(), {
          'quantity': product.stock,
          'remainingQuantity': product.stock,
          'costPrice': product.costPrice,
          'purchasedAt': now,
        });
      }
    }

    for (final service in newServices) {
      writer.set(servicesRef.doc(), {
        'name': service.name,
        'price': service.price,
        'materialsCost': service.materialsCost,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    for (final expense in newExpenses) {
      writer.set(expensesRef.doc(), {
        'title': expense.title,
        'amount': expense.amount,
        'category': expense.category,
        'date': Timestamp.fromDate(expense.date),
      });
    }

    return (
      result: ImportResult(
        productsAdded: newProducts.length,
        productsSkipped: preview.products.length - newProducts.length,
        servicesAdded: newServices.length,
        servicesSkipped: preview.services.length - newServices.length,
        expensesAdded: newExpenses.length,
        expensesSkipped: preview.expenses.length - newExpenses.length,
      ),
      write: writer.commit(),
    );
  }
}

/// Spreads writes over as many batches as needed.
class _ChunkedWriter {
  _ChunkedWriter(this._db);

  final FirebaseFirestore _db;
  final _batches = <WriteBatch>[];
  int _count = 0;

  void set(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) {
    if (_count % ImportService._writesPerBatch == 0) _batches.add(_db.batch());
    _batches.last.set(ref, data);
    _count++;
  }

  Future<void> commit() => Future.wait(_batches.map((b) => b.commit()));
}
