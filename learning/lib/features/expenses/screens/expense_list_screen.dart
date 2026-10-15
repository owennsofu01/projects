import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../budgets/controllers/budget_controller.dart';
import '../../budgets/screens/budget_screen.dart';
import '../controllers/expense_controller.dart';
import '../models/expense_model.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatelessWidget {
  ExpenseListScreen({super.key});

  final ExpenseController controller = Get.find<ExpenseController>();
  final BudgetController budgetController = Get.find<BudgetController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          Obx(() {
            final count = budgetController.needingAttention.length;
            return IconButton(
              onPressed: () => Get.to(() => BudgetScreen()),
              tooltip: 'Budgets',
              icon: Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: const Icon(Icons.savings_outlined),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expenses-fab',
        onPressed: () => Get.to(() => const AddExpenseScreen()),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: controller.expensesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!;

          if (expenses.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No expenses recorded',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final expense = expenses[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.money_off),
                  title: Text(expense.title),
                  subtitle: Text(
                    '${expense.category}  •  ${AppFormatter.date(expense.date)}',
                  ),
                  trailing: Obx(
                    () => Text(
                      AppFormatter.currency(expense.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
