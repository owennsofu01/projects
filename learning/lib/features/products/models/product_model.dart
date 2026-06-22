import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final double costPrice;
  final double sellingPrice;
  final int stock;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.stock,
    required this.createdAt,
    required this.updatedAt,
  });

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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
