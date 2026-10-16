import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/firestore_collections.dart';
import 'spreadsheet_format.dart';

/// Builds the backup workbook (every record in the account) and the
/// import template, and hands either to the share sheet.
///
/// Amounts are the stored values, not converted to the display currency,
/// so a backup imported again gives back exactly the same numbers.
class BackupService {
  BackupService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static final _headerStyle = CellStyle(bold: true);

  /// An .xlsx with one sheet per kind of record. Its Products, Services
  /// and Expenses sheets use the import layout.
  Future<List<int>> buildBackup(String userId) async {
    final userRef = _db.collection(FirestoreCollections.users).doc(userId);
    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> all(
      CollectionReference<Map<String, dynamic>> ref,
    ) async => (await ref.get()).docs;

    final products = await all(
      userRef.collection(FirestoreCollections.products),
    );
    final services = await all(
      userRef.collection(FirestoreCollections.services),
    );
    final customers = await all(
      userRef.collection(FirestoreCollections.customers),
    );
    final sales = await all(userRef.collection(FirestoreCollections.sales));
    final expenses = await all(
      userRef.collection(FirestoreCollections.expenses),
    );
    final budgets = await all(userRef.collection(FirestoreCollections.budgets));

    products.sort((a, b) => _text(a['name']).compareTo(_text(b['name'])));
    services.sort((a, b) => _text(a['name']).compareTo(_text(b['name'])));
    customers.sort((a, b) => _text(a['name']).compareTo(_text(b['name'])));
    sales.sort((a, b) => _date(a['date']).compareTo(_date(b['date'])));
    expenses.sort((a, b) => _date(a['date']).compareTo(_date(b['date'])));

    final workbook = Excel.createExcel();

    final about = _sheet(workbook, 'About', ['ProfitPulse backup', '']);
    about.appendRow([
      TextCellValue('Created'),
      TextCellValue(_dateTimeText(DateTime.now())),
    ]);
    about.appendRow([TextCellValue('Amounts'), TextCellValue('ZMW')]);
    about.appendRow([
      TextCellValue('Re-importing'),
      TextCellValue(
        'Products, Services and Expenses can be imported again from '
        'Settings. '
        'Anything already in the app is skipped.',
      ),
    ]);
    about.setColumnWidth(0, 16);
    about.setColumnWidth(1, 60);

    final productSheet = _sheet(
      workbook,
      SpreadsheetFormat.productsSheet,
      SpreadsheetFormat.productColumns,
    );
    for (final p in products) {
      productSheet.appendRow([
        TextCellValue(_text(p['name'])),
        DoubleCellValue(_number(p['costPrice'])),
        DoubleCellValue(_number(p['sellingPrice'])),
        IntCellValue(_number(p['stock']).toInt()),
        IntCellValue(_number(p.data()['reorderLevel'] ?? 5).toInt()),
        TextCellValue(_text(p.data()['barcode'])),
      ]);
    }

    final serviceSheet = _sheet(
      workbook,
      SpreadsheetFormat.servicesSheet,
      SpreadsheetFormat.serviceColumns,
    );
    for (final s in services) {
      serviceSheet.appendRow([
        TextCellValue(_text(s['name'])),
        DoubleCellValue(_number(s['price'])),
        DoubleCellValue(_number(s.data()['materialsCost'])),
      ]);
    }

    final expenseSheet = _sheet(
      workbook,
      SpreadsheetFormat.expensesSheet,
      SpreadsheetFormat.expenseColumns,
    );
    for (final e in expenses) {
      expenseSheet.appendRow([
        _dateCell(e['date']),
        TextCellValue(_text(e['title'])),
        TextCellValue(_text(e.data()['category'])),
        DoubleCellValue(_number(e['amount'])),
      ]);
    }

    final saleSheet = _sheet(workbook, 'Sales', [
      'Date',
      'Receipt',
      'Type',
      'Item',
      'Quantity',
      'Unit price',
      'Total',
      'Cost',
      'Profit',
      'Customer',
      'On credit (whole receipt)',
    ]);
    for (final s in sales) {
      final data = s.data();
      saleSheet.appendRow([
        TextCellValue(_dateTimeText(_date(s['date']))),
        TextCellValue(_text(data['receiptId'] ?? s.id)),
        TextCellValue(data['kind'] == 'service' ? 'Service' : 'Product'),
        TextCellValue(_text(s['productName'])),
        IntCellValue(_number(s['quantity']).toInt()),
        DoubleCellValue(_number(s['sellingPrice'])),
        DoubleCellValue(_number(s['totalAmount'])),
        DoubleCellValue(_number(s['costAmount'])),
        DoubleCellValue(_number(s['profit'])),
        TextCellValue(_text(data['customerName'])),
        DoubleCellValue(_number(data['receiptCredit'] ?? 0)),
      ]);
    }

    final customerSheet = _sheet(workbook, 'Customers', [
      'Name',
      'Phone',
      'Balance owed',
    ]);
    final ledgerSheet = _sheet(workbook, 'Customer ledger', [
      'Customer',
      'Date',
      'Type',
      'Amount',
      'Note',
    ]);
    for (final c in customers) {
      customerSheet.appendRow([
        TextCellValue(_text(c['name'])),
        TextCellValue(_text(c.data()['phone'])),
        DoubleCellValue(_number(c.data()['balance'] ?? 0)),
      ]);
      final ledger = await all(
        c.reference.collection(FirestoreCollections.ledger),
      );
      ledger.sort((a, b) => _date(a['date']).compareTo(_date(b['date'])));
      for (final entry in ledger) {
        ledgerSheet.appendRow([
          TextCellValue(_text(c['name'])),
          TextCellValue(_dateTimeText(_date(entry['date']))),
          TextCellValue(_text(entry['type'])),
          DoubleCellValue(_number(entry['amount'])),
          TextCellValue(_text(entry.data()['note'])),
        ]);
      }
    }

    final batchSheet = _sheet(workbook, 'Stock purchases', [
      'Product',
      'Purchased',
      'Quantity',
      'Still in stock',
      'Unit cost',
    ]);
    for (final p in products) {
      final batches = await all(
        p.reference.collection(FirestoreCollections.batches),
      );
      batches.sort(
        (a, b) => _date(a['purchasedAt']).compareTo(_date(b['purchasedAt'])),
      );
      for (final batch in batches) {
        batchSheet.appendRow([
          TextCellValue(_text(p['name'])),
          TextCellValue(_dateTimeText(_date(batch['purchasedAt']))),
          IntCellValue(_number(batch['quantity']).toInt()),
          IntCellValue(_number(batch['remainingQuantity']).toInt()),
          DoubleCellValue(_number(batch['costPrice'])),
        ]);
      }
    }

    final budgetSheet = _sheet(workbook, 'Budgets', [
      'Category',
      'Monthly limit',
    ]);
    for (final b in budgets) {
      budgetSheet.appendRow([
        TextCellValue(_text(b['category'])),
        DoubleCellValue(_number(b['monthlyLimit'])),
      ]);
    }

    return _encode(workbook);
  }

