import 'package:get/get.dart';

import '../../../core/currency/currency_controller.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../expenses/models/expense_model.dart';
import '../../sales/models/sale_model.dart';
import '../models/report_range.dart';
import '../services/excel_export_service.dart';
import '../services/report_service.dart';

class ReportController extends GetxController {
  final ReportService _reportService;
  final ExcelExportService _exportService = ExcelExportService();
  final String userId;

  ReportController(this.userId, {ReportService? reportService})
    : _reportService = reportService ?? ReportService();

  final Rx<ReportRange> range = ReportRange.thisMonth().obs;
  final RxBool isLoading = false.obs;
  final RxBool isExporting = false.obs;
  final RxList<SaleModel> sales = <SaleModel>[].obs;
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;

  double get totalSales => sales.fold(0, (sum, s) => sum + s.totalAmount);
  double get totalProfit => sales.fold(0, (sum, s) => sum + s.profit);
  double get totalExpenses => expenses.fold(0, (sum, e) => sum + e.amount);
  double get netProfit => totalProfit - totalExpenses;

  /// What the goods and services sold cost (revenue minus gross profit).
  double get costOfSales => totalSales - totalProfit;

  /// Gross and net profit as a percentage of revenue; null with no sales.
  double? get grossMargin =>
      totalSales == 0 ? null : totalProfit / totalSales * 100;
  double? get netMargin =>
      totalSales == 0 ? null : netProfit / totalSales * 100;

  /// Checkouts in the period. Lines from one checkout share a receipt id;
  /// older sales without one count as their own receipt.
  int get transactionCount =>
      {for (final s in sales) s.receiptId.isEmpty ? s.id : s.receiptId}.length;

  double get averageSale =>
      transactionCount == 0 ? 0 : totalSales / transactionCount;

  /// Expense totals per category, largest first. Blank categories are
  /// grouped as "Other"; names are matched ignoring case and spacing.
  List<MapEntry<String, double>> get expensesByCategory {
    final totals = <String, double>{};
    final names = <String, String>{};
    for (final e in expenses) {
      final name = e.category.trim().isEmpty ? 'Other' : e.category.trim();
      final key = name.toLowerCase();
      names.putIfAbsent(key, () => name);
      totals[key] = (totals[key] ?? 0) + e.amount;
    }
    return [for (final e in totals.entries) MapEntry(names[e.key]!, e.value)]
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Revenue and profit per item sold, by revenue, largest first.
  List<ItemPerformance> get topItems {
    final byName = <String, ItemPerformance>{};
    for (final s in sales) {
      final current =
          byName[s.productName] ??
          ItemPerformance(name: s.productName, isService: s.isService);
      byName[s.productName] = current.add(s);
    }
    return byName.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
  }

  @override
  void onInit() {
    super.onInit();
    loadReport();
  }

  Future<void> setRange(ReportRange newRange) async {
    range.value = newRange;
    await loadReport();
  }

  Future<void> loadReport() async {
    try {
      isLoading.value = true;
      final current = range.value;
      final results = await Future.wait([
        _reportService.getSales(userId, from: current.start, to: current.end),
        _reportService.getExpenses(
          userId,
          from: current.start,
          to: current.end,
        ),
      ]);
      sales.assignAll(results[0] as List<SaleModel>);
      expenses.assignAll(results[1] as List<ExpenseModel>);
    } catch (e) {
      showErrorSnackbar('Could not load the report. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportToExcel() async {
    if (sales.isEmpty && expenses.isEmpty) {
      showErrorSnackbar('Nothing to export for this period.');
      return;
    }

    try {
      isExporting.value = true;
      final currencyController = Get.find<CurrencyController>();
      await _exportService.exportReport(
        range: range.value,
        sales: sales,
        expenses: expenses,
        convert: currencyController.convert,
        currencySymbol: currencyController.currency.value.symbol,
      );
    } catch (e) {
      showErrorSnackbar('Could not export the report. Please try again.');
    } finally {
      isExporting.value = false;
    }
  }
}

class ItemPerformance {
  const ItemPerformance({
    required this.name,
    required this.isService,
    this.quantity = 0,
    this.revenue = 0,
    this.profit = 0,
  });

  final String name;
  final bool isService;
  final int quantity;
  final double revenue;
  final double profit;

  ItemPerformance add(SaleModel sale) => ItemPerformance(
    name: name,
    isService: isService,
    quantity: quantity + sale.quantity,
    revenue: revenue + sale.totalAmount,
    profit: profit + sale.profit,
  );
}
