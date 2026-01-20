import 'package:get/get.dart';
import '../models/product-model.dart';
import '../services/product-service.dart';

class ProductController extends GetxController {
  final ProductService _service = ProductService();
  final String userId;

  ProductController(this.userId);

  RxList<ProductModel> products = <ProductModel>[].obs;

  @override
  void onInit() {
    products.bindStream(_service.getProducts(userId));
    super.onInit();
  }

  Future<void> addProduct(ProductModel product) {
    return _service.addProduct(userId, product);
  }

  Future<void> updateProduct(ProductModel product) {
    return _service.updateProduct(userId, product);
  }

  Future<void> deleteProduct(String productId) {
    return _service.deleteProduct(userId, productId);
  }
}
