import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../models/product_model.dart';
import '../models/stock_batch_model.dart';
import '../services/product_service.dart';

class ProductController extends GetxController {
  final ProductService _service = ProductService();
  final String userId;

  ProductController(this.userId);

  RxList<ProductModel> products = <ProductModel>[].obs;
  RxBool isSaving = false.obs;

  @override
  void onInit() {
    products.bindStream(_service.getProducts(userId));
    super.onInit();
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      isSaving.value = true;
      await _service.addProduct(userId, product);
      return true;
    } catch (e) {
      showErrorSnackbar('Could not save product. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      isSaving.value = true;
      await _service.updateProduct(userId, product);
      return true;
    } catch (e) {
      showErrorSnackbar('Could not update product. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> restockProduct(
    String productId,
    int quantity,
    double costPrice,
  ) async {
    try {
      isSaving.value = true;
      await _service.restockProduct(userId, productId, quantity, costPrice);
      return true;
    } catch (e) {
      showErrorSnackbar('Could not update stock. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Stream<List<StockBatchModel>> batchesFor(String productId) =>
      _service.getBatches(userId, productId);

  Future<bool> deleteProduct(String productId) async {
    try {
      await _service.deleteProduct(userId, productId);
      return true;
    } catch (e) {
      showErrorSnackbar('Could not delete product. Please try again.');
      return false;
    }
  }
}
