import 'package:get/get.dart';

import '../../../core/currency/currency_controller.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../expenses/models/expense_model.dart';
import '../../sales/models/sale_model.dart';
import '../models/report_range.dart';
import '../services/excel_export_service.dart';
import '../services/report_service.dart';

class ReportController extends GetxController {
  final ReportService _reportService = ReportService();
  final ExcelExportService _exportService = ExcelExportService();
  final String userId;

  ReportController(this.userId);

  final Rx<ReportRange> range = ReportRange.thisMonth().obs;
  final RxBool isLoading = false.obs;
  final RxBool isExporting = false.obs;
  final RxList<SaleModel> sales = <SaleModel>[].obs;
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;

  double get totalSales => sales.fold(0, (sum, s) => sum + s.totalAmount);
  double get totalProfit => sales.fold(0, (sum, s) => sum + s.profit);
  double get totalExpenses => expenses.fold(0, (sum, e) => sum + e.amount);
  double get netProfit => totalProfit - totalExpenses;

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
        _reportService.getSales(
          userId,
          from: current.start,
          to: current.end,
        ),
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
