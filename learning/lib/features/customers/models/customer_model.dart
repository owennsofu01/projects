import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String name;
  final String phone;

  /// What the customer currently owes. Only ever changed inside the same
  /// transaction that writes the matching ledger entry.
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get owesMoney => balance > 0.005;

  factory CustomerModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CustomerModel(
      id: doc.id,
      name: data['name'],
      phone: data['phone'] as String? ?? '',
      balance: (data['balance'] as num? ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
