import 'package:excel/excel.dart';

import '../../products/models/product_model.dart';
import '../models/import_rows.dart';

/// The Products and Expenses sheet layout shared by the import template,
/// imports and backups, so a backup can be imported again as-is.
class SpreadsheetFormat {
  SpreadsheetFormat._();

  static const productsSheet = 'Products';
  static const expensesSheet = 'Expenses';

  static const productColumns = [
    'Name',
    'Cost price',
    'Selling price',
    'Stock',
    'Reorder level',
    'Barcode',
  ];

  static const expenseColumns = ['Date', 'Title', 'Category', 'Amount'];

  /// Reads the Products and Expenses sheets of an .xlsx file. Sheet and
  /// column names are matched ignoring case, and columns may be in any
  /// order. Invalid rows are skipped and described in
  /// [ImportPreview.problems].
  static ImportPreview parse(List<int> bytes) {
    final Excel workbook;
    try {
      workbook = Excel.decodeBytes(bytes);
    } catch (_) {
      throw const FormatException(
        "This file couldn't be read. Save it as an Excel workbook (.xlsx) "
        'and try again.',
      );
    }

    final problems = <String>[];
    final products = _sheet(workbook, productsSheet);
    final expenses = _sheet(workbook, expensesSheet);
    if (products == null && expenses == null) {
      throw const FormatException(
        'No "Products" or "Expenses" sheet found. Use the template to see '
        'the layout.',
      );
    }

    return ImportPreview(
      products: products == null
          ? const []
          : _parseProducts(products, problems),
      expenses: expenses == null
          ? const []
          : _parseExpenses(expenses, problems),
      problems: problems,
    );
  }

