import 'package:flutter_test/flutter_test.dart';
import 'package:profitpulse/features/insights/services/insight_service.dart';
import 'package:profitpulse/features/products/models/product_profit_row.dart';

import 'support/fake_shop.dart';

void main() {
  late FakeShop shop;
  late InsightService service;

  setUp(() {
    shop = FakeShop();
    service = InsightService(db: shop.db);
  });

  Future<void> seedSales() async {
    await shop.addSale(
      productId: 'a',
      quantity: 2,
      totalAmount: 40,
      profit: 10,
      date: DateTime(2026, 8, 31, 23, 59),
    );
    await shop.addSale(
      productId: 'a',
      quantity: 3,
      totalAmount: 60,
      profit: 15,
      date: DateTime(2026, 9, 1),
    );
    await shop.addSale(
      productId: 'b',
      quantity: 1,
      totalAmount: 5,
      profit: -2,
      date: DateTime(2026, 9, 30, 12),
    );
    await shop.addSale(
      productId: 'a',
      quantity: 1,
      totalAmount: 20,
      profit: 5,
      date: DateTime(2026, 10, 1),
    );
  }

  test('all-time totals sum every sale per product', () async {
    await seedSales();

    final byProduct = await service.salesByProductAllTime(userId).first;

    expect(byProduct['a']!.quantity, 6);
    expect(byProduct['a']!.revenue, 120);
    expect(byProduct['a']!.profit, 30);
    expect(byProduct['b']!.profit, -2);
  });

  test('a month includes its first day and stops before the next', () async {
    await seedSales();

    final september = await service
        .salesByProductBetween(
          userId,
          from: DateTime(2026, 9),
          to: DateTime(2026, 10),
        )
        .first;

    expect(september['a']!.quantity, 3);
    expect(september['a']!.profit, 15);
    expect(september['b']!.profit, -2);
  });

  test('a month with no sales is empty', () async {
    await seedSales();

    final july = await service
        .salesByProductBetween(
          userId,
          from: DateTime(2026, 7),
          to: DateTime(2026, 8),
        )
        .first;

    expect(july, isEmpty);
  });

  test('a row values remaining stock at cost and expected profit', () {
    const row = ProductProfitRow(
      productId: 'a',
      productName: 'A',
      stock: 4,
      costPrice: 7.5,
      sellingPrice: 10,
      unitsSold: 6,
      profit: 30,
    );

    expect(row.totalCost, 30);
    expect(row.expectedProfit, 10);
  });
}
