import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  /// Default [reorderLevel] for products that haven't set their own
  /// (including every product created before reorder levels existed).
  static const lowStockThreshold = 5;

  final String id;
  final String name;
  final double costPrice;
  final double sellingPrice;
  final int stock;

  /// Stock at or below this (but above zero) is flagged "low" — product
  /// cards, the post-sale warning, and Stock Intelligence all key off it.
  final int reorderLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.stock,
    this.reorderLevel = lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= reorderLevel;
  bool get needsAttention => isOutOfStock || isLowStock;

  // Convert Firestore → Dart
  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ProductModel(
      id: doc.id,
      name: data['name'],
      costPrice: (data['costPrice'] as num).toDouble(),
      sellingPrice: (data['sellingPrice'] as num).toDouble(),
      stock: data['stock'],
      reorderLevel:
          (data['reorderLevel'] as num?)?.toInt() ?? lowStockThreshold,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert Dart → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'stock': stock,
      'reorderLevel': reorderLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
