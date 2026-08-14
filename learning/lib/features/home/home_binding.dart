import 'package:get/get.dart';

import '../../core/currency/currency_controller.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../auth/controllers/auth_controller.dart';
import '../dashboard/controllers/dashboard_controller.dart';
import '../expenses/controllers/expense_controller.dart';
import '../insights/controllers/insight_controller.dart';
import '../products/controllers/product_controller.dart';
import '../reports/controllers/report_controller.dart';
import '../sales/controllers/sale_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final userId = Get.find<AuthController>().userId;

    Get.lazyPut<CurrencyController>(() => CurrencyController(userId));
    // Eager, not lazy: the theme must apply the moment home loads, not
    // whenever the user happens to first open Settings.
    Get.put(ThemeModeController(userId));
    Get.lazyPut<ProductController>(() => ProductController(userId));
    Get.lazyPut<SaleController>(() => SaleController(userId));
    Get.lazyPut<ExpenseController>(() => ExpenseController(userId));
    Get.lazyPut<DashboardController>(() => DashboardController(userId));
    Get.lazyPut<InsightController>(() => InsightController(userId));
    Get.lazyPut<ReportController>(() => ReportController(userId));
  }
}
