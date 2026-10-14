import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../customers/models/customer_model.dart';
import '../models/cart_item.dart';
import '../models/sale_model.dart';
import '../services/sale_service.dart';

class SaleController extends GetxController {
  final SaleService _service = SaleService();
  final String userId;

  SaleController(this.userId);

  RxBool isSaving = false.obs;

  Stream<List<SaleModel>> get salesStream => _service.getSales(userId);

  /// Returns the receipt id on success, or null if the sale failed.
  Future<String?> checkout(
    List<CartItem> items, {
    CustomerModel? customer,
    double creditAmount = 0,
  }) async {
    try {
      isSaving.value = true;
      return await _service.checkout(
        userId: userId,
        items: items,
        customer: customer,
        creditAmount: creditAmount,
      );
    } catch (e) {
      showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
      return null;
    } finally {
      isSaving.value = false;
    }
  }
}
