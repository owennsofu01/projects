import 'dart:async';

import 'package:get/get.dart';

import '../services/service_performance_service.dart';
import 'service_controller.dart';

/// One row of the service performance table.
class ServicePerformanceRow {
  final String serviceId;
  final String name;
  final int jobs;
  final double revenue;
  final double cost;
  final double profit;

  /// False for a service that's been deleted but still has sales.
  final bool isCurrent;

  const ServicePerformanceRow({
    required this.serviceId,
    required this.name,
    required this.jobs,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.isCurrent,
  });

  /// What each job actually sold for on average, after any price changes
  /// at checkout.
  double get averagePrice => jobs == 0 ? 0 : revenue / jobs;
}

/// Joins every service with its sales in the selected month (or all
/// time) for the service performance screen.
class ServicePerformanceController extends GetxController {
  final ServiceController _serviceController = Get.find<ServiceController>();
  final ServicePerformanceService _service = ServicePerformanceService();
  final String userId;

  ServicePerformanceController(this.userId);

  /// First day of the month being viewed, or null for all time.
  final Rxn<DateTime> selectedMonth = Rxn<DateTime>();
  final RxList<ServicePerformanceRow> rows = <ServicePerformanceRow>[].obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<Map<String, ServiceSalesAggregate>>? _salesSub;
  Map<String, ServiceSalesAggregate> _sales = {};
  Worker? _servicesWorker;

  int get totalJobs => rows.fold(0, (sum, r) => sum + r.jobs);
  double get totalRevenue => rows.fold(0, (sum, r) => sum + r.revenue);
  double get totalProfit => rows.fold(0, (sum, r) => sum + r.profit);

  @override
  void onInit() {
    super.onInit();
    _servicesWorker = ever(_serviceController.services, (_) => _recompute());
    _listen();
  }

  @override
  void onClose() {
    _salesSub?.cancel();
    _servicesWorker?.dispose();
    super.onClose();
  }

  /// Switches to [month] (normalized to its first day), or back to all
  /// time when null.
  void selectMonth(DateTime? month) {
    final normalized = month == null ? null : DateTime(month.year, month.month);
    if (normalized == selectedMonth.value) return;
    selectedMonth.value = normalized;
    _listen();
  }

  void _listen() {
    _salesSub?.cancel();
    isLoading.value = true;
    final month = selectedMonth.value;
    _salesSub = _service
        .salesByService(
          userId,
          from: month,
          to: month == null ? null : DateTime(month.year, month.month + 1),
        )
        .listen((data) {
          _sales = data;
          isLoading.value = false;
          _recompute();
        });
  }

  void _recompute() {
    final current = {for (final s in _serviceController.services) s.id: s};
    final ids = {...current.keys, ..._sales.keys};

    rows.value =
        [
          for (final id in ids)
            ServicePerformanceRow(
              serviceId: id,
              name: current[id]?.name ?? _sales[id]!.name,
              jobs: _sales[id]?.jobs ?? 0,
              revenue: _sales[id]?.revenue ?? 0,
              cost: _sales[id]?.cost ?? 0,
              profit: _sales[id]?.profit ?? 0,
              isCurrent: current.containsKey(id),
            ),
        ]..sort((a, b) {
          final byRevenue = b.revenue.compareTo(a.revenue);
          return byRevenue != 0
              ? byRevenue
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
  }
}
