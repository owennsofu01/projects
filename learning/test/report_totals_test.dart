import 'package:flutter_test/flutter_test.dart';
import 'package:profitpulse/features/reports/controllers/report_controller.dart';
import 'package:profitpulse/features/reports/models/report_range.dart';
import 'package:profitpulse/features/reports/services/report_service.dart';

import 'support/fake_shop.dart';

void main() {
  late FakeShop shop;
  late ReportController controller;

  setUp(() async {
    shop = FakeShop();
    controller = ReportController(
      userId,
      reportService: ReportService(db: shop.db),
    );

    // Inside 1–15 Sep.
    await shop.addSale(
      productId: 'a',
      quantity: 2,
      totalAmount: 100,
      profit: 30,
      date: DateTime(2026, 9, 1),
    );
    await shop.addSale(
      productId: 'b',
      quantity: 1,
      totalAmount: 50,
      profit: -5,
      date: DateTime(2026, 9, 15, 23, 30),
    );
    await shop.addExpense(amount: 10, date: DateTime(2026, 9, 10));

    // Outside it.
    await shop.addSale(
      productId: 'a',
      quantity: 1,
      totalAmount: 999,
      profit: 999,
      date: DateTime(2026, 9, 16),
    );
    await shop.addExpense(amount: 999, date: DateTime(2026, 8, 31, 23));
  });

  test(
    'totals cover every record in the range, including its last day',
    () async {
      await controller.setRange(
        ReportRange.custom(DateTime(2026, 9, 1), DateTime(2026, 9, 15)),
      );

      expect(controller.sales, hasLength(2));
      expect(controller.totalSales, 150);
      expect(controller.totalProfit, 25);
      expect(controller.totalExpenses, 10);
      expect(controller.netProfit, 15);
    },
  );

  test('net profit goes negative when expenses exceed profit', () async {
    await shop.addExpense(amount: 40, date: DateTime(2026, 9, 2));

    await controller.setRange(
      ReportRange.custom(DateTime(2026, 9, 1), DateTime(2026, 9, 15)),
    );

    expect(controller.netProfit, 25 - 50);
  });

  test('an empty range totals zero', () async {
    await controller.setRange(
      ReportRange.custom(DateTime(2026, 7, 1), DateTime(2026, 7, 31)),
    );

    expect(controller.totalSales, 0);
    expect(controller.netProfit, 0);
  });

  test('a custom range runs from the start of its first day to the end '
      'of its last', () {
    final range = ReportRange.custom(
      DateTime(2026, 9, 1, 14),
      DateTime(2026, 9, 15, 9),
    );

    expect(range.start, DateTime(2026, 9, 1));
    expect(range.end, DateTime(2026, 9, 16));
  });
}
