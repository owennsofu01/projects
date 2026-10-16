import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../customers/models/customer_model.dart';
import '../../customers/models/ledger_entry.dart';
import '../models/cart_item.dart';
import '../models/sale_model.dart';

class SaleService {
  SaleService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Records every item in [items] as one checkout: each line becomes its
  /// own sale document (so per-product reporting is unchanged), all sharing
  /// one `receiptId`. All-or-nothing — if any product is short on stock,
  /// nothing is recorded.
  ///
  /// Service lines have no stock: they're costed at the service's
  /// materials cost and sold at the cart line's price.
  ///
  /// With a [customer], the sale is tagged with them, and [creditAmount]
  /// (the part of the total not paid now) is added to their balance with a
  /// matching ledger entry, in the same atomic write as the sale itself.
  ///
  /// [online] picks how: a transaction (re-reads everything from the
  /// server) when online, or — since transactions need the server — a
  /// batch costed from the on-device cache when offline, which Firestore
  /// queues and syncs on reconnect. Stock and balances change by
  /// increments in both cases, so an offline sale merges correctly with
  /// changes made elsewhere in the meantime.
  ///
  /// Returns the new receipt's id.
  Future<String> checkout({
    required String userId,
    required List<CartItem> items,
    required bool online,
    CustomerModel? customer,
    double creditAmount = 0,
  }) async {
    assert(creditAmount == 0 || customer != null);
    final userRef = _db.collection(FirestoreCollections.users).doc(userId);
    final productsRef = userRef.collection(FirestoreCollections.products);
    final receiptId = userRef.collection(FirestoreCollections.sales).doc().id;

    // Firestore transactions can only re-read specific documents, not run
    // queries — so FIFO order is determined by these queries up front, and
    // each candidate batch is individually re-read below for a consistent
    // snapshot of what's actually still left in it. (Filtering
    // remainingQuantity > 0 client-side rather than in the query avoids
    // needing a composite index for this.)
    final batchRefsByProduct =
        <String, List<DocumentReference<Map<String, dynamic>>>>{};
    for (final item in items) {
      final product = item.product;
      if (product == null) continue;
      final batchSnapshot = await productsRef
          .doc(product.id)
          .collection(FirestoreCollections.batches)
          .orderBy('purchasedAt')
          .get(
            GetOptions(source: online ? Source.serverAndCache : Source.cache),
          );
      batchRefsByProduct[product.id] = batchSnapshot.docs
          .where((doc) => (doc.data()['remainingQuantity'] as int) > 0)
          .map((doc) => doc.reference)
          .toList();
    }

    Future<void> apply(_Reader read, _Writer write) => _applyCheckout(
      read: read,
      write: write,
      userRef: userRef,
      items: items,
      batchRefsByProduct: batchRefsByProduct,
      receiptId: receiptId,
      customer: customer,
      creditAmount: creditAmount,
    );

    if (online) {
      await _db.runTransaction((transaction) async {
        await apply(
          transaction.get,
          _Writer(update: transaction.update, set: transaction.set),
        );
      });
    } else {
      final batch = _db.batch();
      await apply(_readCached, _Writer(update: batch.update, set: batch.set));
      // Applied to the local cache right away; the returned Future only
      // completes once the server has it, so it isn't awaited offline.
      unawaited(batch.commit());
    }

    return receiptId;
  }

  /// Reads and costs every line first (transactions require all reads
  /// before any write), then writes the sale lines, stock and batch
  /// changes, and any customer credit.
  Future<void> _applyCheckout({
    required _Reader read,
    required _Writer write,
    required DocumentReference<Map<String, dynamic>> userRef,
    required List<CartItem> items,
    required Map<String, List<DocumentReference<Map<String, dynamic>>>>
    batchRefsByProduct,
    required String receiptId,
    required CustomerModel? customer,
    required double creditAmount,
  }) async {
    final productsRef = userRef.collection(FirestoreCollections.products);
    final salesRef = userRef.collection(FirestoreCollections.sales);
    final lines = <_CostedLine>[];

    for (final item in items) {
      final product = item.product;
      if (product == null) {
        lines.add(_CostedLine(item: item, costAmount: item.serviceCost));
        continue;
      }

      final productRef = productsRef.doc(product.id);
      final productSnap = await read(productRef);
      final int currentStock = productSnap['stock'];

      if (currentStock < item.quantity) {
        throw Exception(
          'Insufficient stock for ${product.name} '
          '(only $currentStock left)',
        );
      }

      // Allocate the sale across purchase batches oldest-first (FIFO), so
      // cost of goods sold reflects what those specific units actually
      // cost — not a single cost figure a later restock could've
      // overwritten.
      double costAmount = 0;
      int remaining = item.quantity;
      final batchTakes = <DocumentReference<Map<String, dynamic>>, int>{};

      for (final batchRef in batchRefsByProduct[product.id]!) {
        if (remaining <= 0) break;

        final batchSnap = await read(batchRef);
        if (!batchSnap.exists) continue;

        final batchRemaining = batchSnap['remainingQuantity'] as int;
        if (batchRemaining <= 0) continue;

        final take = batchRemaining < remaining ? batchRemaining : remaining;
        final batchCost = (batchSnap['costPrice'] as num).toDouble();

        costAmount += take * batchCost;
        remaining -= take;
        batchTakes[batchRef] = take;
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
          costAmount: costAmount,
          batchTakes: batchTakes,
        ),
      );
    }

