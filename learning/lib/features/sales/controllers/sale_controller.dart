import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../models/cart_item.dart';
import '../models/sale_model.dart';
import '../services/sale_service.dart';

class SaleController extends GetxController {
  final SaleService _service = SaleService();
  final String userId;

  SaleController(this.userId);

  RxBool isSaving = false.obs;

  Stream<List<SaleModel>> get salesStream => _service.getSales(userId);

  Future<bool> checkout(List<CartItem> items) async {
    try {
      isSaving.value = true;
      await _service.checkout(userId: userId, items: items);
      return true;
    } catch (e) {
      showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