  /// An empty workbook with the import layout and one example row each.
  List<int> buildTemplate() {
    final workbook = Excel.createExcel();

    _sheet(
      workbook,
      SpreadsheetFormat.productsSheet,
      SpreadsheetFormat.productColumns,
    ).appendRow([
      TextCellValue('Example: Sugar 2kg'),
      DoubleCellValue(45),
      DoubleCellValue(55),
      IntCellValue(20),
      IntCellValue(5),
      TextCellValue(''),
    ]);
    _sheet(
      workbook,
      SpreadsheetFormat.servicesSheet,
      SpreadsheetFormat.serviceColumns,
    ).appendRow([
      TextCellValue('Example: Box braids'),
      DoubleCellValue(350),
      DoubleCellValue(120),
    ]);
    _sheet(
      workbook,
      SpreadsheetFormat.expensesSheet,
      SpreadsheetFormat.expenseColumns,
    ).appendRow([
      _dateCell(Timestamp.now()),
      TextCellValue('Example: Shop rent'),
      TextCellValue('Rent'),
      DoubleCellValue(1500),
    ]);

    final help = _sheet(workbook, 'How to use', ['Column', 'What to enter']);
    for (final (column, text) in const [
      ('Name', 'Product or service name. Ones already in the app are skipped.'),
      ('Cost price', 'What you pay for one unit.'),
      ('Selling price', 'What you charge for one unit.'),
      ('Stock', 'Units on hand now (optional, default 0).'),
      ('Reorder level', 'Warn when stock falls to this (optional, default 5).'),
      ('Barcode', 'Optional.'),
      ('Price', 'Services sheet: usual price per job.'),
      (
        'Materials cost',
        'Services sheet: materials used per job (optional, default 0).',
      ),
      ('Date', 'Expense date, e.g. 2026-10-15 or 15/10/2026.'),
      ('Category', 'Optional; blank becomes "Other".'),
      ('', 'Delete the example rows before importing.'),
    ]) {
      help.appendRow([TextCellValue(column), TextCellValue(text)]);
    }
    help.setColumnWidth(0, 16);
    help.setColumnWidth(1, 60);

    return _encode(workbook);
  }

  Future<void> share(List<int> bytes, String fileName, String subject) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject),
    );
  }

  /// A new sheet with a bold header row.
  Sheet _sheet(Excel workbook, String name, List<String> headers) {
    final sheet = workbook[name];
    sheet.appendRow([for (final h in headers) TextCellValue(h)]);
    for (var col = 0; col < headers.length; col++) {
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
              .cellStyle =
          _headerStyle;
      sheet.setColumnWidth(col, col == 0 ? 24 : 16);
    }
    return sheet;
  }

  List<int> _encode(Excel workbook) {
    // createExcel() seeds an empty default sheet.
    workbook.delete('Sheet1');
    final bytes = workbook.encode();
    if (bytes == null) throw Exception('Could not create the Excel file');
    return bytes;
  }

  static String _text(Object? value) => (value as String?)?.trim() ?? '';

  static double _number(Object? value) => (value as num? ?? 0).toDouble();

  static DateTime _date(Object? value) =>
      value is Timestamp ? value.toDate() : DateTime(1970);

  static CellValue _dateCell(Object? value) {
    final date = _date(value);
    return DateCellValue(year: date.year, month: date.month, day: date.day);
  }

  static String _dateTimeText(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
