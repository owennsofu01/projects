import 'package:cloud_firestore/cloud_firestore.dart';

/// What a sale line sold. Sales from before services existed have no
/// `kind` and are products.
enum SaleKind { product, service }

class SaleModel {
  final String id;

  /// What was sold. Product sales set [productId]; service sales set
  /// [serviceId] and leave [productId] empty.
  final SaleKind kind;
  final String productId;
  final String? serviceId;

  /// The product's or service's name at the time of the sale.
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

  /// How much of the whole receipt (not just this line) went on the
  /// customer's account — repeated on every line so any one line can
  /// rebuild the receipt.
  final double receiptCredit;

  /// Saved on this device but not yet confirmed by the server (e.g. made
  /// offline). Not stored — read from the snapshot's metadata.
  final bool isPendingSync;

  bool get isService => kind == SaleKind.service;

  SaleModel({
    required this.id,
    this.kind = SaleKind.product,
    required this.productId,
    this.serviceId,
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
    this.receiptCredit = 0,
    this.isPendingSync = false,
  });

  factory SaleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SaleModel(
      id: doc.id,
      kind: data['kind'] == SaleKind.service.name
          ? SaleKind.service
          : SaleKind.product,
      productId: data['productId'] as String? ?? '',
      serviceId: data['serviceId'] as String?,
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
      receiptCredit: (data['receiptCredit'] as num? ?? 0).toDouble(),
      isPendingSync: doc.metadata.hasPendingWrites,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (kind == SaleKind.service) ...{
        'kind': kind.name,
        'serviceId': serviceId,
      } else
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
      if (receiptCredit > 0) 'receiptCredit': receiptCredit,
    };
  }
}