    final customerRef = customer == null
        ? null
        : userRef.collection(FirestoreCollections.customers).doc(customer.id);
    if (customerRef != null && !(await read(customerRef)).exists) {
      throw Exception('Customer not found');
    }

    final now = Timestamp.now();
    for (final line in lines) {
      final item = line.item;
      final product = item.product;
      final totalAmount = item.total;

      final productRef = line.productRef;
      if (productRef != null) {
        write.update(productRef, {
          'stock': FieldValue.increment(-item.quantity),
          'updatedAt': now,
        });
      }

      for (final entry in line.batchTakes.entries) {
        write.update(entry.key, {
          'remainingQuantity': FieldValue.increment(-entry.value),
        });
      }

      write.set(salesRef.doc(), {
        if (product != null)
          'productId': product.id
        else ...{
          'kind': SaleKind.service.name,
          'serviceId': item.service!.id,
        },
        'productName': item.name,
        'quantity': item.quantity,
        'sellingPrice': item.unitPrice,
        'totalAmount': totalAmount,
        'costAmount': line.costAmount,
        'profit': totalAmount - line.costAmount,
        'date': now,
        'receiptId': receiptId,
        if (customer != null) ...{
          'customerId': customer.id,
          'customerName': customer.name,
        },
        if (creditAmount > 0) 'receiptCredit': creditAmount,
      });
    }

    if (customerRef != null && creditAmount > 0) {
      write.update(customerRef, {
        'balance': FieldValue.increment(creditAmount),
        'updatedAt': now,
      });
      write.set(customerRef.collection(FirestoreCollections.ledger).doc(), {
        'type': LedgerEntryType.credit.name,
        'amount': creditAmount,
        'date': now,
        'receiptId': receiptId,
        'note': items.map((i) => '${i.quantity} × ${i.name}').join(', '),
      });
    }
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> _readCached(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return await ref.get(const GetOptions(source: Source.cache));
    } on FirebaseException {
      throw Exception(
        "Some of this sale's details aren't saved on this phone yet. "
        'Connect to the internet and try again.',
      );
    }
  }

  Stream<List<SaleModel>> getSales(String userId) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.sales)
        .orderBy('date', descending: true)
        // Metadata changes too, so a sale's "waiting to sync" marker clears
        // as soon as the server confirms it.
        .snapshots(includeMetadataChanges: true)
        .map((s) => s.docs.map((e) => SaleModel.fromFirestore(e)).toList());
  }
}

typedef _Reader =
    Future<DocumentSnapshot<Map<String, dynamic>>> Function(
      DocumentReference<Map<String, dynamic>> ref,
    );

/// The write operations shared by [Transaction] and [WriteBatch], so the
/// checkout logic is written once for both the online and offline paths.
class _Writer {
  const _Writer({required this.update, required this.set});

  final void Function(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  )
  update;
  final void Function(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  )
  set;
}

/// One cart line after it's been costed, holding everything needed for
/// the write phase.
class _CostedLine {
  const _CostedLine({
    required this.item,
    this.productRef,
    required this.costAmount,
    this.batchTakes = const {},
  });

  final CartItem item;

  /// Null for a service line, which has no stock to change.
  final DocumentReference<Map<String, dynamic>>? productRef;
  final double costAmount;

  /// Units taken from each purchase batch.
  final Map<DocumentReference<Map<String, dynamic>>, int> batchTakes;
}
