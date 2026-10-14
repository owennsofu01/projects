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

  /// Shared by every line item recorded in the same checkout. Sales from
  /// before multi-item checkout have none and act as their own receipt.
  final String receiptId;

  /// Set when the sale was made to a saved customer.
  final String? customerId;
  final String? customerName;

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
    required this.receiptId,
    this.customerId,
    this.customerName,
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
      receiptId: data['receiptId'] as String? ?? doc.id,
      customerId: data['customerId'] as String?,
      customerName: data['customerName'] as String?,
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
      'receiptId': receiptId,
      if (customerId != null) 'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
    };
  }
}
