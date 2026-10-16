import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profitpulse/core/constants/firestore_collections.dart';
import 'package:profitpulse/features/data_transfer/models/import_rows.dart';
import 'package:profitpulse/features/data_transfer/services/import_service.dart';
import 'package:profitpulse/features/data_transfer/services/spreadsheet_format.dart';
import 'package:profitpulse/features/insights/services/insight_service.dart';
import 'package:profitpulse/features/sales/models/cart_item.dart';
import 'package:profitpulse/features/sales/models/sale_model.dart';
import 'package:profitpulse/features/sales/services/sale_service.dart';
import 'package:profitpulse/features/services/models/service_model.dart';
import 'package:profitpulse/features/services/services/service_performance_service.dart';

import 'support/fake_shop.dart';

ServiceModel braids({double price = 350, double materialsCost = 120}) {
  final now = DateTime(2026, 1, 1);
  return ServiceModel(
    id: 's1',
    name: 'Box braids',
    price: price,
    materialsCost: materialsCost,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeShop shop;
  late SaleService sales;

  setUp(() {
    shop = FakeShop();
    sales = SaleService(db: shop.db);
  });

  group('checkout', () {
    test('records a service sale at its price, costed by materials', () async {
      await sales.checkout(
        userId: userId,
        items: [CartItem.service(service: braids(), quantity: 2)],
        online: true,
      );

      final sale = (await shop.salesRef.get()).docs.single;
      expect(sale['kind'], 'service');
      expect(sale['serviceId'], 's1');
      expect(sale.data().containsKey('productId'), isFalse);
      expect(sale['productName'], 'Box braids');
      expect(sale['sellingPrice'], 350);
      expect(sale['totalAmount'], 700);
      expect(sale['costAmount'], 240);
      expect(sale['profit'], 460);
    });

    test('uses a price changed at checkout', () async {
      await sales.checkout(
        userId: userId,
        items: [
          CartItem.service(service: braids(), quantity: 1, unitPrice: 500),
        ],
        online: true,
      );

      final sale = (await shop.salesRef.get()).docs.single;
      expect(sale['sellingPrice'], 500);
      expect(sale['totalAmount'], 500);
      expect(sale['profit'], 380);
    });

    test('sells a product and a service on one receipt', () async {
      final product = await shop.addProduct(
        'p1',
        sellingPrice: 50,
        costPrice: 30,
        batches: [(5, 30)],
      );

      final receiptId = await sales.checkout(
        userId: userId,
        items: [
          CartItem(product: product, quantity: 2),
          CartItem.service(service: braids(), quantity: 1),
        ],
        online: true,
      );

      final docs = (await shop.salesRef.get()).docs;
      expect(docs, hasLength(2));
      expect(docs.every((d) => d['receiptId'] == receiptId), isTrue);
      expect(await shop.stockOf('p1'), 3);
      expect(await shop.batchRemaining('p1'), [3]);
    });

    test('works offline', () async {
      await sales.checkout(
        userId: userId,
        items: [CartItem.service(service: braids(), quantity: 1)],
        online: false,
      );

      expect((await shop.salesRef.get()).docs, hasLength(1));
    });

    test('puts a service on credit', () async {
      final customer = await shop.addCustomer('c1');

      await sales.checkout(
        userId: userId,
        items: [CartItem.service(service: braids(), quantity: 1)],
        online: true,
        customer: customer,
        creditAmount: 150,
      );

      expect(await shop.balanceOf('c1'), 150);
      final ledger = await shop
          .customerRef('c1')
          .collection(FirestoreCollections.ledger)
          .get();
      expect(ledger.docs.single['note'], '1 × Box braids');
    });
  });

  group('reading sales', () {
    test('old sales without a kind are products', () async {
      await shop.addSale(
        productId: 'p1',
        quantity: 1,
        totalAmount: 10,
        profit: 4,
        date: DateTime(2026, 3, 1),
      );

      final sale = SaleModel.fromFirestore(
        (await shop.salesRef.get()).docs.single,
      );
      expect(sale.kind, SaleKind.product);
      expect(sale.productId, 'p1');
      expect(sale.serviceId, isNull);
    });

    test('service sales read back as services', () async {
      await sales.checkout(
        userId: userId,
        items: [CartItem.service(service: braids(), quantity: 1)],
        online: true,
      );

      final sale = SaleModel.fromFirestore(
        (await shop.salesRef.get()).docs.single,
      );
      expect(sale.isService, isTrue);
      expect(sale.serviceId, 's1');
      expect(sale.productId, '');
    });

    test('product profitability ignores service sales', () async {
      await shop.addSale(
        productId: 'p1',
        quantity: 1,
        totalAmount: 10,
        profit: 4,
        date: DateTime(2026, 3, 1),
      );
      await sales.checkout(
        userId: userId,
        items: [CartItem.service(service: braids(), quantity: 1)],
        online: true,
      );

      final byProduct = await InsightService(
        db: shop.db,
      ).salesByProductAllTime(userId).first;
      expect(byProduct.keys, ['p1']);
    });
  });

  group('service performance', () {
    Future<void> serviceSale(
      String serviceId,
      String name, {
      required int jobs,
      required double total,
      required double cost,
      required DateTime date,
    }) {
      return shop.salesRef.add({
        'kind': 'service',
        'serviceId': serviceId,
        'productName': name,
        'quantity': jobs,
        'sellingPrice': total / jobs,
        'totalAmount': total,
        'costAmount': cost,
        'profit': total - cost,
        'date': Timestamp.fromDate(date),
        'receiptId': 'r-$serviceId-${date.millisecondsSinceEpoch}',
      });
    }

    test('sums jobs, revenue and profit per service', () async {
      await serviceSale(
        's1',
        'Braids',
        jobs: 1,
        total: 300,
        cost: 100,
        date: DateTime(2026, 3, 1),
      );
      await serviceSale(
        's1',
        'Box braids',
        jobs: 2,
        total: 700,
        cost: 240,
        date: DateTime(2026, 3, 5),
      );
      await serviceSale(
        's2',
        'Haircut',
        jobs: 1,
        total: 50,
        cost: 0,
        date: DateTime(2026, 3, 2),
      );
      await shop.addSale(
        productId: 'p1',
        quantity: 1,
        totalAmount: 10,
        profit: 4,
        date: DateTime(2026, 3, 1),
      );

      final byService = await ServicePerformanceService(
        db: shop.db,
      ).salesByService(userId).first;

      expect(byService.keys, unorderedEquals(['s1', 's2']));
      final s1 = byService['s1']!;
      expect(s1.name, 'Box braids'); // newest sale's name
      expect(s1.jobs, 3);
      expect(s1.revenue, 1000);
      expect(s1.cost, 340);
      expect(s1.profit, 660);
    });

    test('limits to a date range', () async {
      await serviceSale(
        's1',
        'Braids',
        jobs: 1,
        total: 300,
        cost: 100,
        date: DateTime(2026, 2, 20),
      );
      await serviceSale(
        's1',
        'Braids',
        jobs: 1,
        total: 350,
        cost: 100,
        date: DateTime(2026, 3, 5),
      );

      final march = await ServicePerformanceService(db: shop.db)
          .salesByService(
            userId,
            from: DateTime(2026, 3),
            to: DateTime(2026, 4),
          )
          .first;
      expect(march['s1']!.revenue, 350);
    });
  });

  group('import', () {
    test('reads a Services sheet', () {
      final excel = Excel.createExcel();
      final sheet = excel['Services'];
      sheet.appendRow([
        TextCellValue('Name'),
        TextCellValue('Price'),
        TextCellValue('Materials cost'),
      ]);
      sheet.appendRow([
        TextCellValue('Box braids'),
        IntCellValue(350),
        IntCellValue(120),
      ]);
      sheet.appendRow([TextCellValue('Haircut'), IntCellValue(50), null]);
      sheet.appendRow([TextCellValue('Free'), IntCellValue(0), null]);
      excel.delete('Sheet1');

      final preview = SpreadsheetFormat.parse(excel.encode()!);

      final [braids, haircut] = preview.services;
      expect(braids.price, 350);
      expect(braids.materialsCost, 120);
      expect(haircut.materialsCost, 0);
      expect(preview.problems, ['Services row 4: Price must be more than 0']);
    });

    test('adds services, skipping names already in the app', () async {
      await shop.userRef.collection(FirestoreCollections.services).add({
        ...braids().toFirestore(),
      });

      final (:result, :write) = await ImportService(db: shop.db).import(
        userId,
        const ImportPreview(
          products: [],
          services: [
            ImportedService(name: 'box braids', price: 400, materialsCost: 0),
            ImportedService(name: 'Haircut', price: 50, materialsCost: 5),
          ],
          expenses: [],
          problems: [],
        ),
      );
      await write;

      expect(result.servicesAdded, 1);
      expect(result.servicesSkipped, 1);
      final names =
          (await shop.userRef.collection(FirestoreCollections.services).get())
              .docs
              .map((d) => d['name']);
      expect(names, unorderedEquals(['Box braids', 'Haircut']));
    });
  });
}
