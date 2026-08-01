import 'package:cloud_firestore/cloud_firestore.dart';

/// One purchase of a product's stock at a specific cost. Products are
/// restocked at different prices over time, so instead of a single
/// overwritable `costPrice`, every purchase gets its own batch — the cost
/// each unit actually cost to buy is preserved even after later restocks.
class StockBatchModel {
  final String id;
  final int quantity;
  final int remainingQuantity;
  final double costPrice;
  final DateTime purchasedAt;

  const StockBatchModel({
    required this.id,
    required this.quantity,
    required this.remainingQuantity,
    required this.costPrice,
    required this.purchasedAt,
  });

  factory StockBatchModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return StockBatchModel(
      id: doc.id,
      quantity: data['quantity'] as int,
      remainingQuantity: data['remainingQuantity'] as int,
      costPrice: (data['costPrice'] as num).toDouble(),
      purchasedAt: (data['purchasedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'quantity': quantity,
      'remainingQuantity': remainingQuantity,
      'costPrice': costPrice,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
    };
  }
}
