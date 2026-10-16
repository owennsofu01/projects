import 'package:cloud_firestore/cloud_firestore.dart';

/// Something the business does rather than stocks — a haircut, braids, a
/// repair. Unlike a product it has no stock or purchase batches; its cost
/// per job is just the materials it uses up.
class ServiceModel {
  final String id;
  final String name;

  /// Usual price per job. Checkout can change it for a single sale (e.g.
  /// longer braids cost more).
  final double price;

  /// Materials used per job (extensions, relaxer, blades…), counted as the
  /// cost of each sale. Zero when the service uses none.
  final double materialsCost;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    this.materialsCost = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get profitPerJob => price - materialsCost;

  factory ServiceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ServiceModel(
      id: doc.id,
      name: data['name'] as String,
      price: (data['price'] as num).toDouble(),
      materialsCost: (data['materialsCost'] as num? ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'materialsCost': materialsCost,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