  static Sheet? _sheet(Excel workbook, String name) {
    for (final entry in workbook.tables.entries) {
      if (entry.key.trim().toLowerCase() == name.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

  static List<ImportedProduct> _parseProducts(
    Sheet sheet,
    List<String> problems,
  ) {
    final rows = _Rows(sheet, productsSheet, problems);
    final name = rows.column('Name', required: true);
    final cost = rows.column('Cost price', required: true);
    final selling = rows.column('Selling price', required: true);
    final stock = rows.column('Stock');
    final reorder = rows.column('Reorder level');
    final barcode = rows.column('Barcode');
    if (!rows.hasRequiredColumns) return const [];

    final products = <ImportedProduct>[];
    final seenNames = <String>{};
    rows.forEachRow((row, problem) {
      final productName = row.text(name);
      if (productName.isEmpty) return problem('Name is missing');
      if (!seenNames.add(productName.toLowerCase())) {
        return problem('"$productName" appears more than once');
      }

      final costPrice = row.number(cost);
      if (costPrice == null || costPrice < 0) {
        return problem('Cost price must be 0 or more');
      }
      final sellingPrice = row.number(selling);
      if (sellingPrice == null || sellingPrice <= 0) {
        return problem('Selling price must be more than 0');
      }
      final stockCount = row.wholeNumber(stock) ?? 0;
      if (stockCount < 0) return problem('Stock cannot be negative');
      final reorderLevel =
          row.wholeNumber(reorder) ?? ProductModel.lowStockThreshold;
      if (reorderLevel < 0) {
        return problem('Reorder level cannot be negative');
      }

      products.add(
        ImportedProduct(
          name: productName,
          costPrice: costPrice,
          sellingPrice: sellingPrice,
          stock: stockCount,
          reorderLevel: reorderLevel,
          barcode: row.code(barcode),
        ),
      );
    });
    return products;
  }

  static List<ImportedExpense> _parseExpenses(
    Sheet sheet,
    List<String> problems,
  ) {
    final rows = _Rows(sheet, expensesSheet, problems);
    final date = rows.column('Date', required: true);
    final title = rows.column('Title', required: true);
    final category = rows.column('Category');
    final amount = rows.column('Amount', required: true);
    if (!rows.hasRequiredColumns) return const [];

    final expenses = <ImportedExpense>[];
    rows.forEachRow((row, problem) {
      final expenseDate = row.date(date);
      if (expenseDate == null) {
        return problem('Date is missing or not a date (use YYYY-MM-DD)');
      }
      final expenseTitle = row.text(title);
      if (expenseTitle.isEmpty) return problem('Title is missing');
      final expenseAmount = row.number(amount);
      if (expenseAmount == null || expenseAmount <= 0) {
        return problem('Amount must be more than 0');
      }
      final expenseCategory = row.text(category);

      expenses.add(
        ImportedExpense(
          date: expenseDate,
          title: expenseTitle,
          category: expenseCategory.isEmpty ? 'Other' : expenseCategory,
          amount: expenseAmount,
        ),
      );
    });
    return expenses;
  }
}

/// A sheet's rows, with its header row mapped to column positions.
class _Rows {
  _Rows(this.sheet, this.sheetName, this.problems) {
    final rows = sheet.rows;
    final header = rows.isEmpty ? const <Data?>[] : rows.first;
    for (var i = 0; i < header.length; i++) {
      final title = _Row.textOf(header[i]?.value).toLowerCase();
      if (title.isNotEmpty) _indexByHeader.putIfAbsent(title, () => i);
    }
  }

  final Sheet sheet;
  final String sheetName;
  final List<String> problems;
  final _indexByHeader = <String, int>{};
  bool hasRequiredColumns = true;

  /// The column headed [title], or null if the sheet has none.
  int? column(String title, {bool required = false}) {
    final index = _indexByHeader[title.toLowerCase()];
    if (index == null && required) {
      hasRequiredColumns = false;
      problems.add('$sheetName sheet: no "$title" column, so it was skipped');
    }
    return index;
  }

  /// Calls [read] for every non-blank row after the header. [read] reports
  /// an invalid row by calling its second argument with the reason.
  void forEachRow(
    void Function(_Row row, void Function(String reason) problem) read,
  ) {
    final rows = sheet.rows;
    for (var i = 1; i < rows.length; i++) {
      final row = _Row(rows[i]);
      if (row.isBlank) continue;
      read(row, (reason) => problems.add('$sheetName row ${i + 1}: $reason'));
    }
  }
}

class _Row {
  const _Row(this.cells);

  final List<Data?> cells;

  bool get isBlank => cells.every((c) => textOf(c?.value).isEmpty);

  CellValue? _value(int? column) {
    if (column == null || column >= cells.length) return null;
    return cells[column]?.value;
  }

  String text(int? column) => textOf(_value(column));

  static String textOf(CellValue? value) => switch (value) {
    null => '',
    TextCellValue(:final value) => value.toString().trim(),
    IntCellValue(:final value) => '$value',
    DoubleCellValue(:final value) => _trimNumber(value),
    _ => value.toString().trim(),
  };

  double? number(int? column) {
    return switch (_value(column)) {
      IntCellValue(:final value) => value.toDouble(),
      DoubleCellValue(:final value) => value,
      final other => double.tryParse(
        textOf(other).replaceAll(',', '').replaceAll(' ', ''),
      ),
    };
  }

  /// A whole number, or null when blank or not whole.
  int? wholeNumber(int? column) {
    final value = number(column);
    if (value == null || value != value.roundToDouble()) return null;
    return value.toInt();
  }

  /// Text for codes like barcodes, which Excel often stores as numbers
  /// (so 6001234567890 must not come back as "6.00123456789e12").
  String code(int? column) => switch (_value(column)) {
    DoubleCellValue(:final value) when value == value.roundToDouble() =>
      value.toStringAsFixed(0),
    final other => textOf(other),
  };

  DateTime? date(int? column) {
    return switch (_value(column)) {
      DateCellValue(:final year, :final month, :final day) => DateTime(
        year,
        month,
        day,
      ),
      DateTimeCellValue(
        :final year,
        :final month,
        :final day,
        :final hour,
        :final minute,
      ) =>
        DateTime(year, month, day, hour, minute),
      // A date cell Excel saved as its serial day number.
      IntCellValue(:final value) => _fromSerial(value.toDouble()),
      DoubleCellValue(:final value) => _fromSerial(value),
      final other => parseDate(textOf(other)),
    };
  }

  static DateTime? _fromSerial(double serial) {
    if (serial < 1 || serial > 2958465) return null;
    final base = DateTime(1899, 12, 30);
    return DateTime(base.year, base.month, base.day + serial.floor());
  }

  /// YYYY-MM-DD, or day-first D/M/YYYY (also with "-" or ".").
  static DateTime? parseDate(String text) {
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(text);
    final dayFirst = RegExp(
      r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})$',
    ).firstMatch(text);

    final (int, int, int)? parts = iso != null
        ? (int.parse(iso[1]!), int.parse(iso[2]!), int.parse(iso[3]!))
        : dayFirst != null
        ? (
            int.parse(dayFirst[3]!),
            int.parse(dayFirst[2]!),
            int.parse(dayFirst[1]!),
          )
        : null;
    if (parts == null) return null;

    final (year, month, day) = parts;
    final date = DateTime(year, month, day);
    // Reject impossible dates like 31/02, which DateTime would roll over.
    if (date.month != month || date.day != day) return null;
    return date;
  }

  static String _trimNumber(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}
