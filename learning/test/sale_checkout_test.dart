import 'package:flutter_test/flutter_test.dart';
import 'package:profitpulse/core/constants/firestore_collections.dart';
import 'package:profitpulse/features/sales/models/cart_item.dart';
import 'package:profitpulse/features/sales/services/sale_service.dart';

import 'support/fake_shop.dart';

void main() {
  late FakeShop shop;
  late SaleService service;

  setUp(() {
    shop = FakeShop();
    service = SaleService(db: shop.db);
  });

  group('FIFO costing', () {
    test('costs a sale from the oldest batch first', () async {
      final product = await shop.addProduct(
        'p1',
        sellingPrice: 20,
        costPrice: 15,
        batches: [(5, 10), (5, 15)],
      );

      await service.checkout(
        userId: userId,
        items: [CartItem(product: product, quantity: 3)],
        online: true,
      );

      final sale = (await shop.salesRef.get()).docs.single;
      expect(sale['totalAmount'], 60);
      expect(sale['costAmount'], 30); // 3 × 10 from the first batch
      expect(sale['profit'], 30);
      expect(await shop.batchRemaining('p1'), [2, 5]);
      expect(await shop.stockOf('p1'), 7);
    });

    test('spans batches when the oldest runs out', () async {
      final product = await shop.addProduct(
        'p1',
        sellingPrice: 20,
        costPrice: 15,
        batches: [(5, 10), (5, 15)],
      );

      await service.checkout(
        userId: userId,
        items: [CartItem(product: product, quantity: 7)],
        online: true,
      );

      final sale = (await shop.salesRef.get()).docs.single;
      expect(sale['costAmount'], 5 * 10 + 2 * 15);
      expect(sale['profit'], 140 - 80);
      expect(await shop.batchRemaining('p1'), [0, 3]);
    });

    test('skips batches that are already used up', () async {
      final product = await shop.addProduct(
        'p1',
        sellingPrice: 20,
        costPrice: 15,
        batches: [(5, 10), (5, 15)],
      );
      await shop.batchesRef('p1').doc('b0').update({'remainingQuantity': 0});
      await shop.productRef('p1').update({'stock': 5});

      await service.checkout(
        userId: userId,
        items: [CartItem(product: product, quantity: 2)],
        online: true,
      );

      final sale = (await shop.salesRef.get()).docs.single;
      expect(sale['costAmount'], 30);
    });

    test('costs units no batch covers at the product cost', () async {
      final product = await shop.addProduct(
        'p1',
        sellingPrice: 20,
        costPrice: 12,
        batches: [(2, 10)],
        extraStock: 3,
      );

      await service.checkout(
        userId: userId,
        items: [CartItem(product: product, quantity: 4)],
        online: true,
      );

      final sale = (await shop.salesRef.get()).docs.single;
      expect(sale['costAmount'], 2 * 10 + 2 * 12);
      expect(await shop.stockOf('p1'), 1);
    });

    test('costs the offline path the same way', () async {
      final product = await shop.addProduct(
        'p1',
        sellingPrice: 20,
        costPrice: 15,
        batches: [(5, 10), (5, 15)],
      );

      await service.checkout(
        userId: userId,
        items: [CartItem(product: product, quantity: 6)],
        online: false,
      );
      // The offline batch commit isn't awaited by checkout.
      await pumpEventQueue();

      final sale = (await shop.salesRef.get()).docs.single;
      expect(sale['costAmount'], 5 * 10 + 1 * 15);
      expect(await shop.stockOf('p1'), 4);
    });
  });

  group('checkout', () {
    test('records each cart line under one receipt', () async {
      final a = await shop.addProduct(
        'a',
        sellingPrice: 10,
        costPrice: 6,
        batches: [(10, 6)],
      );
      final b = await shop.addProduct(
        'b',
        sellingPrice: 25,
        costPrice: 20,
        batches: [(10, 20)],
      );

      final receiptId = await service.checkout(
        userId: userId,
        items: [
          CartItem(product: a, quantity: 2),
          CartItem(product: b, quantity: 1),
        ],
        online: true,
      );

      final sales = (await shop.salesRef.get()).docs;
      expect(sales, hasLength(2));
      expect(sales.map((s) => s['receiptId']), everyElement(receiptId));
      final profit = sales.fold<num>(0, (sum, s) => sum + s['profit']);
      expect(profit, (20 - 12) + (25 - 20));
    });

    test('records nothing when any line is short on stock', () async {
      final a = await shop.addProduct(
        'a',
        sellingPrice: 10,
        costPrice: 6,
        batches: [(10, 6)],
      );
      final b = await shop.addProduct(
        'b',
        sellingPrice: 25,
        costPrice: 20,
        batches: [(1, 20)],
      );

      await expectLater(
        service.checkout(
          userId: userId,
          items: [
            CartItem(product: a, quantity: 2),
            CartItem(product: b, quantity: 2),
          ],
          online: true,
        ),
        throwsA(isA<Exception>()),
      );

      expect((await shop.salesRef.get()).docs, isEmpty);
      expect(await shop.stockOf('a'), 10);
      expect(await shop.batchRemaining('a'), [10]);
    });
  });

  group('credit sales', () {
    test('adds the unpaid part to the balance with a ledger entry', () async {
      final product = await shop.addProduct(
        'p1',
        sellingPrice: 50,
        costPrice: 30,
        batches: [(10, 30)],
      );
      final customer = await shop.addCustomer('c1', balance: 20);

      final receiptId = await service.checkout(
        userId: userId,
        items: [CartItem(product: product, quantity: 2)],
        online: true,
        customer: customer,
        creditAmount: 60,
      );

      expect(await shop.balanceOf('c1'), 80);
      final ledger = await shop
          .customerRef('c1')
          .collection(FirestoreCollections.ledger)
          .get();
      final entry = ledger.docs.single;
      expect(entry['type'], 'credit');
      expect(entry['amount'], 60);
      expect(entry['receiptId'], receiptId);

      final sale = (await shop.salesRef.get()).docs.single;
      expect(sale['customerId'], 'c1');
      expect(sale['receiptCredit'], 60);
    });

    test('a fully paid sale to a customer leaves the balance alone', () async {
      final product = await shop.addProduct(
        'p1',
        sellingPrice: 50,
        costPrice: 30,
        batches: [(10, 30)],
      );
      final customer = await shop.addCustomer('c1', balance: 20);

      await service.checkout(
        userId: userId,
        items: [CartItem(product: product, quantity: 1)],
        online: true,
        customer: customer,
      );

      expect(await shop.balanceOf('c1'), 20);
      final ledger = await shop
          .customerRef('c1')
          .collection(FirestoreCollections.ledger)
          .get();
      expect(ledger.docs, isEmpty);
    });
  });
}
