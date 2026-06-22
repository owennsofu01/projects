import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../products/models/product_model.dart';
import '../models/sale_model.dart';
import '../services/sale_service.dart';

class SaleController extends GetxController {
  final SaleService _service = SaleService();
  final String userId;

  SaleController(this.userId);

  RxBool isSaving = false.obs;

  Stream<List<SaleModel>> get salesStream => _service.getSales(userId);

  Future<bool> recordSale(ProductModel product, int quantity) async {
    try {
      isSaving.value = true;
      await _service.recordSale(
        userId: userId,
        product: product,
        quantity: quantity,
      );
      return true;
    } catch (e) {
      showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
