import 'package:get/get.dart';

import '../services/dashboard_service.dart';

class DashboardController extends GetxController {
  final DashboardService _service = DashboardService();
  final String userId;

  DashboardController(this.userId);

  DateTime get _todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  Stream<SalesSummary> get todaySales =>
      _service.salesSummarySince(userId, _todayStart);

  Stream<SalesSummary> get monthSales =>
      _service.salesSummarySince(userId, _monthStart);

  Stream<double> get todayExpenses =>
      _service.expenseTotalSince(userId, _todayStart);

  Stream<double> get monthExpenses =>
      _service.expenseTotalSince(userId, _monthStart);
}
