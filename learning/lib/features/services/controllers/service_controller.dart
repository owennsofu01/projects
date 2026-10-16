import 'package:get/get.dart';

import '../../../core/sync/sync_status_controller.dart';
import '../../../core/utils/app_snackbars.dart';
import '../models/service_model.dart';
import '../services/service_catalog_service.dart';

class ServiceController extends GetxController {
  final ServiceCatalogService _service = ServiceCatalogService();
  final SyncStatusController _sync = Get.find<SyncStatusController>();
  final String userId;

  ServiceController(this.userId);

  final RxList<ServiceModel> services = <ServiceModel>[].obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    services.bindStream(_service.getServices(userId));
    super.onInit();
  }

  /// Another service already called [name] (ignoring case), other than
  /// the one with [exceptId].
  bool nameTaken(String name, {String? exceptId}) {
    final key = name.trim().toLowerCase();
    return services.any(
      (s) => s.id != exceptId && s.name.trim().toLowerCase() == key,
    );
  }

  Future<bool> addService(ServiceModel service) async {
    try {
      isSaving.value = true;
      await _sync.commit(_service.addService(userId, service));
      return true;
    } catch (e) {
      showErrorSnackbar('Could not save service. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateService(ServiceModel service) async {
    try {
      isSaving.value = true;
      await _sync.commit(_service.updateService(userId, service));
      return true;
    } catch (e) {
      showErrorSnackbar('Could not update service. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteService(String serviceId) async {
    try {
      await _sync.commit(_service.deleteService(userId, serviceId));
      return true;
    } catch (e) {
      showErrorSnackbar('Could not delete service. Please try again.');
      return false;
    }
  }
}
