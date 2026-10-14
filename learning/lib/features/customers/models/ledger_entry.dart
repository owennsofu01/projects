import 'package:cloud_firestore/cloud_firestore.dart';

enum LedgerEntryType {
  /// Goods taken on credit — increases the balance.
  credit,

  /// Money received — decreases the balance.
  payment,
}

/// One movement on a customer's account.
class LedgerEntry {
  final String id;
  final LedgerEntryType type;
  final double amount;
  final DateTime date;

  /// The checkout this credit came from, for credit entries.
  final String? receiptId;
  final String note;

  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.receiptId,
    this.note = '',
  });

  factory LedgerEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return LedgerEntry(
      id: doc.id,
      type: LedgerEntryType.values.byName(data['type'] as String),
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      receiptId: data['receiptId'] as String?,
      note: data['note'] as String? ?? '',
    );
  }
}
