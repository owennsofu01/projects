import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../sales/models/sale_model.dart';

/// One service's summed sales over a period.
class ServiceSalesAggregate {
  /// Name on the most recent sale, so a deleted service still has one.
  final String name;
  final int jobs;
  final double revenue;
  final double cost;
  final double profit;

  const ServiceSalesAggregate({
    required this.name,
    required this.jobs,
    required this.revenue,
    required this.cost,
    required this.profit,
  });
}

/// Sums service sales per service, for the service performance table.
class ServicePerformanceService {
  ServicePerformanceService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _salesRef(String userId) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.sales);
  }

  /// Service sales per service id with a date in [from, to), or across
  /// all history when both are null. Filtered to services on the device
  /// rather than in the query, which would need a composite index.
  Stream<Map<String, ServiceSalesAggregate>> salesByService(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) {
    Query<Map<String, dynamic>> query = _salesRef(userId);
    if (from != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      );
    }
    if (to != null) {
      query = query.where('date', isLessThan: Timestamp.fromDate(to));
    }
    return query.snapshots().map(aggregate);
  }

  static Map<String, ServiceSalesAggregate> aggregate(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final latest = <String, DateTime>{};
    final byService = <String, ServiceSalesAggregate>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['kind'] != SaleKind.service.name) continue;
      final serviceId = data['serviceId'] as String?;
      if (serviceId == null) continue;

      final date = (data['date'] as Timestamp).toDate();
      final name = data['productName'] as String;
      final existing = byService[serviceId];
      final isNewest =
          latest[serviceId] == null || date.isAfter(latest[serviceId]!);
      if (isNewest) latest[serviceId] = date;

      byService[serviceId] = ServiceSalesAggregate(
        name: isNewest ? name : existing!.name,
        jobs: (existing?.jobs ?? 0) + (data['quantity'] as num).toInt(),
        revenue:
            (existing?.revenue ?? 0) + (data['totalAmount'] as num).toDouble(),
        cost: (existing?.cost ?? 0) + (data['costAmount'] as num).toDouble(),
        profit: (existing?.profit ?? 0) + (data['profit'] as num).toDouble(),
      );
    }
    return byService;
  }
}
