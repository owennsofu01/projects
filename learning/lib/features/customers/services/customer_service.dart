import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/customer_model.dart';
import '../models/ledger_entry.dart';

class CustomerService {
  CustomerService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> customersRef(String userId) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.customers);
  }

  Stream<List<CustomerModel>> getCustomers(String userId) {
    return customersRef(userId)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(CustomerModel.fromFirestore).toList());
  }

  Stream<CustomerModel?> watchCustomer(String userId, String customerId) {
    return customersRef(userId)
        .doc(customerId)
        .snapshots()
        .map((doc) => doc.exists ? CustomerModel.fromFirestore(doc) : null);
  }

  Stream<List<LedgerEntry>> getLedger(String userId, String customerId) {
    return customersRef(userId)
        .doc(customerId)
        .collection(FirestoreCollections.ledger)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(LedgerEntry.fromFirestore).toList());
  }

  /// Creates the customer with a zero balance. Returns the customer (its
  /// id is generated on-device, so it's usable straight away, even offline)
  /// and the pending write.
  ({CustomerModel customer, Future<void> write}) addCustomer(
    String userId, {
    required String name,
    required String phone,
  }) {
    final ref = customersRef(userId).doc();
    final now = DateTime.now();
    final customer = CustomerModel(
      id: ref.id,
      name: name,
      phone: phone,
      balance: 0,
      createdAt: now,
      updatedAt: now,
    );
    return (customer: customer, write: ref.set(customer.toFirestore()));
  }

  /// Updates name/phone only — the balance is changed exclusively through
  /// ledger transactions.
  Future<void> updateCustomer(
    String userId,
    String customerId, {
    required String name,
    required String phone,
  }) {
    return customersRef(userId).doc(customerId).update({
      'name': name,
      'phone': phone,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Deletes the customer and their ledger. Refused while they still owe
  /// money, so outstanding credit can't silently disappear.
  Future<void> deleteCustomer(String userId, String customerId) async {
    final customerRef = customersRef(userId).doc(customerId);
    final snap = await customerRef.get();
    final balance = (snap.data()?['balance'] as num? ?? 0).toDouble();
    if (balance > 0.005) {
      throw Exception('This customer still owes money');
    }

    final ledger = await customerRef
        .collection(FirestoreCollections.ledger)
        .get();
    final batch = _db.batch();
    for (final doc in ledger.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(customerRef);
    await batch.commit();
  }

  /// Records money received from the customer, reducing their balance.
  ///
  /// Online this is a transaction against the server's balance. Offline
  /// (transactions need the server) it checks the cached balance and
  /// queues a batch; the balance changes by increment either way, so it
  /// merges correctly with anything recorded elsewhere meanwhile.
  Future<void> recordPayment(
    String userId,
    String customerId, {
    required double amount,
    required bool online,
    String note = '',
  }) async {
    final customerRef = customersRef(userId).doc(customerId);
    final entryRef = customerRef.collection(FirestoreCollections.ledger).doc();

    void checkBalance(DocumentSnapshot<Map<String, dynamic>> snap) {
      final balance = (snap.data()?['balance'] as num? ?? 0).toDouble();
      if (amount > balance + 0.005) {
        throw Exception('Payment is more than the balance owed');
      }
    }

    final now = Timestamp.now();
    final balanceUpdate = {
      'balance': FieldValue.increment(-amount),
      'updatedAt': now,
    };
    final entry = {
      'type': LedgerEntryType.payment.name,
      'amount': amount,
      'date': now,
      'note': note,
    };

    if (online) {
      await _db.runTransaction((transaction) async {
        checkBalance(await transaction.get(customerRef));
        transaction.update(customerRef, balanceUpdate);
        transaction.set(entryRef, entry);
      });
      return;
    }

    checkBalance(await customerRef.get(const GetOptions(source: Source.cache)));
    final batch = _db.batch()
      ..update(customerRef, balanceUpdate)
      ..set(entryRef, entry);
    // Applied locally right away; only completes once the server has it.
    unawaited(batch.commit());
  }
}
