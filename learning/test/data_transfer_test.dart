import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profitpulse/core/constants/firestore_collections.dart';
import 'package:profitpulse/features/data_transfer/models/import_rows.dart';
import 'package:profitpulse/features/data_transfer/services/backup_service.dart';
import 'package:profitpulse/features/data_transfer/services/import_service.dart';
import 'package:profitpulse/features/data_transfer/services/spreadsheet_format.dart';

import 'support/fake_shop.dart';

/// An .xlsx with the given sheets, each a header row then data rows.
List<int> workbook(Map<String, List<List<CellValue?>>> sheets) {
  final excel = Excel.createExcel();
  for (final entry in sheets.entries) {
    final sheet = excel[entry.key];
    for (final row in entry.value) {
      sheet.appendRow(row);
    }
  }
  excel.delete('Sheet1');
  return excel.encode()!;
}

List<CellValue> texts(List<String> values) => [
  for (final v in values) TextCellValue(v),
];

void main() {
  group('parsing', () {
    test('reads products, with defaults for optional columns', () {
      final preview = SpreadsheetFormat.parse(
        workbook({
          'Products': [
            texts(['Name', 'Cost price', 'Selling price', 'Stock']),
            [
              TextCellValue('Sugar'),
              DoubleCellValue(45),
              IntCellValue(55),
              IntCellValue(20),
            ],
            [
              TextCellValue('Salt'),
              TextCellValue('1,200.50'),
              TextCellValue('1500'),
              null,
            ],
          ],
        }),
      );

      expect(preview.problems, isEmpty);
      expect(preview.expenses, isEmpty);
      final [sugar, salt] = preview.products;
      expect(sugar.costPrice, 45);
      expect(sugar.sellingPrice, 55);
      expect(sugar.stock, 20);
      expect(sugar.reorderLevel, 5);
      expect(salt.costPrice, 1200.5);
      expect(salt.stock, 0);
    });

    test('matches sheet and column names ignoring case and order', () {
      final preview = SpreadsheetFormat.parse(
        workbook({
          'products': [
            texts(['SELLING PRICE', 'name', 'Cost Price', 'barcode']),
            [
              IntCellValue(10),
              TextCellValue('Pen'),
              IntCellValue(6),
              DoubleCellValue(6001234567890),
            ],
          ],
        }),
      );

      final pen = preview.products.single;
      expect(pen.name, 'Pen');
      expect(pen.sellingPrice, 10);
      expect(pen.barcode, '6001234567890');
    });

    test('leaves out invalid rows and says why', () {
      final preview = SpreadsheetFormat.parse(
        workbook({
          'Products': [
            texts(['Name', 'Cost price', 'Selling price', 'Stock']),
            texts(['', '1', '2', '1']),
            texts(['Bad price', '1', '0', '1']),
            texts(['Half', '1', '2', '1.5']),
            texts(['Good', '1', '2', '3']),
            texts(['good', '1', '2', '3']),
            texts(['', '', '', '']),
          ],
        }),
      );

      expect(preview.products.map((p) => p.name), ['Half', 'Good']);
      // "Half" keeps going with the default stock of 0, since 1.5 isn't
      // a whole number.
      expect(preview.products.first.stock, 0);
      expect(preview.problems, [
        'Products row 2: Name is missing',
        'Products row 3: Selling price must be more than 0',
        'Products row 6: "good" appears more than once',
      ]);
    });

    test('a sheet missing a required column is skipped', () {
      final preview = SpreadsheetFormat.parse(
        workbook({
          'Products': [
            texts(['Name', 'Selling price']),
            texts(['Pen', '10']),
          ],
          'Expenses': [
            texts(['Date', 'Title', 'Amount']),
            texts(['2026-10-01', 'Rent', '100']),
          ],
        }),
      );

      expect(preview.products, isEmpty);
      expect(preview.expenses, hasLength(1));
      expect(preview.problems, [
        'Products sheet: no "Cost price" column, so it was skipped',
      ]);
    });

    test('reads expense dates in every supported form', () {
      final preview = SpreadsheetFormat.parse(
        workbook({
          'Expenses': [
            texts(['Date', 'Title', 'Category', 'Amount']),
            [
              const DateCellValue(year: 2026, month: 10, day: 1),
              TextCellValue('A'),
              TextCellValue('Rent'),
              IntCellValue(1),
            ],
            [
              ...texts(['2026-10-02', 'B', '']),
              IntCellValue(2),
            ],
            [
              ...texts(['3/10/2026', 'C', 'Fuel']),
              IntCellValue(3),
            ],
            [
              IntCellValue(46299),
              ...texts(['D', 'Fuel']),
              IntCellValue(4),
            ],
            [
              ...texts(['31/02/2026', 'E', 'Fuel']),
              IntCellValue(5),
            ],
          ],
        }),
      );

      expect(preview.expenses.map((e) => e.date), [
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 3),
        DateTime(2026, 10, 4),
      ]);
      expect(preview.expenses[1].category, 'Other');
      expect(preview.problems.single, startsWith('Expenses row 6: Date'));
    });

    test('a file with neither sheet is rejected', () {
      expect(
        () => SpreadsheetFormat.parse(
          workbook({
            'Stuff': [
              texts(['A']),
            ],
          }),
        ),
        throwsFormatException,
      );
    });

    test('a file that is not a workbook is rejected', () {
      expect(
        () => SpreadsheetFormat.parse([1, 2, 3, 4]),
        throwsFormatException,
      );
    });
  });

  group('importing', () {
    late FakeShop shop;
    late ImportService service;

    setUp(() {
      shop = FakeShop();
      service = ImportService(db: shop.db);
    });

    Future<ImportResult> run(ImportPreview preview) async {
      final (:result, :write) = await service.import(userId, preview);
      await write;
      return result;
    }

    test('adds products with an opening stock batch', () async {
      final result = await run(
        const ImportPreview(
          products: [
            ImportedProduct(
              name: 'Sugar',
              costPrice: 45,
              sellingPrice: 55,
              stock: 20,
              reorderLevel: 3,
              barcode: '123',
            ),
            ImportedProduct(
              name: 'Salt',
              costPrice: 5,
              sellingPrice: 8,
              stock: 0,
              reorderLevel: 5,
              barcode: '',
            ),
          ],
          expenses: [],
          problems: [],
        ),
      );

      expect(result.productsAdded, 2);
      final products =
          (await shop.userRef.collection(FirestoreCollections.products).get())
              .docs;
      final sugar = products.singleWhere((p) => p['name'] == 'Sugar');
      expect(sugar['stock'], 20);
      expect(sugar['reorderLevel'], 3);
      expect(await shop.batchRemaining(sugar.id), [20]);
      final salt = products.singleWhere((p) => p['name'] == 'Salt');
      expect(await shop.batchRemaining(salt.id), isEmpty);
    });

    test('skips products whose name already exists', () async {
      await shop.addProduct(
        'p1',
        sellingPrice: 10,
        costPrice: 5,
        batches: [(4, 5)],
      );

      final result = await run(
        const ImportPreview(
          products: [
            ImportedProduct(
              name: 'PRODUCT P1',
              costPrice: 1,
              sellingPrice: 2,
              stock: 100,
              reorderLevel: 5,
              barcode: '',
            ),
          ],
          expenses: [],
          problems: [],
        ),
      );

      expect(result.productsAdded, 0);
      expect(result.productsSkipped, 1);
      expect(await shop.stockOf('p1'), 4);
    });

    test(
      'skips expenses already recorded, including repeats in the file',
      () async {
        await shop.expensesRef.add({
          'title': 'Rent',
          'amount': 100,
          'category': 'Rent',
          'date': Timestamp.fromDate(DateTime(2026, 10, 1, 14, 30)),
        });
        final rent = ImportedExpense(
          date: DateTime(2026, 10, 1),
          title: 'rent',
          category: 'RENT',
          amount: 100,
        );
        final fuel = ImportedExpense(
          date: DateTime(2026, 10, 2),
          title: 'Fuel',
          category: 'Transport',
          amount: 40,
        );

        final result = await run(
          ImportPreview(
            products: const [],
            expenses: [rent, fuel, fuel],
            problems: const [],
          ),
        );

        expect(result.expensesAdded, 1);
        expect(result.expensesSkipped, 2);
        expect((await shop.expensesRef.get()).docs, hasLength(2));
      },
    );

    test('splits large imports across several batches', () async {
      final expenses = [
        for (var i = 0; i < 950; i++)
          ImportedExpense(
            date: DateTime(2026, 10, 1),
            title: 'Item $i',
            category: 'Stock',
            amount: 1,
          ),
      ];

      final result = await run(
        ImportPreview(
          products: const [],
          expenses: expenses,
          problems: const [],
        ),
      );

      expect(result.expensesAdded, 950);
      expect((await shop.expensesRef.get()).docs, hasLength(950));
    });
  });

  group('backup', () {
    test('a backup reads back as the same products and expenses', () async {
      final shop = FakeShop();
      await shop.addProduct(
        'p1',
        sellingPrice: 12.5,
        costPrice: 8,
        batches: [(3, 8)],
      );
      await shop.addExpense(amount: 75.25, date: DateTime(2026, 9, 3, 10));
      await shop.addSale(
        productId: 'p1',
        quantity: 1,
        totalAmount: 12.5,
        profit: 4.5,
        date: DateTime(2026, 9, 4),
      );
      await shop.addCustomer('c1', balance: 20);

      final bytes = await BackupService(db: shop.db).buildBackup(userId);
      final preview = SpreadsheetFormat.parse(bytes);

      expect(preview.problems, isEmpty);
      final product = preview.products.single;
      expect(product.name, 'Product p1');
      expect(product.costPrice, 8);
      expect(product.sellingPrice, 12.5);
      expect(product.stock, 3);
      final expense = preview.expenses.single;
      expect(expense.date, DateTime(2026, 9, 3));
      expect(expense.amount, 75.25);
      expect(expense.category, 'Rent');

      final sheets = Excel.decodeBytes(bytes).tables.keys;
      expect(
        sheets,
        containsAll([
          'About',
          'Sales',
          'Customers',
          'Customer ledger',
          'Stock purchases',
          'Budgets',
        ]),
      );

      // Importing it straight back adds nothing.
      final (:result, write: _) = await ImportService(
        db: shop.db,
      ).import(userId, preview);
      expect(result.productsAdded, 0);
      expect(result.expensesAdded, 0);
    });

    test('the template parses, with its example rows', () {
      final preview = SpreadsheetFormat.parse(
        BackupService(db: FakeShop().db).buildTemplate(),
      );

      expect(preview.problems, isEmpty);
      expect(preview.products.single.name, startsWith('Example'));
      expect(preview.expenses.single.title, startsWith('Example'));
    });
  });
}
