import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/service_model.dart';

/// Reads and writes the services a business offers.
class ServiceCatalogService {
  ServiceCatalogService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _servicesRef(String userId) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.services);
  }

  Future<void> addService(String userId, ServiceModel service) {
    return _servicesRef(userId).doc().set(service.toFirestore());
  }

  Future<void> updateService(String userId, ServiceModel service) {
    return _servicesRef(userId).doc(service.id).update(service.toFirestore());
  }

  /// Past sales keep the service's name, so they still show in sales,
  /// reports and service performance after it's deleted.
  Future<void> deleteService(String userId, String serviceId) {
    return _servicesRef(userId).doc(serviceId).delete();
  }

  Stream<List<ServiceModel>> getServices(String userId) {
    return _servicesRef(userId)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(ServiceModel.fromFirestore).toList());
  }
}
