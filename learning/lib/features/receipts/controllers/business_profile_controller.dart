import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/sync/sync_status_controller.dart';
import '../../../core/utils/app_snackbars.dart';
import '../models/business_profile.dart';

/// Loads and saves the shop details shown on receipts.
class BusinessProfileController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  BusinessProfileController(this.userId);

  final Rx<BusinessProfile> profile = BusinessProfile.empty.obs;
  final RxBool isSaving = false.obs;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _db.collection(FirestoreCollections.users).doc(userId);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final doc = await _userRef.get();
    profile.value = BusinessProfile.fromMap(
      doc.data()?['businessProfile'] as Map<String, dynamic>?,
    );
  }

  Future<bool> save(BusinessProfile value) async {
    try {
      isSaving.value = true;
      await Get.find<SyncStatusController>().commit(
        _userRef.set({
          'businessProfile': value.toMap(),
        }, SetOptions(merge: true)),
      );
      profile.value = value;
      return true;
    } catch (e) {
      showErrorSnackbar('Could not save business details. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
