import 'package:get/get.dart';

import '../../ads/ads_manager.dart';
import '../../core/currency/currency_controller.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../auth/controllers/auth_controller.dart';
import '../budgets/controllers/budget_controller.dart';
import '../customers/controllers/customer_controller.dart';
import '../daily_summary/controllers/daily_summary_controller.dart';
import '../dashboard/controllers/dashboard_controller.dart';
import '../data_transfer/controllers/data_transfer_controller.dart';
import '../expenses/controllers/expense_controller.dart';
import '../insights/controllers/insight_controller.dart';
import '../products/controllers/product_controller.dart';
import '../products/controllers/product_profitability_controller.dart';
import '../receipts/controllers/business_profile_controller.dart';
import '../reports/controllers/report_controller.dart';
import '../sales/controllers/sale_controller.dart';
import '../services/controllers/service_controller.dart';
import '../services/controllers/service_performance_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final userId = Get.find<AuthController>().userId;

    // fenix: GetX deletes a lazily created controller when the route that
    // first used it closes (e.g. Settings). fenix lets it be recreated the
    // next time it's needed instead of throwing "not found".

    Get.lazyPut<CurrencyController>(
      () => CurrencyController(userId),
      fenix: true,
    );
    // Eager, not lazy: the theme must apply the moment home loads, not
    // whenever the user happens to first open Settings.
    Get.put(ThemeModeController(userId));
    // Eager so the first interstitial is preloaded before it's needed.
    Get.put(InterstitialAdController());
    Get.lazyPut<ProductController>(
      () => ProductController(userId),
      fenix: true,
    );
    Get.lazyPut<ProductProfitabilityController>(
      () => ProductProfitabilityController(userId),
      fenix: true,
    );
    Get.lazyPut<ServiceController>(
      () => ServiceController(userId),
      fenix: true,
    );
    Get.lazyPut<ServicePerformanceController>(
      () => ServicePerformanceController(userId),
      fenix: true,
    );
    Get.lazyPut<CustomerController>(
      () => CustomerController(userId),
      fenix: true,
    );
    Get.lazyPut<BusinessProfileController>(
      () => BusinessProfileController(userId),
      fenix: true,
    );
    Get.lazyPut<SaleController>(() => SaleController(userId), fenix: true);
    Get.lazyPut<ExpenseController>(
      () => ExpenseController(userId),
      fenix: true,
    );
    Get.lazyPut<BudgetController>(() => BudgetController(userId), fenix: true);
    Get.lazyPut<DataTransferController>(
      () => DataTransferController(userId),
      fenix: true,
    );
    // Eager so the summary notifications are refreshed on every launch.
    Get.put(DailySummaryController(userId));
    Get.lazyPut<DashboardController>(
      () => DashboardController(userId),
      fenix: true,
    );
    Get.lazyPut<InsightController>(
      () => InsightController(userId),
      fenix: true,
    );
    Get.lazyPut<ReportController>(() => ReportController(userId), fenix: true);
  }
}
