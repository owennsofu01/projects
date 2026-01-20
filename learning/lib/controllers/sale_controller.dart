import 'package:get/get.dart';
import '../models/product-model.dart';

import '../services/sale_service.dart';

class SaleController extends GetxController {
  final SaleService _service = SaleService();
  final String userId;

  SaleController(this.userId);

  Future<void> recordSale(ProductModel product, int quantity) async {
    try {
      await _service.recordSale(
        userId: userId,
        product: product,
        quantity: quantity,
      );
      Get.snackbar('Success', 'Sale recorded');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
