import 'package:flutter_test/flutter_test.dart';
import 'package:profitpulse/features/products/services/product_service.dart';

import 'support/fake_shop.dart';

void main() {
  late FakeShop shop;
  late ProductService service;

  setUp(() {
    shop = FakeShop();
    service = ProductService(db: shop.db);
  });

  test('lowering stock uses up the oldest batches first', () async {
    await shop.addProduct(
      'p1',
      sellingPrice: 20,
      costPrice: 15,
      batches: [(5, 10), (5, 15)],
    );

    await service.setStock(userId, 'p1', newQuantity: 3, costPrice: 15);

    expect(await shop.stockOf('p1'), 3);
    expect(await shop.batchRemaining('p1'), [0, 3]);
  });

  test('raising stock adds a batch at the given cost', () async {
    await shop.addProduct(
      'p1',
      sellingPrice: 20,
      costPrice: 10,
      batches: [(5, 10)],
    );

    await service.setStock(userId, 'p1', newQuantity: 8, costPrice: 12);

    expect(await shop.stockOf('p1'), 8);
    final batches = (await shop.batchesRef('p1').get()).docs;
    final added = batches.singleWhere((b) => b.id != 'b0');
    expect(added['remainingQuantity'], 3);
    expect(added['costPrice'], 12);
  });

  test('setting the same stock changes nothing', () async {
    await shop.addProduct(
      'p1',
      sellingPrice: 20,
      costPrice: 10,
      batches: [(5, 10)],
    );

    await service.setStock(userId, 'p1', newQuantity: 5, costPrice: 99);

    expect(await shop.batchRemaining('p1'), [5]);
  });
}
