import 'package:get/get.dart';

import '../auth/controllers/auth_controller.dart';
import '../dashboard/controllers/dashboard_controller.dart';
import '../expenses/controllers/expense_controller.dart';
import '../products/controllers/product_controller.dart';
import '../sales/controllers/sale_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final userId = Get.find<AuthController>().userId;

    Get.lazyPut<ProductController>(() => ProductController(userId));
    Get.lazyPut<SaleController>(() => SaleController(userId));
    Get.lazyPut<ExpenseController>(() => ExpenseController(userId));
    Get.lazyPut<DashboardController>(() => DashboardController(userId));
  }
}
