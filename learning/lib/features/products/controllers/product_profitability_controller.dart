import 'dart:async';

import 'package:get/get.dart';

import '../../insights/services/insight_service.dart';
import '../models/product_profit_row.dart';
import 'product_controller.dart';

/// Which rows the profitability table shows, based on profit in the
/// selected period.
enum ProfitFilter { all, profitable, loss, notSold }

/// Joins every product with its all-time sales to drive the product
/// profitability table — separate from [InsightController], which only
/// looks at a trailing lookback window for restock/reduce recommendations.
///
/// [rows] and its totals are always all-time (the dashboard card reads
/// them). The profitability screen reads [visibleRows] instead, which
/// applies the selected month, search and [ProfitFilter].
class ProductProfitabilityController extends GetxController {
  final ProductController _productController = Get.find<ProductController>();
  final InsightService _service = InsightService();
  final String userId;

  ProductProfitabilityController(this.userId);

  final RxList<ProductProfitRow> rows = <ProductProfitRow>[].obs;
  final RxBool isLoading = true.obs;

  /// First day of the month being viewed, or null for all time.
  final Rxn<DateTime> selectedMonth = Rxn<DateTime>();
  final RxString searchQuery = ''.obs;
  final Rx<ProfitFilter> profitFilter = ProfitFilter.all.obs;
  final RxList<ProductProfitRow> visibleRows = <ProductProfitRow>[].obs;
  final RxBool isPeriodLoading = false.obs;

  StreamSubscription<Map<String, ProductSalesAggregate>>? _salesSub;
  StreamSubscription<Map<String, ProductSalesAggregate>>? _periodSub;
  Map<String, ProductSalesAggregate> _salesByProduct = {};
  Map<String, ProductSalesAggregate>? _periodSalesByProduct;
  Worker? _productsWorker;
  Worker? _filtersWorker;

  double get totalProfit => rows.fold(0, (sum, r) => sum + r.profit);
  double get totalCost => rows.fold(0, (sum, r) => sum + r.totalCost);
  double get totalExpectedProfit =>
      rows.fold(0, (sum, r) => sum + r.expectedProfit);

  double get visibleProfit => visibleRows.fold(0, (sum, r) => sum + r.profit);
  int get visibleUnitsSold =>
      visibleRows.fold(0, (sum, r) => sum + r.unitsSold);
  double get visibleCost => visibleRows.fold(0, (sum, r) => sum + r.totalCost);
  double get visibleExpectedProfit =>
      visibleRows.fold(0, (sum, r) => sum + r.expectedProfit);

  bool get hasActiveFilters =>
      searchQuery.value.trim().isNotEmpty ||
      profitFilter.value != ProfitFilter.all;

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool get canGoToNextMonth {
    final month = selectedMonth.value;
    return month != null && month.isBefore(_currentMonth);
  }

  @override
  void onInit() {
    super.onInit();
    _salesSub = _service.salesByProductAllTime(userId).listen((data) {
      _salesByProduct = data;
      _recompute();
    });
    _productsWorker = ever(_productController.products, (_) => _recompute());
    _filtersWorker = everAll([
      searchQuery,
      profitFilter,
    ], (_) => _applyFilters());
    _recompute();
  }

  @override
  void onClose() {
    _salesSub?.cancel();
    _periodSub?.cancel();
    _productsWorker?.dispose();
    _filtersWorker?.dispose();
    super.onClose();
  }

  /// Switches the table to [month] (normalized to its first day), or back
  /// to all time when null.
  void selectMonth(DateTime? month) {
    final normalized = month == null ? null : DateTime(month.year, month.month);
    if (normalized == selectedMonth.value) return;
    selectedMonth.value = normalized;

    _periodSub?.cancel();
    _periodSub = null;
    _periodSalesByProduct = null;

    if (normalized == null) {
      isPeriodLoading.value = false;
      _applyFilters();
      return;
    }

    isPeriodLoading.value = true;
    _periodSub = _service
        .salesByProductBetween(
          userId,
          from: normalized,
          to: DateTime(normalized.year, normalized.month + 1),
        )
        .listen((data) {
          _periodSalesByProduct = data;
          isPeriodLoading.value = false;
          _applyFilters();
        });
  }

  void previousMonth() {
    final month = selectedMonth.value ?? _currentMonth;
    selectMonth(DateTime(month.year, month.month - 1));
  }

  void nextMonth() {
    final month = selectedMonth.value;
    if (month == null || !canGoToNextMonth) return;
    selectMonth(DateTime(month.year, month.month + 1));
  }

  void clearFilters() {
    searchQuery.value = '';
    profitFilter.value = ProfitFilter.all;
  }

  List<ProductProfitRow> _buildRows(
    Map<String, ProductSalesAggregate> salesByProduct,
  ) {
    return [
      for (final product in _productController.products)
        ProductProfitRow(
          productId: product.id,
          productName: product.name,
          stock: product.stock,
          costPrice: product.costPrice,
          sellingPrice: product.sellingPrice,
          unitsSold: salesByProduct[product.id]?.quantity ?? 0,
          profit: salesByProduct[product.id]?.profit ?? 0,
        ),
    ]..sort((a, b) => b.profit.compareTo(a.profit));
  }

  void _recompute() {
    rows.value = _buildRows(_salesByProduct);
    isLoading.value = false;
    _applyFilters();
  }

  void _applyFilters() {
    final source = selectedMonth.value == null
        ? rows
        : _buildRows(_periodSalesByProduct ?? const {});
    final query = searchQuery.value.trim().toLowerCase();

    visibleRows.value = source.where((row) {
      if (query.isNotEmpty && !row.productName.toLowerCase().contains(query)) {
        return false;
      }
      return switch (profitFilter.value) {
        ProfitFilter.all => true,
        ProfitFilter.profitable => row.profit > 0,
        ProfitFilter.loss => row.profit < 0,
        ProfitFilter.notSold => row.unitsSold == 0,
      };
    }).toList();
  }
}
