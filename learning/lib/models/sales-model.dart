import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double sellingPrice;
  final double totalAmount;
  final double costAmount;
  final double profit;
  final DateTime date;

  SaleModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellingPrice,
    required this.totalAmount,
    required this.costAmount,
    required this.profit,
    required this.date,
  });

  factory SaleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SaleModel(
      id: doc.id,
      productId: data['productId'],
      productName: data['productName'],
      quantity: data['quantity'],
      sellingPrice: (data['sellingPrice'] as num).toDouble(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      costAmount: (data['costAmount'] as num).toDouble(),
      profit: (data['profit'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'sellingPrice': sellingPrice,
      'totalAmount': totalAmount,
      'costAmount': costAmount,
      'profit': profit,
      'date': Timestamp.fromDate(date),
    };
  }
}
