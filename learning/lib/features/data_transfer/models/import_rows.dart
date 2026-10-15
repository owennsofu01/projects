/// A product row read from an import spreadsheet, already validated.
class ImportedProduct {
  final String name;
  final double costPrice;
  final double sellingPrice;
  final int stock;
  final int reorderLevel;
  final String barcode;

  const ImportedProduct({
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.stock,
    required this.reorderLevel,
    required this.barcode,
  });
}

/// An expense row read from an import spreadsheet, already validated.
class ImportedExpense {
  final DateTime date;
  final String title;
  final String category;
  final double amount;

  const ImportedExpense({
    required this.date,
    required this.title,
    required this.category,
    required this.amount,
  });

  /// Identifies the same expense across files, so importing a file twice
  /// (or a backup of data already in the app) doesn't add it again.
  String get matchKey =>
      '${date.year}-${date.month}-${date.day}|${title.toLowerCase()}|'
      '${category.toLowerCase()}|${amount.toStringAsFixed(2)}';
}

/// Everything read from a spreadsheet, before anything is saved.
class ImportPreview {
  final List<ImportedProduct> products;
  final List<ImportedExpense> expenses;

  /// Rows that couldn't be read, e.g. "Products row 4: Selling price is
  /// missing". Those rows are left out; the rest can still be imported.
  final List<String> problems;

  const ImportPreview({
    required this.products,
    required this.expenses,
    required this.problems,
  });

  bool get isEmpty => products.isEmpty && expenses.isEmpty;
}

/// What an import actually saved.
class ImportResult {
  final int productsAdded;
  final int productsSkipped;
  final int expensesAdded;
  final int expensesSkipped;

  const ImportResult({
    required this.productsAdded,
    required this.productsSkipped,
    required this.expensesAdded,
    required this.expensesSkipped,
  });
}
