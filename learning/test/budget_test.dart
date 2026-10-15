import 'package:flutter_test/flutter_test.dart';
import 'package:profitpulse/features/budgets/models/budget_model.dart';
import 'package:profitpulse/features/budgets/services/budget_service.dart';

import 'support/fake_shop.dart';

void main() {
  const rent = BudgetModel(category: 'Rent', monthlyLimit: 100);

  group('BudgetStatus', () {
    test('levels: under 80% ok, 80% to the limit near, past it over', () {
      expect(BudgetStatus(budget: rent, spent: 79).level, BudgetLevel.ok);
      expect(BudgetStatus(budget: rent, spent: 80).level, BudgetLevel.near);
      expect(BudgetStatus(budget: rent, spent: 100).level, BudgetLevel.near);
      expect(BudgetStatus(budget: rent, spent: 100.01).level, BudgetLevel.over);
    });

    test('remaining goes negative once over', () {
      expect(BudgetStatus(budget: rent, spent: 30).remaining, 70);
      expect(BudgetStatus(budget: rent, spent: 130).remaining, -30);
    });

    test('build matches spending by category key, most used first', () {
      const fuel = BudgetModel(category: 'Fuel', monthlyLimit: 50);
      final statuses = BudgetStatus.build(
        [rent, fuel],
        {'rent': 20, 'fuel': 45},
      );

      expect(statuses.map((s) => s.budget.category), ['Fuel', 'Rent']);
      expect(statuses.last.spent, 20);
    });

    test('a budget with no spending this month shows zero', () {
      final statuses = BudgetStatus.build([rent], {});
      expect(statuses.single.spent, 0);
      expect(statuses.single.level, BudgetLevel.ok);
    });
  });

  group('budgetLevelCrossed', () {
    test('flags moving into near and into over', () {
      final status = BudgetStatus(budget: rent, spent: 70);
      expect(budgetLevelCrossed(status, 15), BudgetLevel.near);
      expect(budgetLevelCrossed(status, 40), BudgetLevel.over);
    });

    test('stays quiet when the level does not change', () {
      expect(
        budgetLevelCrossed(BudgetStatus(budget: rent, spent: 10), 20),
        isNull,
      );
      expect(
        budgetLevelCrossed(BudgetStatus(budget: rent, spent: 85), 5),
        isNull,
      );
      expect(
        budgetLevelCrossed(BudgetStatus(budget: rent, spent: 120), 50),
        isNull,
      );
    });

    test('jumping from near to over is flagged', () {
      expect(
        budgetLevelCrossed(BudgetStatus(budget: rent, spent: 90), 20),
        BudgetLevel.over,
      );
    });
  });

  test('category keys ignore case, spacing, and blank means Other', () {
    expect(BudgetModel.keyFor(' Rent '), 'rent');
    expect(BudgetModel.keyFor('RENT'), 'rent');
    expect(BudgetModel.keyFor('  '), 'other');
  });

  group('BudgetService', () {
    late FakeShop shop;
    late BudgetService service;

    setUp(() {
      shop = FakeShop();
      service = BudgetService(db: shop.db);
    });

    test('one budget per category, whatever the casing', () async {
      await service.setBudget(userId, rent);
      await service.setBudget(
        userId,
        const BudgetModel(category: 'rent', monthlyLimit: 250),
      );

      final budgets = await service.getBudgets(userId).first;
      expect(budgets.single.monthlyLimit, 250);
    });

    test('deleting removes the budget', () async {
      await service.setBudget(userId, rent);
      await service.deleteBudget(userId, 'RENT');

      expect(await service.getBudgets(userId).first, isEmpty);
    });

    test('spending totals only count expenses from the given date', () async {
      await shop.expensesRef.add({
        'title': 'Oct rent',
        'amount': 60,
        'category': 'Rent',
        'date': DateTime(2026, 10, 1),
      });
      await shop.expensesRef.add({
        'title': 'Top-up',
        'amount': 15,
        'category': ' rent',
        'date': DateTime(2026, 10, 9),
      });
      await shop.expensesRef.add({
        'title': 'Sep rent',
        'amount': 999,
        'category': 'Rent',
        'date': DateTime(2026, 9, 30, 23),
      });

      final spent = await service
          .spentByCategorySince(userId, DateTime(2026, 10))
          .first;

      expect(spent, {'rent': 75});
    });

    test('category suggestions are unique and sorted', () async {
      for (final category in ['Rent', 'rent', 'Fuel', '']) {
        await shop.expensesRef.add({
          'title': 'Expense',
          'amount': 1,
          'category': category,
          'date': DateTime(2026, 10, 1),
        });
      }

      expect(await service.expenseCategories(userId), ['Fuel', 'Rent']);
    });
  });
}
