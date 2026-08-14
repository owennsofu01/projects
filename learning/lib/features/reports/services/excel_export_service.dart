import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../expenses/models/expense_model.dart';
import '../../sales/models/sale_model.dart';
import '../models/report_range.dart';

/// Builds a multi-sheet .xlsx workbook for a report and hands it to the
/// platform share sheet, so "export" works the same way on Android and iOS
/// without needing storage permissions — the user picks where it lands
/// (Files, Drive, email, etc.) from the native share dialog.
class ExcelExportService {
  static final _headerStyle = CellStyle(bold: true);

  /// [convert] and [currencySymbol] mirror what's on screen (the user's
  /// selected display currency), so the export matches the app rather than
  /// always dumping raw stored ZMW values.
  Future<void> exportReport({
    required ReportRange range,
    required List<SaleModel> sales,
    required List<ExpenseModel> expenses,
    required double Function(double) convert,
    required String currencySymbol,
  }) async {
    final workbook = Excel.createExcel();

    _writeSummarySheet(
      workbook,
      range: range,
      sales: sales,
      expenses: expenses,
      convert: convert,
      currencySymbol: currencySymbol,
    );
    _writeSalesSheet(workbook, sales, convert, currencySymbol);
    _writeExpensesSheet(workbook, expenses, convert, currencySymbol);

    // Excel.createExcel() seeds a default empty sheet alongside the ones
    // above — drop it so the workbook only shows sheets with real content.
    workbook.delete('Sheet1');

    final bytes = workbook.encode();
    if (bytes == null) {
      throw Exception('Could not generate the Excel file');
    }

    final dir = await getTemporaryDirectory();
    final fileName = _fileName(range);
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'ProfitPulse report — ${range.label}',
      ),
    );
  }

  void _writeSummarySheet(
    Excel workbook, {
    required ReportRange range,
    required List<SaleModel> sales,
    required List<ExpenseModel> expenses,
    required double Function(double) convert,
    required String currencySymbol,
  }) {
    final sheet = workbook['Summary'];

    final totalSales = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final totalProfit = sales.fold<double>(0, (sum, s) => sum + s.profit);
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    sheet.appendRow([TextCellValue('ProfitPulse Report')]);
    sheet.appendRow([
      TextCellValue('Period'),
      TextCellValue(range.label),
    ]);
    sheet.appendRow([
      TextCellValue('From'),
      TextCellValue(_formatDate(range.start)),
    ]);
    sheet.appendRow([
      TextCellValue('To'),
      TextCellValue(_formatDate(range.end.subtract(const Duration(days: 1)))),
    ]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('Metric'),
      TextCellValue('Amount ($currencySymbol)'),
    ]);
    _styleLastRow(sheet, _headerStyle);

    sheet.appendRow([
      TextCellValue('Total Sales'),
      DoubleCellValue(convert(totalSales)),
    ]);
    sheet.appendRow([
      TextCellValue('Total Profit'),
      DoubleCellValue(convert(totalProfit)),
    ]);
    sheet.appendRow([
      TextCellValue('Total Expenses'),
      DoubleCellValue(convert(totalExpenses)),
    ]);
    sheet.appendRow([
      TextCellValue('Net (Profit − Expenses)'),
      DoubleCellValue(convert(totalProfit - totalExpenses)),
    ]);

    sheet.setColumnWidth(0, 28);
    sheet.setColumnWidth(1, 20);
  }

  void _writeSalesSheet(
    Excel workbook,
    List<SaleModel> sales,
    double Function(double) convert,
    String currencySymbol,
  ) {
    final sheet = workbook['Sales'];

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Product'),
      TextCellValue('Quantity'),
      TextCellValue('Unit Price ($currencySymbol)'),
      TextCellValue('Total ($currencySymbol)'),
      TextCellValue('Cost ($currencySymbol)'),
      TextCellValue('Profit ($currencySymbol)'),
    ]);
    _styleLastRow(sheet, _headerStyle);

    for (final sale in sales) {
      sheet.appendRow([
        TextCellValue(_formatDate(sale.date)),
        TextCellValue(sale.productName),
        IntCellValue(sale.quantity),
        DoubleCellValue(convert(sale.sellingPrice)),
        DoubleCellValue(convert(sale.totalAmount)),
        DoubleCellValue(convert(sale.costAmount)),
        DoubleCellValue(convert(sale.profit)),
      ]);
    }

    for (var col = 0; col < 7; col++) {
      sheet.setColumnWidth(col, col == 1 ? 24 : 16);
    }
  }

  void _writeExpensesSheet(
    Excel workbook,
    List<ExpenseModel> expenses,
    double Function(double) convert,
    String currencySymbol,
  ) {
    final sheet = workbook['Expenses'];

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Title'),
      TextCellValue('Category'),
      TextCellValue('Amount ($currencySymbol)'),
    ]);
    _styleLastRow(sheet, _headerStyle);

    for (final expense in expenses) {
      sheet.appendRow([
        TextCellValue(_formatDate(expense.date)),
        TextCellValue(expense.title),
        TextCellValue(expense.category),
        DoubleCellValue(convert(expense.amount)),
      ]);
    }

    for (var col = 0; col < 4; col++) {
      sheet.setColumnWidth(col, col == 1 ? 24 : 18);
    }
  }

  /// Applies [style] to every cell in the row just written by [appendRow],
  /// since that method has no styling parameter of its own.
  void _styleLastRow(Sheet sheet, CellStyle style) {
    final rowIndex = sheet.maxRows - 1;
    final columnCount = sheet.rows.isEmpty ? 0 : sheet.rows.last.length;
    for (var col = 0; col < columnCount; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
      );
      cell.cellStyle = style;
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _fileName(ReportRange range) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final label = range.label.toLowerCase().replaceAll(' ', '_');
    return 'profitpulse_report_${label}_$stamp.xlsx';
  }
}
