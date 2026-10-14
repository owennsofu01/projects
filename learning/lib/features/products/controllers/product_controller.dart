import 'package:get/get.dart';

import '../../../core/sync/sync_status_controller.dart';
import '../../../core/utils/app_snackbars.dart';
import '../models/product_model.dart';
import '../models/stock_batch_model.dart';
import '../services/product_service.dart';

class ProductController extends GetxController {
  final ProductService _service = ProductService();
  final SyncStatusController _sync = Get.find<SyncStatusController>();
  final String userId;

  ProductController(this.userId);

  RxList<ProductModel> products = <ProductModel>[].obs;
  RxBool isSaving = false.obs;

  @override
  void onInit() {
    products.bindStream(_service.getProducts(userId));
    super.onInit();
  }

  /// The product with this exact [barcode], if any.
  ProductModel? findByBarcode(String barcode) {
    final code = barcode.trim();
    if (code.isEmpty) return null;
    return products.firstWhereOrNull((p) => p.barcode == code);
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      isSaving.value = true;
      await _sync.commit(_service.addProduct(userId, product));
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
      await _sync.commit(_service.updateProduct(userId, product));
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
      await _sync.commit(
        _service.restockProduct(userId, productId, quantity, costPrice),
      );
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

  Future<bool> updateStock(
    String productId,
    int newQuantity,
    double costPrice,
  ) async {
    // Stock corrections re-allocate purchase batches in a transaction,
    // which needs the server.
    if (!_sync.isOnline.value) {
      showErrorSnackbar(
        'Correcting stock needs an internet connection. Use Restock for '
        'new stock while offline.',
      );
      return false;
    }
    try {
      isSaving.value = true;
      await _service.setStock(
        userId,
        productId,
        newQuantity: newQuantity,
        costPrice: costPrice,
      );
      return true;
    } catch (e) {
      showErrorSnackbar('Could not update stock. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _sync.commit(_service.deleteProduct(userId, productId));
      return true;
    } catch (e) {
      showErrorSnackbar('Could not delete product. Please try again.');
      return false;
    }
  }
}
